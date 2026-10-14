import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_projects_bloc.dart';
import 'package:watad/features/projects/client/presentation/pages/client_projects_page.dart';

/// Tab wrapper providing [ClientProjectsBloc] to [ClientProjectsPage] for navigation.
class ClientProjectsTab extends StatefulWidget {
  const ClientProjectsTab({super.key, required this.bloc});

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
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.bloc,
      child: const ClientProjectsPage(),
    );
  }
}
