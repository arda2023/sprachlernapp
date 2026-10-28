// READ ONLY: exact installed offer + published immutable artifact, no model/RPC.
// Both platforms: node --experimental-transform-types tool/audit_personal_release.ts /absolute/path/to/active.json /absolute/path/to/content.sqlite
// Credentials are read only from the process environment; never printed.
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {PersonalReleaseCache} from '../supabase/functions/_shared/personal_release.ts';
const url=process.env.SUPABASE_URL,key=process.env.SUPABASE_SERVICE_ROLE_KEY;
if(!url||!key)throw Error('SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY required in environment');
if(new URL(url).protocol!=='https:')throw Error('HTTPS required');
const active=JSON.parse(readFileSync(process.argv[2],'utf8'));
const offer=active.offer??active,manifest=offer.manifest;
if(!manifest?.release_id||!offer.manifest_sha256)throw Error('Pass the actual installed offer from active.json, not bootstrap metadata');
if(!process.argv[3]||createHash('sha256').update(readFileSync(process.argv[3])).digest('hex')!==manifest.sha256)throw Error('Actual installed SQLite bytes do not match offer');
const headers={apikey:key,Authorization:'Bearer '+key};
const endpoint=new URL('/rest/v1/content_release_catalog',url);
endpoint.searchParams.set('release_id','eq.'+manifest.release_id);endpoint.searchParams.set('select','release_id,lang,manifest,manifest_sha256,objects');
const response=await fetch(endpoint,{headers,redirect:'error'});if(!response.ok)throw Error('Catalog read failed: '+response.status);
const rows=await response.json();if(rows.length!==1)throw Error('Exact release not found');const row=rows[0];
if(row.manifest_sha256!==offer.manifest_sha256||row.manifest.sha256!==manifest.sha256||row.lang!==manifest.lang)throw Error('Installed offer/catalog mismatch');
const cards=await new PersonalReleaseCache().candidates(url,key,row,fetch,new AbortController().signal);
console.log(JSON.stringify({release_id:row.release_id,lang:row.lang,manifest_sha256:row.manifest_sha256,sqlite_sha256:row.manifest.sha256,reference_cards:cards.length,retired:cards.filter(c=>c.retired).length}));
