import 'package:watad/features/marketplace/shared/domain/entities/marketplace_address.dart';

class MarketplaceAddressModel extends MarketplaceAddress {
  const MarketplaceAddressModel({
    required super.id,
    required super.name,
    required super.city,
    required super.district,
    required super.formattedAddress,
  });

  /// Maps a `v_my_addresses` row selected by [OrdersRemoteDataSourceImpl].
  factory MarketplaceAddressModel.fromJson(Map<String, dynamic> json) {
    return MarketplaceAddressModel(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String,
      district: json['district'] as String,
      formattedAddress: json['formatted_address'] as String? ?? '',
    );
  }
}
