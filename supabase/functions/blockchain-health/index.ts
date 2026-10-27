// blockchain-health: does the blockchain answer? For the admin's blockchain
// monitor (GRA-53). It asks the Fabric REST API's `GET /health`, the same
// endpoint blockchain-sync's check uses, and times the answer.
//
// POST {}  (no body needed)
// 200  { reachable, http_status, latency_ms, checked_at, details, error }
//        reachable    true when the API answered 200
//        http_status  the API's status, or null when it didn't answer
//        latency_ms   how long the answer took, or null when it didn't answer
//        checked_at   when this check ran (ISO 8601, UTC)
//        details      the API's JSON answer (node details, if it gives them),
//                     or null
//        error        null, "timeout", "unreachable" or "bad_status"
// 401  { error: "unauthorized" }    signed-in users only
// 403  { error: "forbidden" }       admins only (v_my_profile.is_admin)
// 500  { error: "not_configured" }  the blockchain secrets are missing
//
// The API's address and key (BLOCKCHAIN_API_URL, BLOCKCHAIN_API_KEY) are
// server secrets, shared with blockchain-sync: the app never sees them
// (AGENTS.md golden rules 1 and 2). Deployed with verify_jwt off; the
// function checks the caller's session itself (ARCHITECTURE.md §6).

import { createClient } from "jsr:@supabase/supabase-js@2";

const json = (body: unknown, status = 200) => Response.json(body, { status });

/** How long the API may take before it counts as not answering. */
const TIMEOUT_MS = 10000;

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  // Only a signed-in admin may look at the blockchain.
  const authorization = req.headers.get("Authorization") ?? "";
  const token = authorization.replace(/^Bearer\s+/i, "");
  if (!token) return json({ error: "unauthorized" }, 401);
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authorization } } },
  );
  const { data: user, error: userError } = await supabase.auth.getUser(token);
  if (userError || !user.user) return json({ error: "unauthorized" }, 401);
  const { data: profile } = await supabase
    .from("v_my_profile")
    .select("is_admin")
    .maybeSingle();
  if (profile?.is_admin !== true) return json({ error: "forbidden" }, 403);

  const url = (Deno.env.get("BLOCKCHAIN_API_URL") ?? "").replace(/\/+$/, "");
  const key = Deno.env.get("BLOCKCHAIN_API_KEY") ?? "";
  if (!url || !key) return json({ error: "not_configured" }, 500);

  const checkedAt = new Date().toISOString();
  const started = performance.now();
  let res: Response;
  try {
    res = await fetch(`${url}/health`, {
      headers: { Authorization: `Bearer ${key}`, "X-Org": "platform" },
      redirect: "error",
      signal: AbortSignal.timeout(TIMEOUT_MS),
    });
  } catch (e) {
    const timedOut = e instanceof DOMException && e.name === "TimeoutError";
    return json({
      reachable: false,
      http_status: null,
      latency_ms: null,
      checked_at: checkedAt,
      details: null,
      error: timedOut ? "timeout" : "unreachable",
    });
  }
  const latencyMs = Math.round(performance.now() - started);

  let details: unknown = null;
  try {
    const answer = await res.json();
    if (typeof answer === "object" && answer !== null) details = answer;
  } catch {
    // No JSON body.
  }
  const reachable = res.status === 200;
  return json({
    reachable,
    http_status: res.status,
    latency_ms: latencyMs,
    checked_at: checkedAt,
    details,
    error: reachable ? null : "bad_status",
  });
});
