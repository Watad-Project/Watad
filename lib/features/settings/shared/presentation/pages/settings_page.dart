import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_confirm_dialog.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/components/layout/app_menu_row.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/router/routes/auth_routes.dart';
import 'package:watad/core/router/routes/contractor_payments_routes.dart';
import 'package:watad/core/router/routes/evidence_routes.dart';
import 'package:watad/core/router/routes/settings_routes.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/settings/shared/domain/entities/settings_notification_change.dart';
import 'package:watad/features/settings/shared/domain/entities/settings_overview.dart';
import 'package:watad/features/settings/shared/presentation/bloc/settings_bloc.dart';
import 'package:watad/features/settings/shared/presentation/widgets/settings_notifications_section.dart';
import 'package:watad/features/settings/shared/presentation/widgets/settings_section.dart';

/// «الإعدادات»: language, the contractor's bank details, the project
/// export, the notification switches, signing out and closing the account.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with WidgetsBindingObserver {
  /// The phone itself blocks Watad's notifications.
  bool _pushBlocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPhoneSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the phone's settings.
    if (state == AppLifecycleState.resumed) _checkPhoneSettings();
  }

  Future<void> _checkPhoneSettings() async {
    if (kIsWeb) return;
    bool blocked;
    try {
      final status = await Permission.notification.status;
      blocked = !(status.isGranted || status.isLimited || status.isProvisional);
    } on Object {
      // No permission plugin (tests, an unsupported platform): say nothing.
      blocked = false;
    }
    if (mounted && blocked != _pushBlocked) {
      setState(() => _pushBlocked = blocked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsBloc, SettingsState>(
      listenWhen: (previous, current) =>
          current.isSignedOut != previous.isSignedOut ||
          (current.notice != null && current.notice != previous.notice),
      listener: (context, state) {
        if (state.isSignedOut) {
          context.goNamed(AuthRoutes.loginName);
          return;
        }
        context.showErrorSnackBar(context.tr(state.notice!.key));
      },
      builder: (context, state) => Scaffold(
        appBar: AppTopBar(
          title: context.tr('settings.title'),
          onBack: () => context.pop(),
        ),
        body: _body(context, state),
      ),
    );
  }

  Widget _body(BuildContext context, SettingsState state) {
    final bloc = context.read<SettingsBloc>();
    final overview = state.overview;
    if (overview == null) {
      if (state.status == SettingsStatus.failure) {
        return AppErrorView(
          message: context.tr(state.failure!.messageKey),
          onRetry: () => bloc.add(const SettingsFetched()),
        );
      }
      return const AppLoadingIndicator();
    }
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        _General(overview: overview),
        if (_pushBlocked) ...[
          const SizedBox(height: AppSpacing.lg),
          AppStatusCard(
            key: const Key('settings_push_blocked'),
            tone: AppTone.attention,
            title: context.tr('settings.push_blocked_title'),
            subtitle: context.tr('settings.push_blocked_message'),
            action: AppButton(
              label: context.tr('settings.open_phone_settings'),
              variant: AppButtonVariant.secondary,
              onPressed: openAppSettings,
            ),
          ),
        ],
        SettingsNotificationsSection(
          overview: overview,
          onChanged: (group, enabled) => bloc.add(
            SettingsNotificationToggled(
              SettingsNotificationChange(group, enabled: enabled),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          key: const Key('settings_sign_out'),
          label: context.tr('settings.sign_out'),
          variant: AppButtonVariant.secondary,
          isLoading: state.busyAction == SettingsAction.signOut,
          onPressed: state.busyAction == null
              ? () => bloc.add(const SettingsSignOutRequested())
              : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          key: const Key('settings_delete_account'),
          label: context.tr('settings.delete_account'),
          variant: AppButtonVariant.link,
          isLoading: state.busyAction == SettingsAction.delete,
          onPressed: state.busyAction == null
              ? () => _confirmDelete(context, bloc)
              : null,
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, SettingsBloc bloc) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: context.tr('settings.delete_title'),
      message: context.tr('settings.delete_message'),
      confirmLabel: context.tr('settings.delete_confirm'),
    );
    if (confirmed == null) return;
    bloc.add(const SettingsAccountDeleteRequested());
  }
}

/// Language, the contractor's bank details, the export, and the static
/// pages.
class _General extends StatelessWidget {
  const _General({required this.overview});

  final SettingsOverview overview;

  void _openInfo(BuildContext context, String page) => context.pushNamed(
    SettingsRoutes.settingsInfoName,
    pathParameters: {'page': page},
  );

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SettingsBloc>();
    return SettingsSection(
      title: context.tr('settings.general'),
      rows: [
        AppMenuRow(
          key: const Key('settings_language'),
          icon: Icons.language_rounded,
          label: context.tr('settings.language'),
          subtitle: context.tr(
            context.isArabic ? 'settings.arabic' : 'settings.english',
          ),
          onTap: () => context.toggleLanguage(),
        ),
        if (overview.isContractor)
          AppMenuRow(
            key: const Key('settings_bank_details'),
            icon: Icons.account_balance_outlined,
            label: context.tr('settings.bank_details'),
            tag: overview.hasBankDetails
                ? null
                : context.tr('settings.required'),
            tagTone: AppTone.attention,
            onTap: () async {
              await context.pushNamed(ContractorPaymentsRoutes.bankDetailsName);
              bloc.add(const SettingsFetched());
            },
          ),
        AppMenuRow(
          key: const Key('settings_export_project'),
          icon: Icons.picture_as_pdf_outlined,
          label: context.tr('settings.export_project'),
          // My contracted projects, to export one (GRA-72).
          onTap: () => context.pushNamed(EvidenceRoutes.evidenceProjectsName),
        ),
        AppMenuRow(
          icon: Icons.info_outline_rounded,
          label: context.tr('settings.about'),
          onTap: () => _openInfo(context, 'about'),
        ),
        AppMenuRow(
          icon: Icons.description_outlined,
          label: context.tr('settings.terms'),
          onTap: () => _openInfo(context, 'terms'),
        ),
        AppMenuRow(
          icon: Icons.privacy_tip_outlined,
          label: context.tr('settings.privacy'),
          onTap: () => _openInfo(context, 'privacy'),
        ),
      ],
    );
  }
}
