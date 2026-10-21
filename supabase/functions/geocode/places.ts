// Maps Google Places (New) answers onto what `geocode` returns for the
// location picker's search. Pure, so it can be tested without the network.

/** One suggestion under the search field: a city, district or street. */
export interface Suggestion {
  place_id: string;
  /** The place's own name, e.g. «العزيزية». */
  title: string;
  /** Where it is, e.g. «المدينة المنورة، السعودية»; null when Google has none. */
  subtitle: string | null;
}

/** Where a suggestion is, and the area to show around it. */
export interface Place {
  lat: number;
  lng: number;
  /** A city's area is wide, a street's narrow; null shows the point. */
  viewport: { south: number; west: number; north: number; east: number } | null;
}

interface Text {
  text?: string;
}

interface Prediction {
  placeId?: string;
  text?: Text;
  structuredFormat?: { mainText?: Text; secondaryText?: Text };
}

interface LatLng {
  latitude?: number;
  longitude?: number;
}

/** A Places Autocomplete (New) answer → its place suggestions. */
export function toSuggestions(body: unknown): Suggestion[] {
  const suggestions =
    (body as { suggestions?: { placePrediction?: Prediction }[] } | null)
      ?.suggestions ?? [];
  const result: Suggestion[] = [];
  for (const { placePrediction: p } of suggestions) {
    const title = p?.structuredFormat?.mainText?.text ?? p?.text?.text;
    if (!p?.placeId || !title) continue;
    result.push({
      place_id: p.placeId,
      title,
      subtitle: p.structuredFormat?.secondaryText?.text || null,
    });
  }
  return result;
}

/** A Place Details (New) answer with `location,viewport` → the place, or
 * null when Google gave no location. */
export function toPlace(body: unknown): Place | null {
  const { location, viewport } =
    (body as { location?: LatLng; viewport?: { low?: LatLng; high?: LatLng } } | null) ??
      {};
  if (!isPoint(location)) return null;
  const { low, high } = viewport ?? {};
  return {
    lat: location.latitude,
    lng: location.longitude,
    viewport: isPoint(low) && isPoint(high)
      ? {
        south: low.latitude,
        west: low.longitude,
        north: high.latitude,
        east: high.longitude,
      }
      : null,
  };
}

function isPoint(
  point: LatLng | undefined,
): point is { latitude: number; longitude: number } {
  return typeof point?.latitude === "number" &&
    typeof point?.longitude === "number";
}
