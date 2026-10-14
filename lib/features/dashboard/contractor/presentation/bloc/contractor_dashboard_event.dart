part of 'contractor_dashboard_bloc.dart';

sealed class ContractorDashboardEvent {
  const ContractorDashboardEvent();
}

final class ContractorDashboardFetched extends ContractorDashboardEvent {
  const ContractorDashboardFetched();
}

final class ContractorDashboardRefreshed extends ContractorDashboardEvent {
  const ContractorDashboardRefreshed();
}
