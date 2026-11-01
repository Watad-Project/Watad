import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/features/profile/client/presentation/pages/client_profile_page.dart';
import 'package:watad/features/profile/shared/presentation/bloc/profile_overview_bloc.dart';

/// The account as the client's «حسابي» tab. The injection file passes the
/// bloc in (widgets don't create blocs, APP_ARCHITECTURE.md §10), and the tab
/// closes it when it goes away.
class ClientProfileTab extends StatefulWidget {
  const ClientProfileTab({required this.bloc, super.key});

  final ProfileOverviewBloc bloc;

  @override
  State<ClientProfileTab> createState() => _ClientProfileTabState();
}

class _ClientProfileTabState extends State<ClientProfileTab> {
  @override
  void dispose() {
    widget.bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocProvider.value(value: widget.bloc, child: const ClientProfilePage());
}
