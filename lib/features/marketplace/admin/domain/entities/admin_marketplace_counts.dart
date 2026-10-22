import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_filter.dart';

/// The number on each chip, for the current search.
class AdminMarketplaceCounts {
  const AdminMarketplaceCounts(this.byFilter);

  final Map<AdminMarketplaceFilter, int> byFilter;

  int of(AdminMarketplaceFilter filter) => byFilter[filter] ?? 0;
}
