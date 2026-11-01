import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/features/chat/shared/presentation/bloc/chats_bloc.dart';
import 'package:watad/features/chat/shared/presentation/pages/chats_page.dart';

/// The chats as the «المحادثات» tab. The injection file passes the bloc in
/// (widgets don't create blocs, APP_ARCHITECTURE.md §10), and the tab
/// closes it when it goes away.
///
/// The navigation keeps a tab alive while another one shows, so the chats
/// are read again each time this tab shows.
class ChatsTab extends StatefulWidget {
  const ChatsTab({required this.bloc, this.bell, super.key});

  final ChatsBloc bloc;

  /// The notifications bell, for the top bar.
  final Widget? bell;

  @override
  State<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab> {
  bool _wasVisible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The navigation's IndexedStack says which tab shows.
    final isVisible = Visibility.of(context);
    if (isVisible && !_wasVisible) {
      widget.bloc.add(const ChatsFetched());
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
    child: ChatsPage(isTab: true, bell: widget.bell),
  );
}
