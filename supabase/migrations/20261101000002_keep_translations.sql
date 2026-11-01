-- User decision 01.11.2026: AI translations stay in the private server
-- cache for good instead of 30 days, so the same word or sentence never
-- costs a second request. The learner can still delete the cache in the app
-- (clear_translation_cache) and account deletion removes it. Answers already
-- stored are kept as well.

create or replace function public.finish_translation(p_user uuid,p_key text,p_ticket uuid,p_response jsonb)
returns jsonb language plpgsql security definer set search_path='' set lock_timeout='2s' as $$
declare changed integer;
begin
  if p_response is null or p_response->>'provider' is distinct from 'anthropic'
    or p_response->>'model' is distinct from 'claude-haiku-5-5'
    or p_response->>'contract' is distinct from '2'
    or p_response->>'prompt' is distinct from 'translation-v2'
    or jsonb_typeof(p_response->'usage') is distinct from 'object'
    or length(p_response::text)>16384 then raise exception 'invalid response'; end if;
  perform pg_advisory_xact_lock(741905501);
  update app.translation_cache set state='ready',response=p_response,
    expires_at='infinity'
    where user_id=p_user and request_key=p_key and ticket=p_ticket
      and state='pending' and lease_until>clock_timestamp()
      and exists(select 1 from app.translation_budget_reservations r
        where r.ticket=p_ticket and r.user_id=p_user and r.request_key=p_key
          and r.state='pending' and r.lease_until>clock_timestamp());
  get diagnostics changed=row_count;
  if changed=1 then
    update app.translation_budget_reservations set state='charged'
      where ticket=p_ticket and user_id=p_user and state='pending';
  end if;
  return jsonb_build_object('stored',changed=1);
end $$;

update app.translation_cache set expires_at='infinity'
  where state='ready' and expires_at>clock_timestamp();

revoke all on function public.finish_translation(uuid,text,uuid,jsonb) from public,anon,authenticated;
grant execute on function public.finish_translation(uuid,text,uuid,jsonb) to service_role;
