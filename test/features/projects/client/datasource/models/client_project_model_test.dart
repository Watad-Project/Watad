import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/features/projects/client/datasource/models/client_project_model.dart';

void main() {
  test('fromJson parses a realistic v_my_projects row', () {
    final project = ClientProjectModel.fromJson({
      'id': 'p1',
      'title': 'Kitchen renovation',
      'status': 'in_progress',
      'city': 'Madinah',
      'district': null,
      'budget': 15000.5,
      'pending_offer_count': 2,
      'created_at': '2026-10-06T09:30:00+00:00',
    });

    expect(project.id, 'p1');
    expect(project.title, 'Kitchen renovation');
    expect(project.status, ProjectStatus.inProgress);
    expect(project.city, 'Madinah');
    expect(project.district, isNull);
    expect(project.budget?.halalas, 1500050);
    expect(project.pendingOfferCount, 2);
    expect(project.createdAt.isUtc, isTrue);
  });
}
