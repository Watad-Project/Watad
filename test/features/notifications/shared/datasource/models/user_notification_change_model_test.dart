import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/notifications/shared/datasource/models/user_notification_change_model.dart';

void main() {
  final record = {
    'id': 'n-1',
    'user_id': 'u-1',
    'title': 'تم قبول المهمة',
    'body': 'صب القواعد',
    'data': {'type': 'task_accepted', 'task_id': 't-1'},
    'read_at': null,
    'created_at': '2026-10-20T08:00:00+00:00',
    'push_status': 'pending',
    'pushed_at': null,
    'push_error': null,
  };

  test('fromJson maps a new notification from Realtime', () {
    final change = UserNotificationChangeModel.fromJson({
      'event': 'INSERT',
      'record': record,
    });

    expect(change.isNew, isTrue);
    expect(change.notification.id, 'n-1');
    expect(change.notification.title, 'تم قبول المهمة');
    expect(change.notification.isRead, isFalse);
  });

  test('fromJson maps one read as a change, not a new one', () {
    final change = UserNotificationChangeModel.fromJson({
      'event': 'UPDATE',
      'record': {...record, 'read_at': '2026-10-20T09:00:00+00:00'},
    });

    expect(change.isNew, isFalse);
    expect(change.notification.isRead, isTrue);
  });
}
