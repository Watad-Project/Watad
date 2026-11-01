import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/notification_group.dart';
import 'package:watad/features/settings/shared/datasource/models/settings_overview_model.dart';

void main() {
  test('fromJson maps the profile, the bank details and the switches', () {
    final overview = SettingsOverviewModel.fromJson(const {
      'is_business': true,
      'has_bank_details': false,
      'notifications': [
        {'notification_group': 'messages', 'push_enabled': false},
        {'notification_group': 'projects', 'push_enabled': true},
        {'notification_group': 'tasks', 'push_enabled': true},
        {'notification_group': 'marketplace', 'push_enabled': true},
      ],
    });

    expect(overview.isContractor, isTrue);
    expect(overview.hasBankDetails, isFalse);
    expect(overview.isOn(NotificationGroup.messages), isFalse);
    expect(overview.isOn(NotificationGroup.tasks), isTrue);
  });

  test('a client with no rows yet: every group on', () {
    final overview = SettingsOverviewModel.fromJson(const {
      'is_business': false,
      'has_bank_details': false,
      'notifications': <Object>[],
    });

    expect(overview.isContractor, isFalse);
    expect(NotificationGroup.values.every(overview.isOn), isTrue);
  });
}
