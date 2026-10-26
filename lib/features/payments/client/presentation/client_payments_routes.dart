import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/client_payments_routes.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_selection.dart';
import 'package:watad/features/payments/client/presentation/bloc/client_bank_transfer_bloc.dart';
import 'package:watad/features/payments/client/presentation/bloc/client_new_payment_bloc.dart';
import 'package:watad/features/payments/client/presentation/pages/client_bank_transfer_page.dart';
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
  GoRoute(
    name: ClientPaymentsRoutes.bankTransferName,
    path: ClientPaymentsRoutes.bankTransferPath,
    builder: (context, state) {
      // The selected tasks come as `?taskIds=a,b,c`; the page reads them
      // again, so a link keeps working.
      final selection = ClientPaymentSelection(
        projectId: state.pathParameters['projectId']!,
        taskIds: [
          for (final id in (state.uri.queryParameters['taskIds'] ?? '').split(
            ',',
          ))
            if (id.isNotEmpty) id,
        ],
      );
      return BlocProvider(
        create: (_) =>
            getIt<ClientBankTransferBloc>()
              ..add(ClientBankTransferFetched(selection)),
        child: ClientBankTransferPage(selection: selection),
      );
    },
  ),
];
