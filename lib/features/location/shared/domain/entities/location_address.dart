/// Domain entity representing a physical or postal address in Watad.
/// Shared across roles (clients and contractors).
class LocationAddress {
  /// Creates an instance of [LocationAddress].
  const LocationAddress({
    required this.id,
    required this.name,
    required this.city,
    required this.district,
    required this.street,
    required this.buildingNumber,
    required this.postalCode,
    this.latitude,
    this.longitude,
    this.isSaved = false,
  });

  /// Unique identifier of the address.
  final String id;

  /// Label given to the address (e.g., 'المنزل', 'موقع المشروع').
  final String name;

  /// City name (e.g., 'الرياض').
  final String city;

  /// District or neighborhood (e.g., 'النرجس').
  final String district;

  /// Street name (e.g., 'طريق الأمير سلمان').
  final String street;

  /// Building number (e.g., '7421').
  final String buildingNumber;

  /// Postal code (e.g., '13325').
  final String postalCode;

  /// Latitude coordinate on the map.
  final double? latitude;

  /// Longitude coordinate on the map.
  final double? longitude;

  /// Whether this address is saved in the user's address book.
  final bool isSaved;

  /// Formatted single-line display representation:
  /// e.g. "الرياض · النرجس · طريق الأمير سلمان · 7421"
  String get formattedAddress {
    final parts = [
      city,
      district,
      street,
      buildingNumber,
    ].where((s) => s.trim().isNotEmpty);
    return parts.join(' · ');
  }

  /// Copies this entity with updated fields.
  LocationAddress copyWith({
    String? id,
    String? name,
    String? city,
    String? district,
    String? street,
    String? buildingNumber,
    String? postalCode,
    double? latitude,
    double? longitude,
    bool? isSaved,
  }) {
    return LocationAddress(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      district: district ?? this.district,
      street: street ?? this.street,
      buildingNumber: buildingNumber ?? this.buildingNumber,
      postalCode: postalCode ?? this.postalCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationAddress &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          city == other.city &&
          district == other.district &&
          street == other.street &&
          buildingNumber == other.buildingNumber &&
          postalCode == other.postalCode &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          isSaved == other.isSaved;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    city,
    district,
    street,
    buildingNumber,
    postalCode,
    latitude,
    longitude,
    isSaved,
  );
}
