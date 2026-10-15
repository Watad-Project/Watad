import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_projects_bloc.dart';
import 'package:watad/features/projects/client/presentation/pages/client_projects_page.dart';

/// Wraps [ClientProjectsPage] for the client bottom navigation tab.
class ClientProjectsTab extends StatefulWidget {
  const ClientProjectsTab({required this.bloc, super.key});

  final ClientProjectsBloc bloc;

  @override
  State<ClientProjectsTab> createState() => _ClientProjectsTabState();
}

class _ClientProjectsTabState extends State<ClientProjectsTab> {
  @override
  void initState() {
    super.initState();
    widget.bloc.add(const ClientProjectsFetched());
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
      child: const ClientProjectsPage(),
    );
  }
}
