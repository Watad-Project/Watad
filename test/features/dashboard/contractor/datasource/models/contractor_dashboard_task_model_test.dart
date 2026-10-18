import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/features/dashboard/contractor/datasource/models/contractor_dashboard_task_model.dart';

void main() {
  test('fromJson maps v_project_tasks row correctly', () {
    final json = {'id': 'task-1', 'project_id': 'proj-1', 'status': 'approved'};

    final model = ContractorDashboardTaskModel.fromJson(json);

    expect(model.id, 'task-1');
    expect(model.projectId, 'proj-1');
    expect(model.status, TaskStatus.approved);
  });
}
