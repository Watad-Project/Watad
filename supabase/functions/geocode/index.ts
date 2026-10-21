// geocode: places for the location picker (GRA-19). Three requests, told
// apart by their body:
//
// The address of a point on the map:
// POST { "lat": number, "lng": number, "language"?: "ar" | "en" }
// 200  { city, district, street, building_number, postal_code,
//        additional_number, short_address, formatted_address }  (unknown = null)
//
// Places matching what the user types (a city, district or street), in
// Saudi Arabia, nearest to lat/lng first when they're given:
// POST { "query": string, "language"?: "ar" | "en", "lat"?: number, "lng"?: number }
// 200  { suggestions: [{ place_id, title, subtitle }] }  (subtitle may be null)
//
// Where a suggestion is, and the area to show (wide for a city):
// POST { "place_id": string }
// 200  { lat, lng, viewport: { south, west, north, east } | null }
//
// 400  { error: "invalid_body" | "invalid_coordinates" | "invalid_query" | "invalid_place" }
// 401  { error: "unauthorized" }        signed-in users only
// 502  { error: "geocoder_unavailable" }
//
// The Google key (GOOGLE_MAPS_SERVER_KEY) stays here, as a server secret: the
// app never sees it. The search needs the Places API (New) enabled for it.
// Deployed with verify_jwt off; the function checks the caller's session
// itself (ARCHITECTURE.md §6).

import { createClient } from "jsr:@supabase/supabase-js@2";
import { toAddress } from "./address.ts";
import { toPlace, toSuggestions } from "./places.ts";

const json = (body: unknown, status = 200) => Response.json(body, { status });

/** Google's place ids: letters, digits, `-` and `_`. */
const PLACE_ID = /^[A-Za-z0-9_-]{1,512}$/;

/** How far around lat/lng the search prefers places: 50 km, Google's most. */
const NEARBY_METERS = 50000;

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

  let body: Record<string, unknown>;
  try {
    const parsed = await req.json();
    if (typeof parsed !== "object" || parsed === null) {
      throw new Error("not an object");
    }
    body = parsed;
  } catch {
    return json({ error: "invalid_body" }, 400);
  }
  const language = body.language === "en" ? "en" : "ar";

  if ("query" in body) return await search(body, language);
  if ("place_id" in body) return await place(body);
  return await addressAt(body, language);
});

/** body.lat and body.lng, when they're a point on Earth. */
function pointOf(
  body: Record<string, unknown>,
): { lat: number; lng: number } | null {
  const { lat, lng } = body;
  return typeof lat === "number" && typeof lng === "number" &&
      Math.abs(lat) <= 90 && Math.abs(lng) <= 180
    ? { lat, lng }
    : null;
}

function serverKey(): string | null {
  const key = Deno.env.get("GOOGLE_MAPS_SERVER_KEY");
  if (!key) console.error("geocode: GOOGLE_MAPS_SERVER_KEY is not set");
  return key ?? null;
}

async function addressAt(body: Record<string, unknown>, language: string) {
  const point = pointOf(body);
  if (!point) return json({ error: "invalid_coordinates" }, 400);
  const key = serverKey();
  if (!key) return json({ error: "geocoder_unavailable" }, 502);

  const url = new URL("https://maps.googleapis.com/maps/api/geocode/json");
  url.searchParams.set("latlng", `${point.lat},${point.lng}`);
  url.searchParams.set("language", language);
  url.searchParams.set("key", key);

  const response = await fetch(url);
  if (!response.ok) {
    console.error("geocode: Google answered HTTP", response.status);
    return json({ error: "geocoder_unavailable" }, 502);
  }
  const answer = await response.json();
  if (answer.status === "ZERO_RESULTS") return json(toAddress([]));
  if (answer.status !== "OK") {
    console.error("geocode: Google status", answer.status, answer.error_message);
    return json({ error: "geocoder_unavailable" }, 502);
  }
  return json(toAddress(answer.results));
}

async function search(body: Record<string, unknown>, language: string) {
  const query = typeof body.query === "string" ? body.query.trim() : "";
  if (query.length < 2 || query.length > 100) {
    return json({ error: "invalid_query" }, 400);
  }
  const key = serverKey();
  if (!key) return json({ error: "geocoder_unavailable" }, 502);

  const request: Record<string, unknown> = {
    input: query,
    languageCode: language,
    includedRegionCodes: ["sa"],
  };
  const near = pointOf(body);
  if (near) {
    request.locationBias = {
      circle: {
        center: { latitude: near.lat, longitude: near.lng },
        radius: NEARBY_METERS,
      },
    };
  }

  const response = await fetch(
    "https://places.googleapis.com/v1/places:autocomplete",
    {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-Goog-Api-Key": key },
      body: JSON.stringify(request),
    },
  );
  if (!response.ok) {
    // 403 PERMISSION_DENIED: the Places API (New) isn't enabled for the key.
    console.error(
      "geocode: Places autocomplete answered HTTP",
      response.status,
      await response.text(),
    );
    return json({ error: "geocoder_unavailable" }, 502);
  }
  return json({ suggestions: toSuggestions(await response.json()) });
}

async function place(body: Record<string, unknown>) {
  const id = body.place_id;
  if (typeof id !== "string" || !PLACE_ID.test(id)) {
    return json({ error: "invalid_place" }, 400);
  }
  const key = serverKey();
  if (!key) return json({ error: "geocoder_unavailable" }, 502);

  const response = await fetch(`https://places.googleapis.com/v1/places/${id}`, {
    headers: { "X-Goog-Api-Key": key, "X-Goog-FieldMask": "location,viewport" },
  });
  if (response.status === 400 || response.status === 404) {
    return json({ error: "invalid_place" }, 400);
  }
  if (!response.ok) {
    console.error(
      "geocode: Place details answered HTTP",
      response.status,
      await response.text(),
    );
    return json({ error: "geocoder_unavailable" }, 502);
  }
  const found = toPlace(await response.json());
  return found ? json(found) : json({ error: "invalid_place" }, 400);
}
