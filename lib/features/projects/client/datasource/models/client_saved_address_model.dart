import 'package:watad/features/projects/client/domain/entities/client_saved_address.dart';

/// Data model representing a row in `v_my_addresses`.
class ClientSavedAddressModel extends ClientSavedAddress {
  const ClientSavedAddressModel({
    required super.id,
    required super.name,
    required super.city,
    required super.formattedAddress,
    super.district,
    super.street,
    super.buildingNumber,
    super.postalCode,
  });

  factory ClientSavedAddressModel.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final name = (json['name'] as String? ?? '').trim();
    final city = (json['city'] as String? ?? '').trim();
    final district = (json['district'] as String? ?? '').trim();
    final street = (json['street'] as String? ?? '').trim();
    final buildingNumber = (json['building_number'] as String? ?? '').trim();
    final postalCode = (json['postal_code'] as String? ?? '').trim();

    final parts = <String>[
      if (street.isNotEmpty) street,
      if (district.isNotEmpty) district,
      if (city.isNotEmpty) city,
      if (buildingNumber.isNotEmpty) buildingNumber,
      if (postalCode.isNotEmpty) postalCode,
    ];

    final formatted = parts.isNotEmpty
        ? parts.join(', ')
        : (name.isNotEmpty ? name : city);

    return ClientSavedAddressModel(
      id: id,
      name: name.isNotEmpty ? name : (district.isNotEmpty ? district : city),
      city: city,
      district: district.isNotEmpty ? district : null,
      street: street.isNotEmpty ? street : null,
      buildingNumber: buildingNumber.isNotEmpty ? buildingNumber : null,
      postalCode: postalCode.isNotEmpty ? postalCode : null,
      formattedAddress: formatted,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'city': city,
    'district': district,
    'street': street,
    'building_number': buildingNumber,
    'postal_code': postalCode,
  };
}
