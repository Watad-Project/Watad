import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/router/routes/admin_marketplace_routes.dart';
import 'package:watad/core/router/routes/admin_navigation_routes.dart';
import 'package:watad/core/router/routes/admin_reports_routes.dart';
import 'package:watad/core/router/routes/admin_review_routes.dart';
import 'package:watad/core/router/routes/admin_users_routes.dart';
import 'package:watad/features/dashboard/admin/presentation/bloc/admin_dashboard_bloc.dart';
import 'package:watad/features/dashboard/admin/presentation/pages/admin_dashboard_page.dart';

/// The dashboard as the admin's «الرئيسية» tab. The injection file passes
/// the bloc in (widgets don't create blocs, APP_ARCHITECTURE.md §10), and
/// the tab closes it when it goes away.
///
/// The numbers are read again:
///
/// - each time the tab shows (the navigation keeps it alive meanwhile);
/// - a moment after someone opens or closes the app ([onlineUserIds]
///   changed), so «متصلون الآن» follows who is on the platform;
/// - every minute while it shows, for what changes without that.
class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({
    required this.bloc,
    this.onlineUserIds,
    this.bell,
    super.key,
  });

  final AdminDashboardBloc bloc;

  /// Who is online now, live (the app's presence). Null in tests that don't
  /// need it.
  final ValueListenable<Set<String>>? onlineUserIds;

  /// The notifications bell, for the top bar.
  final Widget? bell;

  /// How long after a presence change the numbers are read: the app that
  /// just opened saves its presence right after joining the live channel.
  static const Duration presenceSettle = Duration(seconds: 3);

  /// How often the numbers are read while the tab shows.
  static const Duration refreshEvery = Duration(minutes: 1);

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  bool _isVisible = false;
  Timer? _presenceTimer;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    widget.onlineUserIds?.addListener(_onPresenceChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The navigation's IndexedStack says which tab shows.
    final isVisible = Visibility.of(context);
    if (isVisible == _isVisible) return;
    _isVisible = isVisible;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    if (isVisible) {
      _fetch();
      _refreshTimer = Timer.periodic(
        AdminDashboardTab.refreshEvery,
        (_) => _fetch(),
      );
    }
  }

  void _onPresenceChanged() {
    if (!_isVisible) return;
    _presenceTimer?.cancel();
    _presenceTimer = Timer(AdminDashboardTab.presenceSettle, _fetch);
  }

  void _fetch() {
    if (!widget.bloc.isClosed) {
      widget.bloc.add(const AdminDashboardFetched());
    }
  }

  @override
  void dispose() {
    widget.onlineUserIds?.removeListener(_onPresenceChanged);
    _presenceTimer?.cancel();
    _refreshTimer?.cancel();
    widget.bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.bloc,
      child: AdminDashboardPage(
        bell: widget.bell,
        onReviewTap: () => context.goNamed(
          AdminNavigationRoutes.navigationName,
          queryParameters: {'tab': AdminReviewRoutes.reviewName},
        ),
        onMarketTap: () async {
          await context.pushNamed(AdminMarketplaceRoutes.marketplaceName);
          // A removed listing changes the market numbers.
          _fetch();
        },
        onUsersTap: () async {
          await context.pushNamed(AdminUsersRoutes.usersName);
          // A suspension or a new admin changes the numbers.
          _fetch();
        },
        // The «البلاغات» tab; coming back here reads the numbers again.
        onReportsTap: () => context.goNamed(
          AdminNavigationRoutes.navigationName,
          queryParameters: {'tab': AdminReportsRoutes.reportsName},
        ),
      ),
    );
  }
}
