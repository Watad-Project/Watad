import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/utils/app_notification_links.dart';

void main() {
  tearDown(AppNotificationLinks.clear);

  test('a registered type opens its screen, from the data', () {
    AppNotificationLinks.register(
      'task_added',
      (data) => (
        name: 'contractor-job',
        pathParameters: {'id': '${data['project_id']}'},
      ),
    );

    final link = AppNotificationLinks.linkOf({
      'type': 'task_added',
      'project_id': 'p-1',
    });
    expect(link?.name, 'contractor-job');
    expect(link?.pathParameters, {'id': 'p-1'});
  });

  test('a type nothing links, or no type, opens nothing', () {
    expect(AppNotificationLinks.linkOf({'type': 'message'}), isNull);
    expect(AppNotificationLinks.linkOf(const {}), isNull);
  });

  test('a link may decide one notification opens nothing', () {
    AppNotificationLinks.register('deed_rejected', (_) => null);

    expect(AppNotificationLinks.linkOf({'type': 'deed_rejected'}), isNull);
  });
}
