import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/features/profile/contractor/presentation/pages/contractor_profile_page.dart';
import 'package:watad/features/profile/shared/presentation/bloc/profile_overview_bloc.dart';

/// The account as the contractor's «منشأتي» tab. The injection file passes
/// the bloc in (widgets don't create blocs, APP_ARCHITECTURE.md §10), and the
/// tab closes it when it goes away.
class ContractorProfileTab extends StatefulWidget {
  const ContractorProfileTab({required this.bloc, super.key});

  final ProfileOverviewBloc bloc;

  @override
  State<ContractorProfileTab> createState() => _ContractorProfileTabState();
}

class _ContractorProfileTabState extends State<ContractorProfileTab> {
  @override
  void dispose() {
    widget.bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: widget.bloc,
    child: const ContractorProfilePage(),
  );
}
