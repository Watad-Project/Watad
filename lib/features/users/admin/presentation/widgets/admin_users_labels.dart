import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/users/admin/domain/entities/admin_user.dart';

/// How a user's kind, business verification, presence and dates read, in
/// the list and on their page.
abstract final class AdminUsersLabels {
  /// «مشرف», «مقاول» or «عميل»: one of them, never two.
  static String kind(BuildContext context, AdminUser user) => context.tr(
    user.isAdmin
        ? 'users.kind_admin'
        : user.isContractor
        ? 'users.kind_contractor'
        : 'users.kind_client',
  );

  static String verificationKey(VerificationStatus status) => switch (status) {
    VerificationStatus.unverified => 'users.verification_unverified',
    VerificationStatus.pending => 'users.verification_pending',
    VerificationStatus.verified => 'users.verification_verified',
    VerificationStatus.rejected => 'users.verification_rejected',
    VerificationStatus.suspended => 'users.verification_suspended',
  };

  static AppTone verificationTone(VerificationStatus status) =>
      switch (status) {
        VerificationStatus.verified => AppTone.success,
        VerificationStatus.pending => AppTone.attention,
        VerificationStatus.rejected ||
        VerificationStatus.suspended => AppTone.danger,
        VerificationStatus.unverified => AppTone.neutral,
      };

  /// «متصل الآن», «آخر ظهور منذ ساعة», or «لم يظهر بعد».
  static String presence(BuildContext context, AdminUser user, DateTime now) {
    if (user.isOnline) return context.tr('users.online_now');
    final seen = user.lastSeenAt;
    if (seen == null) return context.tr('users.never_seen');
    return context.tr('users.last_seen', args: [_ago(context, seen, now)]);
  }

  /// «عضو منذ ٢٢ أكتوبر ٢٠٢٦».
  static String memberSince(BuildContext context, AdminUser user) =>
      context.tr('users.member_since', args: [date(context, user.memberSince)]);

  /// «٢٢ أكتوبر ٢٠٢٦», on the phone's calendar, in the app's language.
  static String date(BuildContext context, DateTime time) {
    final locale = context.isArabic
        ? AppLocalization.arabic.languageCode
        : AppLocalization.english.languageCode;
    return DateFormat.yMMMd(locale).format(time.toLocal());
  }

  static String _ago(BuildContext context, DateTime time, DateTime now) {
    final elapsed = now.difference(time);
    String plural(String key, int count) =>
        context.plural(key, count, args: [context.formatNumber(count)]);
    if (elapsed.inMinutes < 1) return context.tr('users.just_now');
    if (elapsed.inHours < 1) {
      return plural('users.minutes_ago', elapsed.inMinutes);
    }
    if (elapsed.inDays < 1) return plural('users.hours_ago', elapsed.inHours);
    return plural('users.days_ago', elapsed.inDays);
  }
}
