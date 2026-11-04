import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/reviews_routes.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/features/reviews/shared/domain/entities/review_subject.dart';
import 'package:watad/features/reviews/shared/presentation/bloc/write_review_bloc.dart';
import 'package:watad/features/reviews/shared/presentation/pages/write_review_page.dart';

final List<RouteBase> reviewsRoutes = [
  GoRoute(
    name: ReviewsRoutes.writeReviewName,
    path: ReviewsRoutes.writeReviewPath,
    pageBuilder: (context, state) {
      final query = state.uri.queryParameters;
      final subject = ReviewSubject(
        targetUserId: query['user'] ?? '',
        projectId: query['project'],
        orderId: query['order'],
      );
      return _SheetPage<bool>(
        key: state.pageKey,
        child: BlocProvider(
          create: (_) =>
              getIt<WriteReviewBloc>()..add(WriteReviewStarted(subject)),
          child: const WriteReviewPage(),
        ),
      );
    },
  ),
];

/// A route shown as a bottom sheet over the page under it, with the app's
/// motion, like `AppPopup.sheet()`.
class _SheetPage<T> extends Page<T> {
  const _SheetPage({required this.child, super.key});

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => ModalBottomSheetRoute<T>(
    settings: this,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: AppMotion.popup,
    builder: (_) => child,
  );
}
