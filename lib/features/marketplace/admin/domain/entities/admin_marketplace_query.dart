import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_filter.dart';

/// One page of the listings: the chip, the search (an item or a seller name)
/// and where the page starts.
class AdminMarketplaceQuery {
  const AdminMarketplaceQuery({
    required this.filter,
    required this.offset,
    required this.limit,
    this.search = '',
  });

  final AdminMarketplaceFilter filter;
  final String search;
  final int offset;
  final int limit;
}
