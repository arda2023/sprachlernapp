-- Local content schema mirror only; not applied remotely. No user-state migration.
alter table content.cards
  add column learning jsonb;
