/// The routes of lib/features/payments/client/. Any feature navigates to
/// them with these names (APP_ARCHITECTURE.md §11).
abstract final class ClientPaymentsRoutes {
  static const String newPaymentName = 'client-new-payment';
  static const String newPaymentPath = '/client/payments/:projectId/new';
}
