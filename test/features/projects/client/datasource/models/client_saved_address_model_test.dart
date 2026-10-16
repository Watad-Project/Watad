import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/projects/client/datasource/models/client_saved_address_model.dart';

void main() {
  group('ClientSavedAddressModel', () {
    test('fromJson parses realistic row correctly', () {
      final json = {
        'id': 'b433cf57-4b7f-4702-8a90-349f2bce374c',
        'name': 'Home Villa',
        'city': 'الرياض',
        'district': 'حي النرجس',
        'street': 'طريق أنس بن مالك',
        'building_number': '4210',
        'postal_code': '13324',
      };

      final model = ClientSavedAddressModel.fromJson(json);

      expect(model.id, 'b433cf57-4b7f-4702-8a90-349f2bce374c');
      expect(model.name, 'Home Villa');
      expect(model.city, 'الرياض');
      expect(model.district, 'حي النرجس');
      expect(model.street, 'طريق أنس بن مالك');
      expect(model.buildingNumber, '4210');
      expect(model.postalCode, '13324');
      expect(
        model.formattedAddress,
        'طريق أنس بن مالك, حي النرجس, الرياض, 4210, 13324',
      );
    });

    test('toJson serializes model accurately', () {
      const model = ClientSavedAddressModel(
        id: 'addr_1',
        name: 'Office',
        city: 'Jeddah',
        district: 'Al-Rawdah',
        street: 'Prince Sultan',
        buildingNumber: '1122',
        postalCode: '23432',
        formattedAddress: 'Prince Sultan, Al-Rawdah, Jeddah',
      );

      final json = model.toJson();

      expect(json['id'], 'addr_1');
      expect(json['name'], 'Office');
      expect(json['city'], 'Jeddah');
      expect(json['district'], 'Al-Rawdah');
      expect(json['street'], 'Prince Sultan');
      expect(json['building_number'], '1122');
      expect(json['postal_code'], '23432');
    });
  });
}
