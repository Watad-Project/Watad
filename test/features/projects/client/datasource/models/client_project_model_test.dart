import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/features/projects/client/datasource/models/client_project_model.dart';

void main() {
  test('fromJson maps a v_my_projects row', () {
    final project = ClientProjectModel.fromJson(const {
      'id': '7c9e6679-7425-40de-944b-e07fc1f90ae7',
      'title': 'Kitchen renovation',
      'status': 'in_progress',
      'city': 'Madinah',
      'district': 'Al-Noor',
      'budget': 15000.5,
      'budget_min': 10000.0,
      'budget_max': 20000.0,
      'pending_offer_count': 2,
      'created_at': '2026-10-06T09:30:00+00:00',
      'project_type': 'renovation',
      'deed_status': 'verified',
    });

    expect(project.id, '7c9e6679-7425-40de-944b-e07fc1f90ae7');
    expect(project.title, 'Kitchen renovation');
    expect(project.status, ProjectStatus.inProgress);
    expect(project.city, 'Madinah');
    expect(project.district, 'Al-Noor');
    expect(project.budget?.halalas, 1500050);
    expect(project.budgetMin?.halalas, 1000000);
    expect(project.budgetMax?.halalas, 2000000);
    expect(project.pendingOfferCount, 2);
    expect(project.createdAt.isUtc, isTrue);
    expect(project.projectType, 'renovation');
    expect(project.deedStatus, 'verified');
  });

  test('fromJson handles null values safely', () {
    final project = ClientProjectModel.fromJson(const {
      'id': 'p2',
      'title': 'Repairs',
      'status': 'draft',
      'city': 'Riyadh',
      'district': null,
      'budget': null,
      'budget_min': null,
      'budget_max': null,
      'pending_offer_count': null,
      'created_at': '2026-10-14T08:00:00+00:00',
    });

    expect(project.district, isNull);
    expect(project.budget, isNull);
    expect(project.pendingOfferCount, 0);
  });
}
