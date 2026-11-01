import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/notification_group.dart';

void main() {
  test('round-trips every notification_group value', () {
    for (final group in NotificationGroup.values) {
      expect(NotificationGroup.fromJson(group.toJson()), group);
    }
    expect(NotificationGroup.values.map((g) => g.value), [
      'messages',
      'projects',
      'tasks',
      'marketplace',
    ]);
  });

  test('throws on an unknown notification_group value', () {
    expect(() => NotificationGroup.fromJson('unknown'), throwsStateError);
  });
}
