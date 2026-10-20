import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/feedback/app_not_found_view.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/admin_review_routes.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_kind.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_target.dart';
import 'package:watad/features/review/admin/presentation/bloc/admin_review_bloc.dart';
import 'package:watad/features/review/admin/presentation/bloc/admin_review_details_bloc.dart';
import 'package:watad/features/review/admin/presentation/pages/admin_review_details_page.dart';
import 'package:watad/features/review/admin/presentation/pages/admin_review_page.dart';

final List<RouteBase> adminReviewRoutes = [
  GoRoute(
    name: AdminReviewRoutes.reviewName,
    path: AdminReviewRoutes.reviewPath,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<AdminReviewBloc>()..add(const AdminReviewFetched()),
      child: const AdminReviewPage(),
    ),
  ),
  GoRoute(
    name: AdminReviewRoutes.reviewDetailsName,
    path: AdminReviewRoutes.reviewDetailsPath,
    builder: (context, state) {
      final kind = AdminReviewKind.values
          .asNameMap()[state.pathParameters['kind']];
      if (kind == null) {
        return AppNotFoundView(
          onBackToStart: () => context.goNamed(AdminReviewRoutes.reviewName),
        );
      }
      final target = AdminReviewTarget(
        kind: kind,
        id: state.pathParameters['id']!,
      );
      return BlocProvider(
        create: (_) =>
            getIt<AdminReviewDetailsBloc>()
              ..add(AdminReviewDetailsFetched(target)),
        child: AdminReviewDetailsPage(target: target),
      );
    },
  ),
];
