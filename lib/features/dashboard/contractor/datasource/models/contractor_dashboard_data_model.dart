import 'package:watad/features/dashboard/contractor/datasource/models/contractor_dashboard_earnings_model.dart';
import 'package:watad/features/dashboard/contractor/datasource/models/contractor_dashboard_offer_model.dart';
import 'package:watad/features/dashboard/contractor/datasource/models/contractor_dashboard_profile_model.dart';
import 'package:watad/features/dashboard/contractor/datasource/models/contractor_dashboard_project_model.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_data.dart';

class ContractorDashboardDataModel extends ContractorDashboardData {
  const ContractorDashboardDataModel({
    required super.profile,
    required super.earnings,
    required super.opportunitiesCount,
    required super.activeProjects,
    required super.myOffers,
  });

  factory ContractorDashboardDataModel.fromJson(Map<String, dynamic> json) {
    final profileJson = json['profile'] as Map<String, dynamic>? ?? {};
    final earningsJson = json['earnings'] as Map<String, dynamic>? ?? {};
    final projectsJson = json['active_projects'] as List<dynamic>? ?? [];
    final offersJson = json['my_offers'] as List<dynamic>? ?? [];

    return ContractorDashboardDataModel(
      profile: ContractorDashboardProfileModel.fromJson(profileJson),
      earnings: ContractorDashboardEarningsModel.fromJson(earningsJson),
      opportunitiesCount: json['opportunities_count'] as int? ?? 0,
      activeProjects: projectsJson
          .map(
            (e) => ContractorDashboardProjectModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      myOffers: offersJson
          .map(
            (e) => ContractorDashboardOfferModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}
