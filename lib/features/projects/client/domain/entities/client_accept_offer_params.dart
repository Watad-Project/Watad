import 'package:watad/core/utils/money.dart';

/// Parameters required to accept a contractor's offer through `accept_offer` RPC.
class ClientAcceptOfferParams {
  const ClientAcceptOfferParams({
    required this.offerId,
    required this.expectedAmount,
  });

  final String offerId;
  final Money expectedAmount;
}
