-- No content or learning changes. Service-only atomic reservation; failures count.
create or replace function public.reserve_runtime_translation(p_user uuid, p_lang text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  today date := (clock_timestamp() at time zone 'UTC')::date;
  minute_kind text := 'translation-minute:' || to_char(clock_timestamp() at time zone 'UTC','YYYYMMDDHH24MI');
  daily integer; per_minute integer; total bigint;
begin
  if p_lang not in ('en','pt-BR') or not exists (
    select 1 from public.content_readers where user_id=p_user and lang=p_lang and channel='internal'
  ) then return jsonb_build_object('allowed',false,'reason','forbidden'); end if;
  -- Shared lock serializes both Functions and all Edge instances, including the global cap.
  perform pg_advisory_xact_lock(741905501);
  select coalesce(sum(units),0) into total from app.usage where day=today and kind='runtime-translation';
  select coalesce(max(units),0) into daily from app.usage where user_id=p_user and day=today and kind='runtime-translation';
  select coalesce(max(units),0) into per_minute from app.usage where user_id=p_user and day=today and kind=minute_kind;
  if total>=1000 or daily>=20 or per_minute>=5 then
    return jsonb_build_object('allowed',false,'reason','limit');
  end if;
  insert into app.usage(user_id,day,kind,units) values(p_user,today,'runtime-translation',1),(p_user,today,minute_kind,1)
    on conflict(user_id,day,kind) do update set units=app.usage.units+1;
  return jsonb_build_object('allowed',true);
end;
$$;
revoke all on function public.reserve_runtime_translation(uuid,text) from public, anon, authenticated;
grant execute on function public.reserve_runtime_translation(uuid,text) to service_role;
