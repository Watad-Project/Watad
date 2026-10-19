import 'package:watad/features/home/client/domain/entities/client_contractor_filter.dart';

/// One page of the contractors list: [limit] contractors after the first
/// [offset] that match [filter].
class ClientContractorsQuery {
  const ClientContractorsQuery({
    required this.filter,
    required this.offset,
    required this.limit,
  });

  final ClientContractorFilter filter;
  final int offset;
  final int limit;
}
