import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/features/dashboard/contractor/datasource/models/contractor_dashboard_project_model.dart';

void main() {
  test('fromJson maps v_my_projects row correctly with owner_name', () {
    final json = {
      'id': 'proj-123',
      'title': 'ترميم فيلا سكنية',
      'owner_name': 'أحمد العتيبي',
      'status': 'in_progress',
      'approved_tasks_count': 3,
      'total_tasks_count': 5,
      'created_at': '2026-10-10T12:00:00.000Z',
      'budget': 50000.0,
      'city': 'المدينة المنورة',
    };

    final model = ContractorDashboardProjectModel.fromJson(json);

    expect(model.id, 'proj-123');
    expect(model.title, 'ترميم فيلا سكنية');
    expect(model.ownerName, 'أحمد العتيبي');
    expect(model.clientName, 'أحمد العتيبي');
    expect(model.status, ProjectStatus.inProgress);
    expect(model.approvedTasksCount, 3);
    expect(model.totalTasksCount, 5);
    expect(model.progress, 0.6);
    expect(model.budget?.halalas, 5000000);
    expect(model.city, 'المدينة المنورة');
  });

  test('handles zero tasks and null budget gracefully', () {
    final json = {
      'id': 'proj-456',
      'title': 'بناء مستودع',
      'owner_name': null,
      'status': 'in_progress',
      'approved_tasks_count': 0,
      'total_tasks_count': 0,
      'created_at': '2026-10-10T12:00:00.000Z',
      'budget': null,
      'city': null,
    };

    final model = ContractorDashboardProjectModel.fromJson(json);

    expect(model.ownerName, isEmpty);
    expect(model.clientName, isEmpty);
    expect(model.progress, 0.0);
    expect(model.budget, isNull);
  });

  test('handles completely empty or null fields gracefully', () {
    final model = ContractorDashboardProjectModel.fromJson({});

    expect(model.id, isEmpty);
    expect(model.title, isEmpty);
    expect(model.ownerName, isEmpty);
    expect(model.status, ProjectStatus.inProgress);
    expect(model.approvedTasksCount, 0);
    expect(model.totalTasksCount, 0);
    expect(model.progress, 0.0);
    expect(model.budget, isNull);
    expect(model.city, isNull);
  });
}
