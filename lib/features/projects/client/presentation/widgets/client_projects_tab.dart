import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_projects_bloc.dart';
import 'package:watad/features/projects/client/presentation/pages/client_projects_page.dart';

/// The projects as the client's «مشاريعي» tab. The injection file passes the
/// bloc in (widgets don't create blocs, APP_ARCHITECTURE.md §10), and the tab
/// closes it when it goes away.
class ClientProjectsTab extends StatefulWidget {
  const ClientProjectsTab({required this.bloc, super.key});

  final ClientProjectsBloc bloc;

  @override
  State<ClientProjectsTab> createState() => _ClientProjectsTabState();
}

class _ClientProjectsTabState extends State<ClientProjectsTab> {
  @override
  void dispose() {
    widget.bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocProvider.value(value: widget.bloc, child: const ClientProjectsPage());
}
