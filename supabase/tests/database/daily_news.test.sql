begin;
create extension if not exists pgtap with schema extensions;
select plan(1);
do $$
declare
  article jsonb := jsonb_build_object(
    'id','2026-11-01-en-politics-1','rank',1,'title','Talks in Geneva','level','B1',
    'reading_minutes',1,
    'sections',jsonb_build_array(
      jsonb_build_object('heading','The meeting','sentences',jsonb_build_array(
        jsonb_build_object('text','Leaders meet today.','de','Die Spitzen treffen sich heute.'),
        jsonb_build_object('text','They talk about trade.','de','Sie sprechen über Handel.'))),
      jsonb_build_object('heading','What comes next','sentences',jsonb_build_array(
        jsonb_build_object('text','A second round follows.','de','Eine zweite Runde folgt.'),
        jsonb_build_object('text','Results come in May.','de','Ergebnisse kommen im Mai.')))),
    'sources',jsonb_build_array(jsonb_build_object('title','Agency','url','https://example.org/a')));
  r jsonb;
begin
  -- Only the service role writes; everyone may read the latest edition.
  assert not has_function_privilege('anon','public.store_news(date,text,text,jsonb)','EXECUTE');
  assert not has_function_privilege('authenticated','public.store_news(date,text,text,jsonb)','EXECUTE');
  assert has_function_privilege('service_role','public.store_news(date,text,text,jsonb)','EXECUTE');
  assert has_function_privilege('anon','public.latest_news(text)','EXECUTE');
  assert not has_table_privilege('anon','app.news_articles','SELECT');

  assert public.latest_news('en') = '[]'::jsonb;
  perform public.store_news(current_date - 1,'politics','en',jsonb_build_array(
    article || jsonb_build_object('id',to_char(current_date - 1,'YYYY-MM-DD')||'-en-politics-1')));
  perform public.store_news(current_date - 1,'economy','en',jsonb_build_array(
    article || jsonb_build_object('id',to_char(current_date - 1,'YYYY-MM-DD')||'-en-economy-1',
      'title','Old economy')));
  -- Today's politics edition replaces yesterday's for that desk only.
  perform public.store_news(current_date,'politics','en',jsonb_build_array(
    article || jsonb_build_object('id',to_char(current_date,'YYYY-MM-DD')||'-en-politics-1'),
    article || jsonb_build_object('id',to_char(current_date,'YYYY-MM-DD')||'-en-politics-2',
      'rank',2,'title','Second story')));
  r := public.latest_news('en');
  assert jsonb_array_length(r) = 3, r::text;
  assert r->0->>'category' = 'politics' and r->0->>'rank' = '1';
  assert r->1->>'title' = 'Second story';
  assert r->2->>'category' = 'economy' and r->2->>'title' = 'Old economy';
  assert public.latest_news('pt-BR') = '[]'::jsonb;

  -- Storing the same edition again replaces it instead of duplicating.
  perform public.store_news(current_date,'politics','en',jsonb_build_array(
    article || jsonb_build_object('id',to_char(current_date,'YYYY-MM-DD')||'-en-politics-1')));
  assert jsonb_array_length(public.latest_news('en')) = 2;

  -- Malformed articles are rejected by the table checks.
  begin
    perform public.store_news(current_date,'medicine','en',jsonb_build_array(
      article || jsonb_build_object('id',to_char(current_date,'YYYY-MM-DD')||'-en-medicine-1',
        'sections','[]'::jsonb)));
    assert false, 'empty sections stored';
  exception when check_violation then null;
  end;

  -- Editions older than two weeks are pruned, older than a week not shown.
  perform public.store_news(current_date - 20,'technology','en',jsonb_build_array(
    article || jsonb_build_object('id',to_char(current_date - 20,'YYYY-MM-DD')||'-en-technology-1')));
  assert jsonb_array_length(public.latest_news('en')) = 2;
  perform public.store_news(current_date,'medicine','en',jsonb_build_array(
    article || jsonb_build_object('id',to_char(current_date,'YYYY-MM-DD')||'-en-medicine-1')));
  assert not exists(select 1 from app.news_articles where edition < current_date - 14);
end $$;
select pass('daily news: service-only writes, public latest edition per desk, replacement, checks and pruning');
select * from finish();
rollback;
