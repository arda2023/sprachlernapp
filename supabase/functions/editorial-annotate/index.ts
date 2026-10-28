import {editorialHandler} from '../_shared/editorial_annotation.ts';
const projectRef=new URL(Deno.env.get('SUPABASE_URL')??'https://invalid.local').hostname.split('.')[0];
Deno.serve(editorialHandler(Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')??'',Deno.env.get('ANTHROPIC_API_KEY')??'',fetch,
  {secret:Deno.env.get('EDITORIAL_ADMIN_TOKEN')??'',projectRef}));
