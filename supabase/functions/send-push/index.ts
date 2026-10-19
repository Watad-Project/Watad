// send-push: delivers a notifications row as a push through OneSignal
// (GRA-32).
//
// Called by the database right after a row is inserted into
// public.notifications (trigger notifications_push, migration 67):
//
// POST { "notification_id": uuid }   header x-push-secret
// 200  { status: "sent", onesignal_id }
//      { status: "skipped" }   already handled, or the user has the app open:
//                              the app shows it (push_status 'in_app')
// 400  { error: "invalid_body" }
// 403  { error: "forbidden" }            wrong or missing secret
// 502  { error: "push_failed" }          OneSignal refused it (see push_error)
//
// OneSignal targets the user's devices by external_id = the user id, which
// the app sets with OneSignal.login() after sign-in. The OneSignal keys
// (ONESIGNAL_APP_ID, ONESIGNAL_REST_API_KEY) stay here, as server secrets:
// the app never sees the REST API key. Deployed with verify_jwt off; the
// database checks the secret on every call (push_claim, push_complete).

import { createClient } from "jsr:@supabase/supabase-js@2";

const json = (body: unknown, status = 200) => Response.json(body, { status });

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const secret = req.headers.get("x-push-secret");
  if (!secret) return json({ error: "forbidden" }, 403);

  let notificationId: unknown;
  try {
    ({ notification_id: notificationId } = await req.json());
  } catch {
    return json({ error: "invalid_body" }, 400);
  }
  if (typeof notificationId !== "string") {
    return json({ error: "invalid_body" }, 400);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );
  const complete = (error: string | null) =>
    supabase.rpc("push_complete", {
      p_secret: secret,
      p_notification_id: notificationId,
      p_error: error,
    });

  // The row, once: null when there's nothing to push (already handled, or
  // the user has the app open and sees it there).
  const { data: row, error: claimError } = await supabase.rpc("push_claim", {
    p_secret: secret,
    p_notification_id: notificationId,
  });
  if (claimError) {
    if (claimError.code === "42501") return json({ error: "forbidden" }, 403);
    console.error("send-push: push_claim failed", claimError.message);
    return json({ error: "push_failed" }, 502);
  }
  if (!row) return json({ status: "skipped" });

  const appId = Deno.env.get("ONESIGNAL_APP_ID");
  const apiKey = Deno.env.get("ONESIGNAL_REST_API_KEY");
  if (!appId || !apiKey) {
    console.error("send-push: ONESIGNAL_APP_ID or ONESIGNAL_REST_API_KEY is not set");
    await complete("onesignal_not_configured");
    return json({ error: "push_failed" }, 502);
  }

  const response = await fetch("https://api.onesignal.com/notifications?c=push", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Key ${apiKey}`,
    },
    body: JSON.stringify({
      app_id: appId,
      target_channel: "push",
      include_aliases: { external_id: [row.user_id] },
      // OneSignal needs an "en" text; it is shown in every language.
      headings: { en: row.title },
      contents: { en: row.body },
      // The app opens data.route when the push is tapped.
      data: { ...row.data, notification_id: notificationId },
    }),
  });
  const result = await response.json().catch(() => ({}));

  // OneSignal answers 200 with `errors` too, e.g. when the user has no
  // subscribed device yet.
  const failure = !response.ok
    ? `HTTP ${response.status}: ${JSON.stringify(result.errors ?? result)}`
    : result.errors
    ? JSON.stringify(result.errors)
    : null;
  await complete(failure);
  if (failure) {
    console.error("send-push: OneSignal refused", notificationId, failure);
    return json({ error: "push_failed" }, 502);
  }
  return json({ status: "sent", onesignal_id: result.id ?? null });
});
