import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/notifications/shared/datasource/models/notification_target_model.dart';

void main() {
  test('fromJson maps a route and its parameters', () {
    final target = NotificationTargetModel.fromJson({
      'route': 'admin-review-details',
      'params': {'kind': 'deed', 'id': 'p-1'},
    });

    expect(target.route, 'admin-review-details');
    expect(target.params, {'kind': 'deed', 'id': 'p-1'});
  });

  test('parameters that aren\'t strings are written as strings', () {
    final target = NotificationTargetModel.fromJson({
      'route': 'client-projects',
      'params': {'page': 2, 'missing': null},
    });

    expect(target.params, {'page': '2'});
  });

  test('routeOf is null for data that leads nowhere', () {
    expect(NotificationTargetModel.routeOf(const <String, dynamic>{}), isNull);
    expect(NotificationTargetModel.routeOf({'route': 7}), isNull);
    expect(NotificationTargetModel.routeOf(null), isNull);
    expect(
      NotificationTargetModel.routeOf({'route': 'client-projects'})?.params,
      isEmpty,
    );
  });
}
