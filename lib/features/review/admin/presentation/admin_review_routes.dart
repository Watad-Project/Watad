import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/admin_review_routes.dart';
import 'package:watad/features/review/admin/presentation/bloc/admin_review_bloc.dart';
import 'package:watad/features/review/admin/presentation/bloc/admin_review_documents_bloc.dart';
import 'package:watad/features/review/admin/presentation/pages/admin_review_documents_page.dart';
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
    name: AdminReviewRoutes.reviewDocumentsName,
    path: AdminReviewRoutes.reviewDocumentsPath,
    builder: (context, state) {
      final businessId = state.pathParameters['businessId']!;
      return BlocProvider(
        create: (_) =>
            getIt<AdminReviewDocumentsBloc>()
              ..add(AdminReviewDocumentsFetched(businessId)),
        child: AdminReviewDocumentsPage(businessId: businessId),
      );
    },
  ),
];
