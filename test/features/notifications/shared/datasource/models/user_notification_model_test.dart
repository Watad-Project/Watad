import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/notifications/shared/datasource/models/user_notification_model.dart';

void main() {
  test('fromJson maps a v_my_notifications row', () {
    final model = UserNotificationModel.fromJson({
      'id': 'n-1',
      'title': 'تم توثيق الصك',
      'body': 'نُشر مشروعك',
      'data': {'type': 'deed_verified', 'project_id': 'p-1'},
      'read_at': null,
      'created_at': '2026-10-20T08:00:00+00:00',
    });

    expect(model.id, 'n-1');
    expect(model.title, 'تم توثيق الصك');
    expect(model.body, 'نُشر مشروعك');
    expect(model.data, {'type': 'deed_verified', 'project_id': 'p-1'});
    expect(model.isRead, isFalse);
    expect(model.createdAt, DateTime.utc(2026, 10, 20, 8));
  });

  test('fromJson maps a Realtime row, with its extra columns', () {
    final model = UserNotificationModel.fromJson({
      'id': 'n-2',
      'user_id': 'u-1',
      'title': 'Hello',
      'body': 'World',
      'data': <String, dynamic>{},
      'read_at': '2026-10-20T09:00:00+00:00',
      'created_at': '2026-10-20T08:30:00+00:00',
      'push_status': 'in_app',
      'pushed_at': '2026-10-20T08:30:01+00:00',
      'push_error': null,
    });

    expect(model.data, isEmpty);
    expect(model.isRead, isTrue);
    expect(model.readAt, DateTime.utc(2026, 10, 20, 9));
  });
}
