-- User decision 01.11.2026: the "Nachrichten" section shows real news. Once a
-- day per desk the refresh-news Edge Function stores 3 to 6 short B1 articles
-- per learning language, each sentence with its German translation and the
-- web sources it is based on. News are free and public: the app reads the
-- latest edition per desk without signing in. Only the service role writes.

create table app.news_articles (
  id text primary key check (id ~ '^\d{4}-\d{2}-\d{2}-[a-zA-Z-]{2,5}-[a-z]+-[1-6]$'),
  edition date not null,
  lang text not null check (lang in ('en','pt-BR','es','it','nb')),
  category text not null
    check (category in ('politics','economy','technology','medicine','entertainment')),
  rank smallint not null check (rank between 1 and 6),
  title text not null check (char_length(title) between 1 and 140),
  level text not null check (level in ('A2','B1','B2')),
  reading_minutes smallint not null check (reading_minutes between 1 and 10),
  sections jsonb not null check (jsonb_typeof(sections)='array'
    and jsonb_array_length(sections) between 2 and 3),
  sources jsonb not null check (jsonb_typeof(sources)='array'
    and jsonb_array_length(sources) between 1 and 3),
  created_at timestamptz not null default now(),
  unique (edition, lang, category, rank),
  check (length(sections::text) <= 12000 and length(sources::text) <= 3000)
);

alter table app.news_articles enable row level security;
revoke all on app.news_articles from public, anon, authenticated;

-- Replaces one desk's edition in one language; keeps two weeks of editions.
create or replace function public.store_news(
  p_edition date, p_category text, p_lang text, p_articles jsonb
) returns jsonb language plpgsql security definer set search_path='' set lock_timeout='2s' as $$
declare stored integer;
begin
  if jsonb_typeof(p_articles) is distinct from 'array'
    or jsonb_array_length(p_articles) not between 1 and 6 then
    raise exception 'invalid articles';
  end if;
  delete from app.news_articles
    where edition=p_edition and category=p_category and lang=p_lang;
  insert into app.news_articles(id,edition,lang,category,rank,title,level,
    reading_minutes,sections,sources)
  select a->>'id', p_edition, p_lang, p_category, (a->>'rank')::smallint,
    a->>'title', a->>'level', (a->>'reading_minutes')::smallint,
    a->'sections', a->'sources'
  from jsonb_array_elements(p_articles) a;
  get diagnostics stored=row_count;
  delete from app.news_articles where edition < p_edition - 14;
  return jsonb_build_object('stored', stored);
end $$;

revoke all on function public.store_news(date,text,text,jsonb) from public,anon,authenticated;
grant execute on function public.store_news(date,text,text,jsonb) to service_role;

-- Each desk's newest edition from the last week, desks in app order.
create or replace function public.latest_news(p_lang text)
returns jsonb language sql stable security definer set search_path='' as $$
  select coalesce(jsonb_agg(jsonb_build_object(
      'id',n.id,'edition',n.edition,'category',n.category,'rank',n.rank,
      'title',n.title,'level',n.level,'reading_minutes',n.reading_minutes,
      'sections',n.sections,'sources',n.sources)
    order by array_position(array['politics','economy','technology','medicine',
      'entertainment'],n.category), n.rank), '[]'::jsonb)
  from app.news_articles n
  where n.lang=p_lang
    and n.edition=(select max(m.edition) from app.news_articles m
      where m.lang=n.lang and m.category=n.category
        and m.edition >= current_date - 7)
$$;

revoke all on function public.latest_news(text) from public;
grant execute on function public.latest_news(text) to anon, authenticated, service_role;
