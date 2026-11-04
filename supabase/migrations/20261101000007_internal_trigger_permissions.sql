-- Supabase's DDL event trigger is administrative, never a public app RPC.
-- It may not exist in a fresh local database. Keep the trigger itself enabled.
do $$
begin
  if to_regprocedure('public.rls_auto_enable()') is not null then
    revoke all on function public.rls_auto_enable() from public,anon,authenticated;
  end if;
end $$;
