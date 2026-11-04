import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/marketplace/shared/datasource/models/marketplace_address_model.dart';

void main() {
  test('fromJson maps a v_my_addresses row', () {
    final address = MarketplaceAddressModel.fromJson(const {
      'id': '3f2a1b0c-9d8e-4f7a-8b6c-5d4e3f2a1b0c',
      'name': 'المنزل',
      'city': 'المدينة المنورة',
      'district': 'العزيزية',
      'formatted_address':
          '٢٤٥٠ شارع الملك عبدالله، العزيزية، المدينة المنورة ٤٢٣١١',
    });

    expect(address.id, '3f2a1b0c-9d8e-4f7a-8b6c-5d4e3f2a1b0c');
    expect(address.name, 'المنزل');
    expect(address.city, 'المدينة المنورة');
    expect(address.district, 'العزيزية');
    expect(address.formattedAddress, contains('العزيزية'));
  });
}
