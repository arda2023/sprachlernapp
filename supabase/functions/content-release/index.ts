import { DistributionBackend, handler } from '../_shared/content_distribution.ts';
Deno.serve(handler('release',new DistributionBackend(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!)));
