import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/features/home/client/presentation/bloc/client_home_bloc.dart';
import 'package:watad/features/home/client/presentation/pages/client_home_page.dart';

/// The home as the client's «الرئيسية» tab. The injection file passes the
/// bloc in (widgets don't create blocs, APP_ARCHITECTURE.md §10), and the tab
/// closes it when it goes away.
class ClientHomeTab extends StatefulWidget {
  const ClientHomeTab({required this.bloc, this.bell, super.key});

  final ClientHomeBloc bloc;

  /// The notifications bell, for the header.
  final Widget? bell;

  @override
  State<ClientHomeTab> createState() => _ClientHomeTabState();
}

class _ClientHomeTabState extends State<ClientHomeTab> {
  @override
  void dispose() {
    widget.bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: widget.bloc,
    child: ClientHomePage(bell: widget.bell),
  );
}
