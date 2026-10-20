import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/features/review/admin/presentation/bloc/admin_review_bloc.dart';
import 'package:watad/features/review/admin/presentation/pages/admin_review_page.dart';

/// The queue as the admin's «التوثيق» tab. The injection file passes the
/// bloc in (widgets don't create blocs, APP_ARCHITECTURE.md §10), and the tab
/// closes it when it goes away.
class AdminReviewTab extends StatefulWidget {
  const AdminReviewTab({required this.bloc, this.bell, super.key});

  final AdminReviewBloc bloc;

  /// The notifications bell, for the top bar.
  final Widget? bell;

  @override
  State<AdminReviewTab> createState() => _AdminReviewTabState();
}

class _AdminReviewTabState extends State<AdminReviewTab> {
  @override
  void dispose() {
    widget.bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: widget.bloc,
    child: AdminReviewPage(bell: widget.bell),
  );
}
