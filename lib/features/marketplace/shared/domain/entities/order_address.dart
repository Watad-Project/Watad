/// The delivery address as it was at checkout
/// (`v_my_orders.delivery_address`). Editing or deleting the saved address
/// never changes it.
class OrderAddress {
  const OrderAddress({
    this.name,
    this.city,
    this.district,
    this.formattedAddress,
  });

  final String? name;
  final String? city;
  final String? district;
  final String? formattedAddress;
}
