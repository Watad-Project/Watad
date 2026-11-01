import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/enums/task_update_decision.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/evidence/shared/datasource/models/project_evidence_model.dart';

/// The body of the project-evidence Edge Function, trimmed to what the app
/// reads.
Map<String, dynamic> _body() => {
  'export_id': '6f1c2d3e-4b5a-4c6d-8e7f-0a1b2c3d4e5f',
  'exported_at': '2026-11-01T08:30:00.000Z',
  'evidence': {
    'format': 'watad-project-evidence/1',
    'exported_by': {'user_id': 'u1', 'role': 'taker'},
    'project': {
      'id': 'd22a4b79-80a3-4e44-afc2-25e1fedc7e61',
      'title': 'ترميم فيلا',
      'description': 'ترميم الواجهة',
      'status': 'completed',
      'city': 'المدينة المنورة',
      'district': 'العزيزية',
      'created_at': '2026-10-02T09:00:00+00:00',
      'started_at': '2026-10-05T10:00:00+00:00',
      'completed_at': '2026-10-30T12:00:00+00:00',
    },
    'client': {'id': 'o1', 'name': 'أمير'},
    'contractor': {
      'id': 't1',
      'company_name': 'مقاولات الخبر',
      'cr_number': '1010123456',
    },
    'agreed_price': 450000,
    'currency': 'SAR',
    'tasks': [
      {
        'id': 'k1',
        'title': 'هدم الواجهة',
        'description': 'إزالة التكسيات',
        'status': 'approved',
        'amount': 50000.25,
        'start_date': '2026-10-06',
        'finish_date': '2026-10-12',
        'last_update': {'decision': 'accepted'},
      },
      {
        'id': 'k2',
        'title': 'السباكة',
        'description': 'تجديد',
        'status': 'some_new_status',
        'amount': null,
        'start_date': null,
        'finish_date': null,
        'last_update': null,
      },
    ],
    'payments': [
      {
        'id': 'p1',
        'stage_number': 1,
        'amount': 50000,
        'status': 'paid',
        'method': 'bank_transfer',
        'paid_at': '2026-10-14T11:00:00+00:00',
        'bank_transfer': {'status': 'confirmed'},
      },
    ],
    'sync': {'status': 'synced', 'synced_at': '2026-10-14T11:02:00+00:00'},
  },
  'comparison': {
    'matches': false,
    'fields': [
      {
        'field': 'agreedPrice',
        'database': 450000,
        'chain': 450000,
        'matches': true,
      },
      {
        'field': 'contractorEmail',
        'database': 'a@b.sa',
        'chain': null,
        'matches': false,
      },
    ],
    'milestones': [
      {
        'index': 0,
        'database': {'description': 'إزالة التكسيات', 'status': 'approved'},
        'chain': {'description': 'إزالة التكسيات', 'status': 'done'},
        'matches': false,
      },
      {
        'index': 1,
        'database': {'description': 'تجديد', 'status': 'proposed'},
        'chain': null,
        'matches': false,
      },
    ],
    'payments': [
      {
        'id': 'p1',
        'database': {'id': 'p1', 'amount': 51000, 'date': '2026-10-14'},
        'chain': {'id': 'p1', 'amount': 50000, 'date': '2026-10-14'},
        'matches': false,
      },
      {
        'id': 'p9',
        'database': null,
        'chain': {'id': 'p9', 'amount': 10, 'date': '2026-10-20'},
        'matches': false,
      },
    ],
  },
  'fingerprint': 'ab' * 32,
  'signature': 'c2lnbmF0dXJl',
  'key_id': 'evidence-2026-10',
  'public_key': 'cHVibGlj',
};

void main() {
  test('fromJson maps the function body', () {
    final evidence = ProjectEvidenceModel.fromJson(_body());

    expect(evidence.exportId, '6f1c2d3e-4b5a-4c6d-8e7f-0a1b2c3d4e5f');
    expect(evidence.exportedAt, DateTime.utc(2026, 11, 1, 8, 30));
    expect(evidence.exportedByRole, 'taker');
    expect(evidence.project.status, ProjectStatus.completed);
    expect(evidence.project.district, 'العزيزية');
    expect(evidence.project.startedAt, DateTime.utc(2026, 10, 5, 10));
    expect(evidence.project.completedAt, DateTime.utc(2026, 10, 30, 12));
    expect(evidence.clientName, 'أمير');
    expect(evidence.contractorCompany, 'مقاولات الخبر');
    expect(evidence.contractorCrNumber, '1010123456');
    expect(evidence.agreedPrice, const Money.halalas(45000000));
    expect(evidence.lastSyncedAt, DateTime.utc(2026, 10, 14, 11, 2));
    expect(evidence.fingerprint, 'ab' * 32);
    expect(evidence.keyId, 'evidence-2026-10');
    expect(evidence.publicKey, 'cHVibGlj');
    expect(evidence.matches, isFalse);
  });

  test('tasks and payments keep their details; unknown values stay empty', () {
    final evidence = ProjectEvidenceModel.fromJson(_body());

    final first = evidence.tasks.first;
    expect(first.status, TaskStatus.approved);
    expect(first.amount, const Money.halalas(5000025));
    expect(first.startDate, DateTime.utc(2026, 10, 6));
    expect(first.lastDecision, TaskUpdateDecision.accepted);
    // A status the app doesn't know yet doesn't break the export.
    expect(evidence.tasks.last.status, isNull);
    expect(evidence.tasks.last.lastDecision, isNull);

    final payment = evidence.payments.single;
    expect(payment.status, PaymentStatus.paid);
    expect(payment.method, 'bank_transfer');
    expect(payment.bankTransferStatus, 'confirmed');
  });

  test('the chain rows show the chain copy, or the database when missing', () {
    final evidence = ProjectEvidenceModel.fromJson(_body());

    expect(evidence.chainFields.first.chain, '450000');
    expect(evidence.chainFields.last.chain, isNull);
    expect(evidence.chainFields.last.matches, isFalse);

    expect(evidence.chainMilestones.first.status, 'done');
    expect(evidence.chainMilestones.last.status, 'proposed');

    // The chain still holds the original amount.
    final changed = evidence.chainPayments.first;
    expect(changed.amount, const Money.halalas(5000000));
    expect(changed.isOnChain && changed.isInDatabase, isTrue);
    final extra = evidence.chainPayments.last;
    expect(extra.isInDatabase, isFalse);
  });
}
