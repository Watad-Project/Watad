// Maps a Google Geocoding answer onto the address the app saves: the
// columns of `addresses` (ARCHITECTURE.md §3a) plus the two extras of the
// Saudi national address. Pure, so it can be tested without the network.

/** One address component of a Google Geocoding result. */
export interface GoogleComponent {
  long_name: string;
  short_name: string;
  types: string[];
}

/** One Google Geocoding result, as far as the mapping reads it. */
export interface GoogleResult {
  formatted_address?: string;
  address_components: GoogleComponent[];
}

/** What `geocode` returns. A field Google doesn't know is null: the user types it. */
export interface GeocodedAddress {
  city: string | null;
  district: string | null;
  street: string | null;
  building_number: string | null;
  postal_code: string | null;
  /** The national address's additional number (4 digits). No column yet. */
  additional_number: string | null;
  /** The national short address, e.g. RAYB6780. No column yet. */
  short_address: string | null;
  formatted_address: string | null;
}

const EMPTY: GeocodedAddress = {
  city: null,
  district: null,
  street: null,
  building_number: null,
  postal_code: null,
  additional_number: null,
  short_address: null,
  formatted_address: null,
};

/** Four letters and four digits, e.g. RAYB6780. */
const SHORT_ADDRESS = /^[A-Z]{4}\d{4}$/;

export function toAddress(results: GoogleResult[]): GeocodedAddress {
  // Google lists the most precise result first, but a landmark can come
  // before the parcel. Prefer the result that has a building number.
  const best =
    results.find((r) => component(r, "street_number") !== null) ?? results[0];
  if (!best) return { ...EMPTY };

  const premise = component(best, "premise");
  return {
    city: component(best, "locality"),
    district:
      component(best, "sublocality_level_1") ?? component(best, "neighborhood"),
    street: component(best, "route"),
    building_number: component(best, "street_number"),
    postal_code: component(best, "postal_code"),
    additional_number: component(best, "postal_code_suffix"),
    short_address: premise !== null && SHORT_ADDRESS.test(premise)
      ? premise
      : null,
    formatted_address: best.formatted_address ?? null,
  };
}

function component(result: GoogleResult, type: string): string | null {
  return (
    result.address_components.find((c) => c.types.includes(type))?.long_name ??
      null
  );
}
