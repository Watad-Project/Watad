import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/features/blockchain/admin/presentation/bloc/admin_blockchain_bloc.dart';
import 'package:watad/features/blockchain/admin/presentation/pages/admin_blockchain_page.dart';

/// The monitor as the admin's «البلوك تشين» tab. The injection file passes
/// the bloc in (widgets don't create blocs, APP_ARCHITECTURE.md §10), and
/// the tab closes it when it goes away.
///
/// The navigation keeps a tab alive while another one shows, so the
/// monitor is read, and the ledger checked, again each time this tab shows.
class AdminBlockchainTab extends StatefulWidget {
  const AdminBlockchainTab({required this.bloc, this.bell, super.key});

  final AdminBlockchainBloc bloc;

  /// The notifications bell, for the top bar.
  final Widget? bell;

  @override
  State<AdminBlockchainTab> createState() => _AdminBlockchainTabState();
}

class _AdminBlockchainTabState extends State<AdminBlockchainTab> {
  bool _wasVisible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The navigation's IndexedStack says which tab shows.
    final isVisible = Visibility.of(context);
    if (isVisible && !_wasVisible) {
      widget.bloc.add(const AdminBlockchainFetched());
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
    child: AdminBlockchainPage(isTab: true, bell: widget.bell),
  );
}
