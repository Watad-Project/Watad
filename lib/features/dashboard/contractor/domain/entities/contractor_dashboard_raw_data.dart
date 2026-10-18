import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_offer.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_payment.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_profile.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_project.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_task.dart';

/// Raw aggregated rows fetched from the remote views before domain calculations.
class ContractorDashboardRawData {
  const ContractorDashboardRawData({
    required this.profile,
    required this.payments,
    required this.opportunitiesCount,
    required this.projects,
    required this.tasks,
    required this.offers,
  });

  final ContractorDashboardProfile profile;
  final List<ContractorDashboardPayment> payments;
  final int opportunitiesCount;
  final List<ContractorDashboardProject> projects;
  final List<ContractorDashboardTask> tasks;
  final List<ContractorDashboardOffer> offers;
}
