/// A saved address belonging to the client, loaded from Supabase `v_my_addresses`.
class ClientSavedAddress {
  const ClientSavedAddress({
    required this.id,
    required this.name,
    required this.city,
    required this.formattedAddress,
    this.district,
    this.street,
    this.buildingNumber,
    this.postalCode,
  });

  final String id;
  final String name;
  final String city;
  final String formattedAddress;
  final String? district;
  final String? street;
  final String? buildingNumber;
  final String? postalCode;
}
