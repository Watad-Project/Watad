/// One of the buyer's saved addresses (`v_my_addresses`), to deliver an
/// order to.
class MarketplaceAddress {
  const MarketplaceAddress({
    required this.id,
    required this.name,
    required this.city,
    required this.district,
    required this.formattedAddress,
  });

  final String id;
  final String name;
  final String city;
  final String district;

  /// The whole address on one line, written by the server.
  final String formattedAddress;
}
