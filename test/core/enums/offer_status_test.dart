import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/offer_status.dart';

void main() {
  test('OfferStatus serializes and deserializes', () {
    expect(OfferStatus.fromJson('pending'), OfferStatus.pending);
    expect(OfferStatus.fromJson('accepted'), OfferStatus.accepted);
    expect(OfferStatus.fromJson('rejected'), OfferStatus.rejected);
    expect(OfferStatus.fromJson('withdrawn'), OfferStatus.withdrawn);

    expect(OfferStatus.pending.toJson(), 'pending');
    expect(() => OfferStatus.fromJson('unknown'), throwsStateError);
  });
}
