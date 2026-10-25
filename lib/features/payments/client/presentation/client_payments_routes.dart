import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/client_payments_routes.dart';
import 'package:watad/features/payments/client/presentation/bloc/client_new_payment_bloc.dart';
import 'package:watad/features/payments/client/presentation/pages/client_new_payment_page.dart';

final List<RouteBase> clientPaymentsRoutes = [
  GoRoute(
    name: ClientPaymentsRoutes.newPaymentName,
    path: ClientPaymentsRoutes.newPaymentPath,
    builder: (context, state) {
      final projectId = state.pathParameters['projectId']!;
      return BlocProvider(
        create: (_) =>
            getIt<ClientNewPaymentBloc>()
              ..add(ClientNewPaymentFetched(projectId)),
        child: ClientNewPaymentPage(projectId: projectId),
      );
    },
  ),
];
