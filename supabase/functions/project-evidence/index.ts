// project-evidence: a project's signed evidence, for its PDF (GRA-72, GRA-73).
//
// It collects the project from the database (project_evidence_collect(),
// migration 84) and its copy from the blockchain (the Fabric REST API's
// GET /projects/{id}, as blockchain-sync reads it), compares the two with
// blockchain-sync's own rules (../_shared/reconcile.ts), writes it all as
// canonical JSON, fingerprints it with SHA-256, signs it with Ed25519 and
// keeps a record of the export (project_evidence_record()).
//
// POST { "project_id": uuid }          signed in (Authorization: Bearer <session>)
// 200  { export_id, exported_at, evidence, comparison, fingerprint,
//        signature, key_id, public_key }
//        fingerprint  SHA-256 of canonicalJson(evidence), lower-case hex
//        signature    Ed25519 of the same canonical JSON, base64
//        public_key   the signing key's public half, base64url (JWK "x")
// 400  { error: "invalid_body" }
// 401  { error: "unauthorized" }        signed-in users only
// 403  { error: "not_allowed" }         not the project's owner, taker or an admin
// 404  { error: "project_not_found" }
// 409  { error: "not_on_chain" }        the project has no accepted offer
//      { error: "not_on_chain_yet" }    agreed, but the sync hasn't copied it yet
// 502  { error: "ledger_unavailable" }  the blockchain didn't answer, or refused
// 504  { error: "timeout" }             the blockchain took too long
// 500  { error: "not_configured" }      a secret below is missing or wrong
//
// It never answers with evidence that lacks the chain's copy.
//
// Secrets (Edge Functions -> Secrets), server-side only (AGENTS.md golden
// rules 1 and 2):
//   BLOCKCHAIN_API_URL, BLOCKCHAIN_API_KEY  shared with blockchain-sync
//   PROJECT_EVIDENCE_SECRET  the Vault secret project_evidence_secret
//   EVIDENCE_SIGNING_KEY     an Ed25519 private key, PKCS#8 DER in base64:
//                            openssl genpkey -algorithm ed25519 -outform DER | base64
//   EVIDENCE_SIGNING_KEY_ID  a name for that key, e.g. "evidence-2026-10"
// The last three are optional since migration 90 (GRA-76): whatever isn't
// set here comes from the Vault (project_evidence_config()), and the first
// export makes an Ed25519 key on the server and keeps it there
// (project_evidence_store_signing_key()). The key never leaves the server.
// Deployed with verify_jwt off; the function checks the caller's session
// itself (ARCHITECTURE.md §6).

import { createClient, type SupabaseClient } from 'jsr:@supabase/supabase-js@2';
import type { Project } from '../_shared/reconcile.ts';
import { compare, fingerprintAndSign, fromBase64, toBase64 } from './evidence.ts';

const json = (body: unknown, status = 200) => Response.json(body, { status });

/** How long the blockchain may take before the export fails with "timeout". */
const CHAIN_TIMEOUT_MS = 15_000;

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** The version of the evidence's shape; change it when the shape changes. */
const FORMAT = 'watad-project-evidence/1';

