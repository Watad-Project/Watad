import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/home/client/datasource/models/client_suggested_contractor_model.dart';

void main() {
  test('fromJson maps a v_public_profiles row with all fields', () {
    final model = ClientSuggestedContractorModel.fromJson(const {
      'id': 'b1234567-7425-40de-944b-e07fc1f90ae7',
      'company_name': 'Al-Bawani Contracting',
      'avatar_path': 'avatars/binaa.jpg',
      'specialized_field': 'General Contracting',
    });

    expect(model.id, 'b1234567-7425-40de-944b-e07fc1f90ae7');
    expect(model.companyName, 'Al-Bawani Contracting');
    expect(model.avatarPath, 'avatars/binaa.jpg');
    expect(model.specializedField, 'General Contracting');
    expect(model.ratingLabel, '—');
    expect(model.projectsLabel, '—');
    expect(model.isVerified, isTrue);
  });

  test('fromJson handles null avatar_path and specialized_field', () {
    final model = ClientSuggestedContractorModel.fromJson(const {
      'id': 'c2345678-7425-40de-944b-e07fc1f90ae7',
      'company_name': 'Rawasi Builders',
      'avatar_path': null,
      'specialized_field': null,
    });

    expect(model.id, 'c2345678-7425-40de-944b-e07fc1f90ae7');
    expect(model.companyName, 'Rawasi Builders');
    expect(model.avatarPath, isNull);
    expect(model.specializedField, isNull);
  });
}
