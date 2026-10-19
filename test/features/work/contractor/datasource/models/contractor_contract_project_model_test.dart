import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/work/contractor/datasource/models/contractor_contract_project_model.dart';

void main() {
  group('ContractorContractProjectModel.fromJson', () {
    test('parses contract fields and computes task progress excluding rejected tasks', () {
      final json = <String, dynamic>{
        'id': 'contract-1',
        'title': 'بناء فيلا سكنية دورين',
        'description': 'تشطيب كامل تسليم مفتاح.',
        'status': 'in_progress',
        'owner_name': 'عبدالله الحربي',
        'budget': 500000,
        'agreed_amount': 480000,
        'total_paid': 216000,
        'city': 'المدينة المنورة',
        'district': 'حي العوالي',
        'created_at': '2026-10-10T09:00:00.000Z',
        'completed_at': null,
        'tasks': [
          {'id': 't-1', 'project_id': 'contract-1', 'status': 'approved'},
          {'id': 't-2', 'project_id': 'contract-1', 'status': 'approved'},
          {'id': 't-3', 'project_id': 'contract-1', 'status': 'approved'},
          {'id': 't-4', 'project_id': 'contract-1', 'status': 'done'},
          {'id': 't-5', 'project_id': 'contract-1', 'status': 'accepted'},
          {'id': 't-6', 'project_id': 'contract-1', 'status': 'rejected'},
        ],
      };

      final model = ContractorContractProjectModel.fromJson(json);

      expect(model.id, 'contract-1');
      expect(model.title, 'بناء فيلا سكنية دورين');
      expect(model.status, ProjectStatus.inProgress);
      expect(model.isInProgress, isTrue);
      expect(model.isCompleted, isFalse);
      expect(model.ownerName, 'عبدالله الحربي');
      expect(model.budget, const Money.halalas(50000000));
      expect(model.agreedAmount, const Money.halalas(48000000));
      expect(model.contractMoney, const Money.halalas(48000000));
      expect(model.totalPaid, const Money.halalas(21600000));
      expect(model.approvedTasksCount, 3);
      expect(model.totalTasksCount, 5);
      expect(model.hasTaskWaitingForClient, isTrue);
      expect(model.progress, closeTo(0.6, 0.0001));
      expect(model.progressPercent, 60);
    });

    test(
      'parses completed contract and defaults progress to 100% when no tasks',
      () {
        final json = <String, dynamic>{
          'id': 'contract-2',
          'title': 'ترميم واجهة خارجية',
          'status': 'completed',
          'owner_name': 'خالد العنزي',
          'agreed_amount': 95000,
          'total_paid': 95000,
          'city': 'الرياض',
          'created_at': '2026-08-01T00:00:00.000Z',
          'completed_at': '2026-10-01T12:00:00.000Z',
          'tasks': const <Map<String, dynamic>>[],
        };

        final model = ContractorContractProjectModel.fromJson(json);

        expect(model.status, ProjectStatus.completed);
        expect(model.isCompleted, isTrue);
        expect(model.hasTaskWaitingForClient, isFalse);
        expect(model.progress, 1.0);
        expect(model.progressPercent, 100);
        expect(model.completedAt, DateTime.utc(2026, 10, 1, 12));
      },
    );
  });
}
