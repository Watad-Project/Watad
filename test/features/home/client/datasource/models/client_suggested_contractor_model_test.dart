import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/home/client/datasource/models/client_suggested_contractor_model.dart';

void main() {
  group('ClientSuggestedContractorModel', () {
    test(
      'parses full json with rating and completed projects count correctly',
      () {
        final json = {
          'id': 'b-123',
          'company_name': 'Solid Contracting',
          'avatar_path': 'avatars/b-123.jpg',
          'specialized_field': 'Building',
          'rating': 4.9,
          'completed_projects_count': 12,
          'verification_status': 'verified',
        };

        final model = ClientSuggestedContractorModel.fromJson(json);

        expect(model.id, 'b-123');
        expect(model.companyName, 'Solid Contracting');
        expect(model.avatarPath, 'avatars/b-123.jpg');
        expect(model.specializedField, 'Building');
        expect(model.rating, 4.9);
        expect(model.completedProjectsCount, 12);
        expect(model.isVerified, isTrue);
      },
    );

    test('handles fallback column names gracefully', () {
      final json = {
        'id': 'b-456',
        'company_name': 'Modern Build',
        'rating_average': 4.5,
        'project_count': 7,
        'is_verified': true,
      };

      final model = ClientSuggestedContractorModel.fromJson(json);

      expect(model.rating, 4.5);
      expect(model.completedProjectsCount, 7);
      expect(model.isVerified, isTrue);
    });
  });
}
