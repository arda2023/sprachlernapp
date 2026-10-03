-- Schemas: content (Inhalte, Master für content.sqlite) und app (Nutzerdaten).
-- Siehe docs/content-schema.md und docs/user-schema.md.
create schema if not exists content;
create schema if not exists app;

-- content ist nicht über die API erreichbar (config.toml), app nur für authenticated.
revoke all on schema content from public, anon, authenticated;
revoke all on schema app from public, anon;
