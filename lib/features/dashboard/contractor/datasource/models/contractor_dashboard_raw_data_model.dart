import 'package:watad/features/dashboard/contractor/datasource/models/contractor_dashboard_offer_model.dart';
import 'package:watad/features/dashboard/contractor/datasource/models/contractor_dashboard_payment_model.dart';
import 'package:watad/features/dashboard/contractor/datasource/models/contractor_dashboard_profile_model.dart';
import 'package:watad/features/dashboard/contractor/datasource/models/contractor_dashboard_project_model.dart';
import 'package:watad/features/dashboard/contractor/datasource/models/contractor_dashboard_task_model.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_raw_data.dart';

class ContractorDashboardRawDataModel extends ContractorDashboardRawData {
  const ContractorDashboardRawDataModel({
    required super.profile,
    required super.payments,
    required super.opportunitiesCount,
    required super.projects,
    required super.tasks,
    required super.offers,
  });

  factory ContractorDashboardRawDataModel.fromJson(Map<String, dynamic> json) {
    final profileJson = json['profile'] as Map<String, dynamic>? ?? {};
    final paymentsJson = json['payments'] as List<dynamic>? ?? [];
    final projectsJson = json['projects'] as List<dynamic>? ?? [];
    final tasksJson = json['tasks'] as List<dynamic>? ?? [];
    final offersJson = json['offers'] as List<dynamic>? ?? [];

    return ContractorDashboardRawDataModel(
      profile: ContractorDashboardProfileModel.fromJson(profileJson),
      payments: paymentsJson
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (e) => ContractorDashboardPaymentModel.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
      opportunitiesCount: json['opportunities_count'] as int? ?? 0,
      projects: projectsJson
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (e) => ContractorDashboardProjectModel.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
      tasks: tasksJson
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (e) => ContractorDashboardTaskModel.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
      offers: offersJson
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (e) => ContractorDashboardOfferModel.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
    );
  }
}
