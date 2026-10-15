import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/offer_status.dart';

void main() {
  test('fromJson parses every offer status from ARCHITECTURE.md §4', () {
    expect(OfferStatus.fromJson('pending'), OfferStatus.pending);
    expect(OfferStatus.fromJson('accepted'), OfferStatus.accepted);
    expect(OfferStatus.fromJson('rejected'), OfferStatus.rejected);
    expect(OfferStatus.fromJson('withdrawn'), OfferStatus.withdrawn);
  });

  test('fromJson throws on unknown status', () {
    expect(() => OfferStatus.fromJson('unknown'), throwsStateError);
  });

  test('toJson matches the value', () {
    expect(OfferStatus.pending.toJson(), 'pending');
    expect(OfferStatus.accepted.toJson(), 'accepted');
  });
}
