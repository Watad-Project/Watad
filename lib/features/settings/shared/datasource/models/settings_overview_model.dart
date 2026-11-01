import 'package:watad/core/enums/notification_group.dart';
import 'package:watad/features/settings/shared/domain/entities/settings_overview.dart';

class SettingsOverviewModel extends SettingsOverview {
  const SettingsOverviewModel({
    required super.isContractor,
    required super.hasBankDetails,
    required super.notifications,
  });

  /// Maps what SettingsRemoteDataSourceImpl reads: `is_business` from
  /// `v_my_profile`, `has_bank_details` (a `v_contractor_bank_details` row
  /// of mine exists), and `notifications`, the `v_my_notification_preferences`
  /// rows.
  factory SettingsOverviewModel.fromJson(Map<String, dynamic> json) {
    final rows = json['notifications'] as List<dynamic>? ?? const [];
    return SettingsOverviewModel(
      isContractor: json['is_business'] as bool? ?? false,
      hasBankDetails: json['has_bank_details'] as bool? ?? false,
      notifications: {
        for (final row in rows.cast<Map<String, dynamic>>())
          NotificationGroup.fromJson(row['notification_group'] as String):
              row['push_enabled'] as bool? ?? true,
      },
    );
  }
}