/** The errors project_evidence_collect() raises, as the app sees them. */
const COLLECT_ERRORS: Record<string, [string, number]> = {
  not_allowed: ['not_allowed', 403],
  project_not_found: ['project_not_found', 404],
  not_on_chain: ['not_on_chain', 409],
  forbidden: ['not_configured', 500],
};

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') return json({ error: 'method_not_allowed' }, 405);

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const chainUrl = (Deno.env.get('BLOCKCHAIN_API_URL') ?? '').replace(/\/+$/, '');
  const chainKey = Deno.env.get('BLOCKCHAIN_API_KEY') ?? '';

  // Only a signed-in user, checked before anything else.
  const token = req.headers.get('Authorization')?.replace(/^Bearer\s+/i, '');
  if (!token) return json({ error: 'unauthorized' }, 401);
  const auth = createClient(supabaseUrl, Deno.env.get('SUPABASE_ANON_KEY')!);
  const { data: user, error: userError } = await auth.auth.getUser(token);
  if (userError || !user.user) return json({ error: 'unauthorized' }, 401);

  let projectId: unknown;
  try {
    ({ project_id: projectId } = await req.json());
  } catch {
    return json({ error: 'invalid_body' }, 400);
  }
  if (typeof projectId !== 'string' || !UUID.test(projectId)) {
    return json({ error: 'invalid_body' }, 400);
  }

  if (!chainUrl || !chainKey) return json({ error: 'not_configured' }, 500);

  // The database: checks the caller, and reads what the sync sends.
  const db = createClient(supabaseUrl, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

  const keys = await evidenceKeys(db);
  if (!keys) return json({ error: 'not_configured' }, 500);
  const { dbSecret, signingKey, keyId } = keys;
  let privateKey: CryptoKey;
  let publicKey: string;
  try {
    privateKey = await crypto.subtle.importKey('pkcs8', fromBase64(signingKey), 'Ed25519', true, ['sign']);
    publicKey = (await crypto.subtle.exportKey('jwk', privateKey)).x ?? '';
  } catch {
    return json({ error: 'not_configured' }, 500);
  }

  const collected = await db.rpc('project_evidence_collect', {
    p_secret: dbSecret,
    p_user_id: user.user.id,
    p_project_id: projectId,
  });
  if (collected.error) {
    const [error, status] = COLLECT_ERRORS[collected.error.message] ?? ['server_error', 500];
    return json({ error }, status);
  }
  const database = collected.data as Record<string, unknown> & { snapshot: Project | null; caller_role: string };
  if (!database.snapshot) return json({ error: 'not_on_chain' }, 409);

  // The chain's copy.
  let chainRes: Response;
  try {
    chainRes = await fetch(`${chainUrl}/projects/${encodeURIComponent(projectId)}`, {
      headers: { Authorization: `Bearer ${chainKey}`, 'X-Org': 'platform' },
      redirect: 'error',
      signal: AbortSignal.timeout(CHAIN_TIMEOUT_MS),
    });
  } catch (e) {
    const timedOut = e instanceof DOMException && e.name === 'TimeoutError';
    return json({ error: timedOut ? 'timeout' : 'ledger_unavailable' }, timedOut ? 504 : 502);
  }
  if (chainRes.status === 404) return json({ error: 'not_on_chain_yet' }, 409);
  let chain: Project;
  try {
    if (chainRes.status !== 200) throw new Error(`status ${chainRes.status}`);
    chain = await chainRes.json();
  } catch {
    return json({ error: 'ledger_unavailable' }, 502);
  }
  const chainReadAt = new Date().toISOString();

  const comparison = compare(database.snapshot, chain);
  const exportId = crypto.randomUUID();
  const exportedAt = new Date().toISOString();
  const { snapshot, caller_role: callerRole, ...details } = database;
  const evidence = {
    format: FORMAT,
    export_id: exportId,
    exported_at: exportedAt,
    exported_by: { user_id: user.user.id, role: callerRole },
    ...details,
    database_record: snapshot,
    chain: { record: chain, read_at: chainReadAt },
    comparison,
  };
  const { fingerprint, signature } = await fingerprintAndSign(evidence, privateKey);

  const saved = await db.rpc('project_evidence_record', {
    p_secret: dbSecret,
    p_export_id: exportId,
    p_exported_at: exportedAt,
    p_user_id: user.user.id,
    p_project_id: projectId,
    p_fingerprint: fingerprint,
    p_signature: signature,
    p_key_id: keyId,
  });
  if (saved.error) return json({ error: 'server_error' }, 500);

  return json({
    export_id: exportId,
    exported_at: exportedAt,
    evidence,
    comparison,
    fingerprint,
    signature,
    key_id: keyId,
    public_key: publicKey,
  });
});

interface EvidenceKeys {
  dbSecret: string;
  signingKey: string;
  keyId: string;
}

/** What project_evidence_config() and project_evidence_store_signing_key() return (migration 90). */
interface VaultKeys {
  db_secret: string | null;
  signing_key: string | null;
  key_id: string | null;
}

/**
 * The shared secret and the signing key: the function's own secrets when they are set, else the Vault's. When
 * neither has a signing key, the first export makes an Ed25519 key here and stores it in the Vault; a second export
 * at the same moment gets the stored one back. Null when they can't be found or stored.
 */
async function evidenceKeys(db: SupabaseClient): Promise<EvidenceKeys | null> {
  const fromEnv: EvidenceKeys = {
    dbSecret: Deno.env.get('PROJECT_EVIDENCE_SECRET') ?? '',
    signingKey: Deno.env.get('EVIDENCE_SIGNING_KEY') ?? '',
    keyId: Deno.env.get('EVIDENCE_SIGNING_KEY_ID') ?? '',
  };
  const envHasKey = Boolean(fromEnv.signingKey && fromEnv.keyId);
  if (fromEnv.dbSecret && envHasKey) return fromEnv;

  const stored = await db.rpc('project_evidence_config');
  if (stored.error) return null;
  let vault = stored.data as VaultKeys;
  if (!envHasKey && !vault.signing_key) {
    let pkcs8: string;
    try {
      const pair = (await crypto.subtle.generateKey('Ed25519', true, ['sign', 'verify'])) as CryptoKeyPair;
      pkcs8 = toBase64(await crypto.subtle.exportKey('pkcs8', pair.privateKey));
    } catch {
      return null;
    }
    const saved = await db.rpc('project_evidence_store_signing_key', {
      p_key: pkcs8,
      p_key_id: `evidence-${new Date().toISOString().slice(0, 7)}`,
    });
    if (saved.error) return null;
    vault = saved.data as VaultKeys;
  }
  const keys: EvidenceKeys = {
    dbSecret: fromEnv.dbSecret || vault.db_secret || '',
    // The key and its id always come from the same place.
    signingKey: envHasKey ? fromEnv.signingKey : vault.signing_key ?? '',
    keyId: envHasKey ? fromEnv.keyId : vault.key_id ?? '',
  };
  return keys.dbSecret && keys.signingKey && keys.keyId ? keys : null;
}
