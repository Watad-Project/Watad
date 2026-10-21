import 'package:watad/core/utils/money.dart';

/// Accepting an offer at the amount the client saw: the server refuses if
/// the contractor changed it meanwhile.
class ClientAcceptOfferParams {
  const ClientAcceptOfferParams({
    required this.offerId,
    required this.expectedAmount,
  });

  final String offerId;
  final Money expectedAmount;
}
