import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/features/reports/admin/presentation/bloc/admin_reports_bloc.dart';
import 'package:watad/features/reports/admin/presentation/pages/admin_reports_page.dart';

/// The tickets as the admin's «البلاغات» tab. The injection file passes the
/// bloc in (widgets don't create blocs, APP_ARCHITECTURE.md §10), and the tab
/// closes it when it goes away.
///
/// The navigation keeps a tab alive while another one shows, so the tickets
/// are read again each time this tab shows.
class AdminReportsTab extends StatefulWidget {
  const AdminReportsTab({required this.bloc, this.bell, super.key});

  final AdminReportsBloc bloc;

  /// The notifications bell, for the top bar.
  final Widget? bell;

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  bool _wasVisible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The navigation's IndexedStack says which tab shows.
    final isVisible = Visibility.of(context);
    if (isVisible && !_wasVisible) {
      widget.bloc.add(const AdminReportsFetched());
    }
    _wasVisible = isVisible;
  }

  @override
  void dispose() {
    widget.bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: widget.bloc,
    child: AdminReportsPage(isTab: true, bell: widget.bell),
  );
}
