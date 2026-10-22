import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/features/reports/admin/presentation/bloc/admin_reports_bloc.dart';
import 'package:watad/features/reports/admin/presentation/pages/admin_reports_page.dart';

/// The reports as the admin's «البلاغات» tab. The injection file passes the
/// bloc in (widgets don't create blocs, APP_ARCHITECTURE.md §10), and the tab
/// closes it when it goes away.
class AdminReportsTab extends StatefulWidget {
  const AdminReportsTab({required this.bloc, super.key});

  final AdminReportsBloc bloc;

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  @override
  void dispose() {
    widget.bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocProvider.value(value: widget.bloc, child: const AdminReportsPage());
}
