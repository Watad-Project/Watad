import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/notifications/shared/datasource/models/notification_tap_model.dart';

void main() {
  test('fromJson maps a tapped push: its notification and target', () {
    final tap = NotificationTapModel.fromJson({
      'type': 'task_accepted',
      'task_id': 't-1',
      'notification_id': 'n-1',
      'route': 'client-projects',
      'params': {'id': 'p-1'},
    });

    expect(tap.notificationId, 'n-1');
    expect(tap.target?.route, 'client-projects');
    expect(tap.target?.params, {'id': 'p-1'});
  });

  test('fromJson accepts a push that leads nowhere, or without an id', () {
    final tap = NotificationTapModel.fromJson(const {'type': 'message'});

    expect(tap.notificationId, isNull);
    expect(tap.target, isNull);
  });
}
