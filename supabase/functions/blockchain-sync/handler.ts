// Supabase Edge Function `blockchain-sync`: copies projects from the Watad database to the blockchain.
//
// Who calls it: the database (pg_net, right after a relevant row changes, and pg_cron every 2 minutes as a retry
// safety net). It is deployed with verify_jwt = false because it does its own check: every database call it makes
// needs the shared secret (Vault: blockchain_sync_secret) that only the database sends in `x-sync-secret`;
// without it every call is answered 403 and nothing is read or written.
//
// Secrets (Edge Functions -> Secrets):  BLOCKCHAIN_API_URL, BLOCKCHAIN_API_KEY
// Provided by Supabase:                 SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
//
// Body {}              -> sync everything that is waiting
// Body {"check": true} -> only test the secret and the connection to the blockchain server (writes nothing)

import { describe, plan, type Project, type Step } from '../_shared/reconcile.ts';

const CHAIN_TIMEOUT_MS = 25_000;
const DB_TIMEOUT_MS = 15_000;
const BATCH = 5;
const BUDGET_MS = 100_000; // stop starting new work after this; claimed projects are picked up again later

type Outcome = 'ok' | 'retry' | 'failed';

export interface Config { supabaseUrl: string; serviceKey: string; chainUrl: string; chainKey: string }
export interface Deps { config: () => Partial<Config>; fetch: typeof fetch; now: () => number }

class SyncError extends Error {
  constructor(readonly outcome: Outcome, message: string) { super(message); }
}
class Forbidden extends Error {}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });

/** Turns an unsuccessful answer of the blockchain server into "try again later" or "will not work as it is". */
function classify(status: number, payload: { error?: string } | null, what: string): SyncError {
  const detail = payload?.error ? `: ${payload.error}` : '';
  if (status === 401 || status === 403) return new SyncError('retry', `${what}: the blockchain server rejected the API key${detail}`);
  if (status === 404 || status === 409 || status === 429 || status >= 500) return new SyncError('retry', `${what} failed (${status})${detail}`);
  return new SyncError('failed', `${what} was refused (${status})${detail}`);
}

