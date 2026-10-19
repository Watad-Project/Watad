// geocode: the address of a point on the map (the location picker, GRA-19).
//
// POST { "lat": number, "lng": number, "language"?: "ar" | "en" }
// 200  { city, district, street, building_number, postal_code,
//        additional_number, short_address, formatted_address }  (unknown = null)
// 400  { error: "invalid_body" | "invalid_coordinates" }
// 401  { error: "unauthorized" }        signed-in users only
// 502  { error: "geocoder_unavailable" }
//
// The Google key (GOOGLE_MAPS_SERVER_KEY) stays here, as a server secret: the
// app never sees it. Deployed with verify_jwt off; the function checks the
// caller's session itself (ARCHITECTURE.md §6).

import { createClient } from "jsr:@supabase/supabase-js@2";
import { toAddress } from "./address.ts";

const json = (body: unknown, status = 200) => Response.json(body, { status });

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  // Only a signed-in user may spend the Google quota.
  const token = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
  if (!token) return json({ error: "unauthorized" }, 401);
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
  );
  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data.user) return json({ error: "unauthorized" }, 401);

  let lat: unknown, lng: unknown, language: unknown;
  try {
    ({ lat, lng, language } = await req.json());
  } catch {
    return json({ error: "invalid_body" }, 400);
  }
  if (
    typeof lat !== "number" || typeof lng !== "number" ||
    Math.abs(lat) > 90 || Math.abs(lng) > 180
  ) {
    return json({ error: "invalid_coordinates" }, 400);
  }

  const key = Deno.env.get("GOOGLE_MAPS_SERVER_KEY");
  if (!key) {
    console.error("geocode: GOOGLE_MAPS_SERVER_KEY is not set");
    return json({ error: "geocoder_unavailable" }, 502);
  }

  const url = new URL("https://maps.googleapis.com/maps/api/geocode/json");
  url.searchParams.set("latlng", `${lat},${lng}`);
  url.searchParams.set("language", language === "en" ? "en" : "ar");
  url.searchParams.set("key", key);

  const response = await fetch(url);
  if (!response.ok) {
    console.error("geocode: Google answered HTTP", response.status);
    return json({ error: "geocoder_unavailable" }, 502);
  }
  const body = await response.json();
  if (body.status === "ZERO_RESULTS") return json(toAddress([]));
  if (body.status !== "OK") {
    console.error("geocode: Google status", body.status, body.error_message);
    return json({ error: "geocoder_unavailable" }, 502);
  }
  return json(toAddress(body.results));
});
