import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/marketplace_category.dart';

void main() {
  test('round-trips every marketplace_category value', () {
    for (final category in MarketplaceCategory.values) {
      expect(MarketplaceCategory.fromJson(category.toJson()), category);
    }
    expect(MarketplaceCategory.values, hasLength(14));
    expect(MarketplaceCategory.steelMetals.toJson(), 'steel_metals');
    expect(MarketplaceCategory.hvac.toJson(), 'hvac');
    expect(MarketplaceCategory.other.toJson(), 'other');
  });

  test('throws on an unknown marketplace_category value', () {
    expect(() => MarketplaceCategory.fromJson('unknown'), throwsStateError);
  });
}
