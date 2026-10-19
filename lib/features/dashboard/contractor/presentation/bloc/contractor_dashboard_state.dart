part of 'contractor_dashboard_bloc.dart';

sealed class ContractorDashboardState {
  const ContractorDashboardState();
}

final class ContractorDashboardInitial extends ContractorDashboardState {
  const ContractorDashboardInitial();
}

final class ContractorDashboardLoadInProgress extends ContractorDashboardState {
  const ContractorDashboardLoadInProgress();
}

final class ContractorDashboardLoadSuccess extends ContractorDashboardState {
  const ContractorDashboardLoadSuccess(this.data);

  final ContractorDashboardData data;
}

final class ContractorDashboardLoadFailure extends ContractorDashboardState {
  const ContractorDashboardLoadFailure(this.failure);

  final Failure failure;
}