export function makeHandler(deps: Deps) {
  return async function handler(req: Request): Promise<Response> {
    if (req.method !== 'POST') return json({ error: 'use POST' }, 405);
    const secret = req.headers.get('x-sync-secret') ?? '';
    if (!secret) return json({ error: 'forbidden' }, 403);

    const cfg = deps.config();
    if (!cfg.supabaseUrl || !cfg.serviceKey || !cfg.chainUrl || !cfg.chainKey) {
      return json({ error: 'not configured: set BLOCKCHAIN_API_URL and BLOCKCHAIN_API_KEY (Edge Functions -> Secrets)' }, 500);
    }
    const c = cfg as Config;

    let body: { check?: boolean } = {};
    try {
      const text = await req.text();
      if (text.trim()) body = JSON.parse(text);
    } catch {
      return json({ error: 'the body must be JSON' }, 400);
    }

    // ---- database (PostgREST RPC with the service role; each function re-checks the shared secret)
    async function rpc<T>(name: string, args: Record<string, unknown>): Promise<T> {
      const res = await deps.fetch(`${c.supabaseUrl}/rest/v1/rpc/${name}`, {
        method: 'POST',
        headers: { apikey: c.serviceKey, Authorization: `Bearer ${c.serviceKey}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ p_secret: secret, ...args }),
        signal: AbortSignal.timeout(DB_TIMEOUT_MS),
      });
      const text = await res.text();
      if (!res.ok) {
        let code = '';
        try { code = JSON.parse(text).code; } catch { /* not JSON */ }
        if (code === '42501' || res.status === 401 || res.status === 403) throw new Forbidden();
        throw new Error(`database call ${name} failed (${res.status})`);
      }
      return (text ? JSON.parse(text) : null) as T;
    }

    // ---- blockchain REST API
    async function chain(method: string, path: string, payload?: unknown): Promise<{ status: number; payload: any }> {
      let res: Response;
      try {
        res = await deps.fetch(c.chainUrl + path, {
          method,
          headers: { Authorization: `Bearer ${c.chainKey}`, 'X-Org': 'platform', ...(payload ? { 'Content-Type': 'application/json' } : {}) },
          body: payload ? JSON.stringify(payload) : undefined,
          redirect: 'error',
          signal: AbortSignal.timeout(CHAIN_TIMEOUT_MS),
        });
      } catch {
        throw new SyncError('retry', 'the blockchain server is not reachable');
      }
      let answer: unknown = null;
      try { answer = await res.json(); } catch { /* no body */ }
      return { status: res.status, payload: answer };
    }

    async function readChain(id: string): Promise<Project | null> {
      const r = await chain('GET', `/projects/${encodeURIComponent(id)}`);
      if (r.status === 404) return null;
      if (r.status !== 200) throw classify(r.status, r.payload, 'reading the project');
      return r.payload as Project;
    }

    async function apply(step: Step): Promise<void> {
      const r = step.kind === 'create' ? await chain('POST', '/projects', step.body)
        : step.kind === 'update' ? await chain('PUT', `/projects/${encodeURIComponent(step.id)}`, step.body)
        : await chain('POST', `/projects/${encodeURIComponent(step.id)}/payments`, step.body);
      if (r.status !== 200 && r.status !== 201) throw classify(r.status, r.payload, describe(step));
    }

    async function syncOne(id: string): Promise<{ outcome: Outcome; message: string }> {
      const want = await rpc<Project | null>('blockchain_sync_snapshot', { p_project_id: id });
      if (!want) return { outcome: 'ok', message: 'not on the chain: the project has no accepted offer' };
      const { steps, notes } = plan(want, await readChain(want.id));
      const done: string[] = [];
      for (const s of steps) {
        await apply(s);
        done.push(describe(s));
      }
      const parts = [done.length ? `applied: ${done.join(', ')}` : 'already up to date', ...notes.map((n) => `NEEDS ATTENTION: ${n}`)];
      return { outcome: notes.length ? 'failed' : 'ok', message: parts.join('; ') };
    }

    try {
      if (body.check === true) {
        await rpc('blockchain_sync_claim', { p_limit: 0 }); // proves the secret, claims nothing
        try {
          const r = await chain('GET', '/health');
          return json({ check: 'ok', blockchainHttpStatus: r.status, blockchain: r.payload }, r.status === 200 ? 200 : 502);
        } catch (e) {
          return json({ check: 'failed', error: (e as Error).message }, 502);
        }
      }

      const started = deps.now();
      const processed: { id: string; outcome: Outcome; message: string }[] = [];
      while (deps.now() - started < BUDGET_MS) {
        const claimed = await rpc<{ pid: string; ver: number }[]>('blockchain_sync_claim', { p_limit: BATCH });
        if (!claimed || claimed.length === 0) break;
        for (const { pid, ver } of claimed) {
          if (deps.now() - started >= BUDGET_MS) break;
          let result: { outcome: Outcome; message: string };
          try {
            result = await syncOne(pid);
          } catch (e) {
            if (e instanceof Forbidden) throw e;
            result = e instanceof SyncError
              ? { outcome: e.outcome, message: e.message }
              : { outcome: 'retry', message: `unexpected error: ${(e as Error).message}` };
          }
          await rpc('blockchain_sync_complete', { p_project_id: pid, p_version: ver, p_outcome: result.outcome, p_message: result.message });
          processed.push({ id: pid, ...result });
        }
      }
      return json({ processed });
    } catch (e) {
      if (e instanceof Forbidden) return json({ error: 'forbidden' }, 403);
      return json({ error: (e as Error).message }, 502);
    }
  };
}
