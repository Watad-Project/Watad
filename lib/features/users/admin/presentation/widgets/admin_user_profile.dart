import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_avatar.dart';
import 'package:watad/core/components/display/app_key_value_list.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/components/display/app_verified_name.dart';
import 'package:watad/core/components/layout/app_section_header.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/users/admin/domain/entities/admin_user.dart';
import 'package:watad/features/users/admin/presentation/widgets/admin_users_labels.dart';

/// Everything about one user: photo, name, kind (client, contractor or
/// admin), member since and last seen; how to reach them and who they are
/// (email, phone, ID number, account id); their business and its
/// verification (a pending license opens «التوثيق»); and their activity as
/// a client or as a contractor.
class AdminUserProfile extends StatelessWidget {
  const AdminUserProfile({
    required this.user,
    required this.now,
    this.onOpenReview,
    this.onCopied,
    super.key,
  });

  final AdminUser user;
  final DateTime now;

  /// After a value was copied, e.g. to say so.
  final ValueChanged<String>? onCopied;

  /// Opens the «التوثيق» tab, for a business whose license waits there.
  final VoidCallback? onOpenReview;

  static const EdgeInsetsGeometry _sectionPadding = EdgeInsetsDirectional.only(
    top: AppSpacing.lg,
    bottom: AppSpacing.xs,
  );

  @override
  Widget build(BuildContext context) {
    String count(int value) => context.formatNumber(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            AppAvatar(url: user.avatarUrl, size: 72, semanticLabel: user.name),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: AppTextStyles.h2),
                  Text(
                    AdminUsersLabels.kind(context, user),
                    style: AppTextStyles.caption,
                  ),
                  if (user.isSuspended || user.isDeleted || user.isMe) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      children: [
                        if (user.isSuspended)
                          AppStatusBadge(
                            label: context.tr('users.suspended'),
                            tone: AppTone.danger,
                          ),
                        if (user.isDeleted)
                          AppStatusBadge(label: context.tr('users.closed')),
                        if (user.isMe)
                          AppStatusBadge(
                            label: context.tr('users.you'),
                            tone: AppTone.attention,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppKeyValueList(
          rows: [
            AppKeyValueRow(
              label: context.tr('users.member_since_label'),
              value: AdminUsersLabels.date(context, user.memberSince),
            ),
            AppKeyValueRow(
              label: context.tr('users.presence_label'),
              value: AdminUsersLabels.presence(context, user, now),
            ),
          ],
        ),
        AppSectionHeader(
          title: context.tr('users.account'),
          padding: _sectionPadding,
        ),
        _Account(user: user, onCopied: onCopied),
        if (user.isBusiness) ...[
          AppSectionHeader(
            title: context.tr('users.business'),
            padding: _sectionPadding,
          ),
          _Business(user: user, onOpenReview: onOpenReview),
        ],
        AppSectionHeader(
          title: context.tr('users.activity'),
          padding: _sectionPadding,
        ),
        AppKeyValueList(
          rows: [
            // Their projects as what they are: a contractor or a client.
            if (user.isContractor)
              AppKeyValueRow(
                label: context.tr('users.contractor_projects'),
                value: count(user.contractorProjectCount),
              )
            else
              AppKeyValueRow(
                label: context.tr('users.client_projects'),
                value: count(user.clientProjectCount),
              ),
            AppKeyValueRow(
              label: context.tr('users.listings'),
              value: count(user.listingCount),
            ),
            AppKeyValueRow(
              label: context.tr('users.open_reports'),
              value: count(user.openReportCount),
            ),
          ],
        ),
      ],
    );
  }
}

/// Email, phone, ID number and account id, each with «نسخ».
class _Account extends StatelessWidget {
  const _Account({required this.user, required this.onCopied});

  final AdminUser user;
  final ValueChanged<String>? onCopied;

  @override
  Widget build(BuildContext context) {
    final missing = context.tr('users.not_given');
    AppKeyValueRow row(String key, String? value, {bool isMonospace = false}) =>
        AppKeyValueRow(
          label: context.tr(key),
          value: value ?? missing,
          isMonospace: isMonospace && value != null,
          isCopyable: value != null,
        );
    return AppKeyValueList(
      onCopied: onCopied,
      rows: [
        row('users.email', user.email, isMonospace: true),
        row('users.phone', user.phone, isMonospace: true),
        row('users.national_id', user.nationalId, isMonospace: true),
        row('users.account_id', user.id, isMonospace: true),
      ],
    );
  }
}

class _Business extends StatelessWidget {
  const _Business({required this.user, required this.onOpenReview});

  final AdminUser user;
  final VoidCallback? onOpenReview;

  @override
  Widget build(BuildContext context) {
    final status = user.verificationStatus;
    final company = user.companyName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (company != null) ...[
          user.isVerifiedBusiness
              ? AppVerifiedName(name: company, style: AppTextStyles.label)
              : Text(company, style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.xs),
        ],
        AppKeyValueList(
          rows: [
            if (user.specialty case final specialty?)
              AppKeyValueRow(
                label: context.tr('users.specialty'),
                value: specialty,
              ),
            if (user.businessCity case final city?)
              AppKeyValueRow(label: context.tr('users.city'), value: city),
          ],
        ),
        if (status != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppStatusBadge(
              label: context.tr(AdminUsersLabels.verificationKey(status)),
              tone: AdminUsersLabels.verificationTone(status),
            ),
          ),
        ],
        if (status == VerificationStatus.pending && onOpenReview != null) ...[
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: context.tr('users.open_review'),
            variant: AppButtonVariant.secondary,
            onPressed: onOpenReview,
          ),
        ],
      ],
    );
  }
}
