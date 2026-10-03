-- Storage-Buckets (docs/backend.md): audio und packs öffentlich lesbar, imports privat.
insert into storage.buckets (id, name, public)
values ('audio', 'audio', true), ('packs', 'packs', true), ('imports', 'imports', false)
on conflict (id) do nothing;

-- imports: nur im eigenen Ordner <auth.uid()>/...
create policy "imports own folder select" on storage.objects
  for select to authenticated
  using (bucket_id = 'imports' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "imports own folder insert" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'imports' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "imports own folder update" on storage.objects
  for update to authenticated
  using (bucket_id = 'imports' and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'imports' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "imports own folder delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'imports' and (storage.foldername(name))[1] = (select auth.uid())::text);

-- audio und packs: keine Schreib-Policies, also schreibt nur service_role (umgeht RLS).
-- Lesen läuft über die öffentliche URL der Buckets.
