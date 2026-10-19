import 'package:watad/features/location/shared/domain/entities/location_address.dart';

/// Data model for [LocationAddress] with JSON serialization.
class LocationAddressModel extends LocationAddress {
  /// Creates an instance of [LocationAddressModel].
  const LocationAddressModel({
    required super.id,
    required super.name,
    required super.city,
    required super.district,
    required super.street,
    required super.buildingNumber,
    required super.postalCode,
    super.latitude,
    super.longitude,
    super.additionalNumber,
    super.shortAddress,
    super.isSaved = false,
  });

  /// Creates a model from a JSON map.
  factory LocationAddressModel.fromJson(Map<String, dynamic> json) {
    return LocationAddressModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      district: json['district'] as String? ?? '',
      street: json['street'] as String? ?? '',
      buildingNumber: json['building_number'] as String? ?? '',
      postalCode: json['postal_code'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      additionalNumber: json['additional_number'] as String?,
      shortAddress: json['short_address'] as String?,
      isSaved: json['is_saved'] as bool? ?? true,
    );
  }

  /// Creates an address model from the `geocode` Edge Function response.
  factory LocationAddressModel.fromGeocode(
    Map<String, dynamic> json, {
    double? lat,
    double? lng,
  }) {
    return LocationAddressModel(
      id: '',
      name: '',
      city: (json['city'] as String?)?.trim() ?? '',
      district: (json['district'] as String?)?.trim() ?? '',
      street: (json['street'] as String?)?.trim() ?? '',
      buildingNumber: (json['building_number'] as String?)?.trim() ?? '',
      postalCode: (json['postal_code'] as String?)?.trim() ?? '',
      latitude: lat ?? (json['lat'] as num?)?.toDouble(),
      longitude: lng ?? (json['lng'] as num?)?.toDouble(),
      additionalNumber: (json['additional_number'] as String?)?.trim(),
      shortAddress: (json['short_address'] as String?)?.trim(),
      isSaved: false,
    );
  }

  /// Creates a model from a [LocationAddress] entity.
  factory LocationAddressModel.fromEntity(LocationAddress entity) {
    return LocationAddressModel(
      id: entity.id,
      name: entity.name,
      city: entity.city,
      district: entity.district,
      street: entity.street,
      buildingNumber: entity.buildingNumber,
      postalCode: entity.postalCode,
      latitude: entity.latitude,
      longitude: entity.longitude,
      additionalNumber: entity.additionalNumber,
      shortAddress: entity.shortAddress,
      isSaved: entity.isSaved,
    );
  }

  /// Only the 6 allowed columns for Supabase `addresses` table writes (ARCHITECTURE.md §3a).
  Map<String, dynamic> toSupabaseMap() {
    final effectiveName = name.trim().isNotEmpty
        ? name.trim()
        : (district.trim().isNotEmpty ? district.trim() : city.trim());
    return {
      'name': effectiveName,
      'city': city.trim(),
      'district': district.trim(),
      'street': street.trim(),
      'building_number': buildingNumber.trim(),
      'postal_code': postalCode.trim(),
    };
  }

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'district': district,
      'street': street,
      'building_number': buildingNumber,
      'postal_code': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'additional_number': additionalNumber,
      'short_address': shortAddress,
      'is_saved': isSaved,
    };
  }

  /// Converts this model to a domain [LocationAddress] entity.
  LocationAddress toEntity() {
    return LocationAddress(
      id: id,
      name: name,
      city: city,
      district: district,
      street: street,
      buildingNumber: buildingNumber,
      postalCode: postalCode,
      latitude: latitude,
      longitude: longitude,
      additionalNumber: additionalNumber,
      shortAddress: shortAddress,
      isSaved: isSaved,
    );
  }
}
