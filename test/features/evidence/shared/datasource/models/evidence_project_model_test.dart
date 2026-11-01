import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/evidence/shared/datasource/models/evidence_project_model.dart';

void main() {
  const row = {
    'id': 'd22a4b79-80a3-4e44-afc2-25e1fedc7e61',
    'title': 'ترميم فيلا في العزيزية',
    'status': 'in_progress',
    'my_role': 'owner',
    'owner_name': 'أمير',
    'taker_company_name': 'مقاولات الخبر',
    'agreed_amount': 450000.5,
    'created_at': '2026-10-02T09:00:00+00:00',
  };

  test('fromJson maps a v_my_projects row of the client', () {
    final project = EvidenceProjectModel.fromJson(row);

    expect(project.id, 'd22a4b79-80a3-4e44-afc2-25e1fedc7e61');
    expect(project.title, 'ترميم فيلا في العزيزية');
    expect(project.status, ProjectStatus.inProgress);
    expect(project.createdAt, DateTime.utc(2026, 10, 2, 9));
    // The client sees the contractor's company.
    expect(project.otherParty, 'مقاولات الخبر');
    expect(project.agreedAmount, const Money.halalas(45000050));
  });

  test('the contractor sees the client', () {
    final project = EvidenceProjectModel.fromJson({
      ...row,
      'my_role': 'taker',
      'agreed_amount': null,
    });

    expect(project.otherParty, 'أمير');
    expect(project.agreedAmount, isNull);
  });
}
