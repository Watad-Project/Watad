import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/work/contractor/datasource/models/contractor_work_overview_model.dart';

void main() {
  group('ContractorWorkOverviewModel.fromJson', () {
    test(
      'parses open projects list, contracts, and groups tasks by project_id',
      () {
        final json = <String, dynamic>{
          'open_projects': [
            {
              'id': 'proj-1',
              'title': 'تأسيس عظم دورين',
              'description': 'بناء عظم بالمواد.',
              'budget': 350000,
              'city': 'المدينة المنورة',
              'district': 'حي العوالي',
              'created_at': '2026-10-19T08:00:00.000Z',
              'owner_name': 'فهد الشمري',
              'offer_count': 2,
              'my_offer_id': null,
              'my_offer_amount': null,
              'my_offer_status': null,
              'is_mine': false,
            },
          ],
          'contracts': [
            {
              'id': 'contract-1',
              'title': 'تشطيب شقة سكنية',
              'status': 'in_progress',
              'owner_name': 'عبدالله الحربي',
              'agreed_amount': 480000,
              'total_paid': 216000,
              'city': 'جدة',
              'created_at': '2026-10-10T08:00:00.000Z',
            },
            {
              'id': 'contract-2',
              'title': 'عزل أسطح وخزانات',
              'status': 'completed',
              'owner_name': 'سعود الدوسري',
              'agreed_amount': 45000,
              'total_paid': 45000,
              'city': 'الرياض',
              'created_at': '2026-09-01T08:00:00.000Z',
            },
          ],
          'tasks': [
            {'id': 't-1', 'project_id': 'contract-1', 'status': 'approved'},
            {'id': 't-2', 'project_id': 'contract-1', 'status': 'proposed'},
          ],
        };

        final model = ContractorWorkOverviewModel.fromJson(json);

        expect(model.contractsCount, 2);
        expect(model.inProgressContractsCount, 1);
        expect(model.completedContractsCount, 1);
        expect(model.opportunitiesCount, 1);
        expect(model.openProjects.single.id, 'proj-1');
        expect(model.openProjects.single.budget, const Money.halalas(35000000));

        final inProgress = model.inProgressContracts.single;
        expect(inProgress.id, 'contract-1');
        expect(inProgress.status, ProjectStatus.inProgress);
        expect(inProgress.approvedTasksCount, 1);
        expect(inProgress.totalTasksCount, 2);
        expect(inProgress.hasTaskWaitingForClient, isTrue);
      },
    );

    test('defaults to empty list and zero count when keys are missing', () {
      final model = ContractorWorkOverviewModel.fromJson(const {});

      expect(model.openProjects, isEmpty);
      expect(model.contracts, isEmpty);
      expect(model.contractsCount, 0);
      expect(model.opportunitiesCount, 0);
    });
  });
}
