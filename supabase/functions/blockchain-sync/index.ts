import { makeHandler } from './handler.ts';

Deno.serve(makeHandler({
  config: () => ({
    supabaseUrl: Deno.env.get('SUPABASE_URL') ?? '',
    serviceKey: Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    chainUrl: (Deno.env.get('BLOCKCHAIN_API_URL') ?? '').replace(/\/+$/, ''),
    chainKey: Deno.env.get('BLOCKCHAIN_API_KEY') ?? '',
  }),
  fetch: (input, init) => fetch(input, init),
  now: () => Date.now(),
}));
