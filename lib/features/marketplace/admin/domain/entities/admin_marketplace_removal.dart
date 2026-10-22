import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_item.dart';

/// «إزالة المنتج»: the listing, and the reason its seller reads.
class AdminMarketplaceRemoval {
  const AdminMarketplaceRemoval({required this.item, required this.reason});

  /// The most the database keeps of a reason.
  static const int maxReasonLength = 1000;

  final AdminMarketplaceItem item;
  final String reason;
}
