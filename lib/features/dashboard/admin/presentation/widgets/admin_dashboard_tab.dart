import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/router/routes/admin_navigation_routes.dart';
import 'package:watad/core/router/routes/admin_reports_routes.dart';
import 'package:watad/core/router/routes/admin_review_routes.dart';
import 'package:watad/features/dashboard/admin/presentation/bloc/admin_dashboard_bloc.dart';
import 'package:watad/features/dashboard/admin/presentation/pages/admin_dashboard_page.dart';

/// The dashboard as the admin's «الرئيسية» tab. The injection file passes
/// the bloc in (widgets don't create blocs, APP_ARCHITECTURE.md §10), and
/// the tab closes it when it goes away.
///
/// The navigation keeps a tab alive while another one shows, so the numbers
/// are read again each time this tab shows.
class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({required this.bloc, this.bell, super.key});

  final AdminDashboardBloc bloc;

  /// The notifications bell, for the top bar.
  final Widget? bell;

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  bool _wasVisible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The navigation's IndexedStack says which tab shows.
    final isVisible = Visibility.of(context);
    if (isVisible && !_wasVisible) {
      widget.bloc.add(const AdminDashboardFetched());
    }
    _wasVisible = isVisible;
  }

  @override
  void dispose() {
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
        onReportsTap: () async {
          await context.pushNamed(AdminReportsRoutes.reportsName);
          // What the admin did there changes the numbers.
          widget.bloc.add(const AdminDashboardFetched());
        },
      ),
    );
  }
}
