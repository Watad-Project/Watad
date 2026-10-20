import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/notifications/shared/datasource/models/notification_tap_model.dart';

void main() {
  test('fromJson maps a tapped push: its notification and its data', () {
    final tap = NotificationTapModel.fromJson({
      'type': 'task_accepted',
      'project_id': 'p-1',
      'task_id': 't-1',
      'notification_id': 'n-1',
    });

    expect(tap.notificationId, 'n-1');
    expect(tap.data, {
      'type': 'task_accepted',
      'project_id': 'p-1',
      'task_id': 't-1',
    });
  });

  test('fromJson accepts a push sent outside the app\'s notifications', () {
    final tap = NotificationTapModel.fromJson(const {'type': 'campaign'});

    expect(tap.notificationId, isNull);
    expect(tap.data, {'type': 'campaign'});
  });
}
