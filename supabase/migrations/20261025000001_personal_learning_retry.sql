-- Explicit compare-and-swap retry of an observed attempt. No learning/cache rows change.
alter table app.personal_learning_jobs drop constraint personal_learning_jobs_state_check;
alter table app.personal_learning_jobs add constraint personal_learning_jobs_state_check
  check(state in ('pending','ready','uncertain','failed'));

create function public.claim_personal_learning(p_user uuid,p_lang text,p_key text,p_retry_ticket uuid)
returns jsonb language plpgsql security definer set search_path='' set lock_timeout='2s' as $$
declare item app.personal_learning_jobs; quota jsonb; next_ticket uuid;
begin
  if p_lang not in ('en','pt-BR') or not exists (
    select 1 from public.content_readers where user_id=p_user and lang=p_lang and channel='internal'
  ) then return jsonb_build_object('status','forbidden'); end if;
  if p_key is null or p_key !~ '^[0-9a-f]{64}$' then raise exception 'invalid key'; end if;
  perform pg_advisory_xact_lock(741905501);
  -- Keep attempt tombstones: expiry is retention, never permission to auto-generate.
  select * into item from app.personal_learning_jobs where user_id=p_user and request_key=p_key;
  if found then
    if item.state='ready' and item.expires_at>clock_timestamp() then
      return jsonb_build_object('status','hit','response',item.response);
    end if;
    if item.state='pending' and item.lease_until>clock_timestamp() then
      return jsonb_build_object('status','busy');
    end if;
    if p_retry_ticket is distinct from item.ticket then
      return jsonb_build_object('status','uncertain','retry_ticket',item.ticket);
    end if;
  elsif p_retry_ticket is not null then
    return jsonb_build_object('status','uncertain');
  end if;
  quota:=public.reserve_runtime_translation(p_user,p_lang);
  if quota->>'allowed'<>'true' then return jsonb_build_object('status',quota->>'reason'); end if;
  next_ticket:=gen_random_uuid();
  insert into app.personal_learning_jobs(user_id,request_key,ticket,state,lease_until,expires_at,response)
    values(p_user,p_key,next_ticket,'pending',clock_timestamp()+interval '45 seconds',clock_timestamp()+interval '24 hours',null)
    on conflict(user_id,request_key) do update set ticket=excluded.ticket,state='pending',
      lease_until=excluded.lease_until,expires_at=excluded.expires_at,response=null;
  return jsonb_build_object('status','claimed','ticket',next_ticket);
end $$;
-- Old clients can recover stored results, but cannot authorize a retry implicitly.
create or replace function public.claim_personal_learning(p_user uuid,p_lang text,p_key text)
returns jsonb language sql security definer set search_path='' as $$
  select public.claim_personal_learning(p_user,p_lang,p_key,null::uuid);
$$;

create function public.fail_personal_learning(p_user uuid,p_key text,p_ticket uuid)
returns jsonb language plpgsql security definer set search_path='' set lock_timeout='2s' as $$
declare changed integer;
begin
  perform pg_advisory_xact_lock(741905501);
  update app.personal_learning_jobs set state='failed',lease_until=clock_timestamp()
    where user_id=p_user and request_key=p_key and ticket=p_ticket and state='pending';
  get diagnostics changed=row_count;
  return jsonb_build_object('failed',changed=1);
end $$;
-- finish_personal_learning already fences writes by current ticket + pending lease.
revoke all on function public.claim_personal_learning(uuid,text,text,uuid) from public,anon,authenticated;
revoke all on function public.fail_personal_learning(uuid,text,uuid) from public,anon,authenticated;
grant execute on function public.claim_personal_learning(uuid,text,text,uuid) to service_role;
grant execute on function public.fail_personal_learning(uuid,text,uuid) to service_role;
