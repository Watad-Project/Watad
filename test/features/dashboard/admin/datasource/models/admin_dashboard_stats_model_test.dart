import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/dashboard/admin/datasource/models/admin_dashboard_stats_model.dart';

void main() {
  test('fromJson maps the v_admin_dashboard row', () {
    final model = AdminDashboardStatsModel.fromJson(const {
      'active_users': 1240,
      'clients': 980,
      'businesses': 260,
      'verified_businesses': 212,
      'projects': 418,
      'projects_draft': 31,
      'projects_open': 57,
      'projects_in_progress': 96,
      'projects_completed': 219,
      'projects_cancelled': 15,
      'market_items': 640,
      'market_items_live': 588,
      'pending_licenses': 7,
      'pending_deeds': 3,
      'open_reports': 5,
      'online_users': 37,
    });

    expect(model.activeUsers, 1240);
    expect(model.clients, 980);
    expect(model.businesses, 260);
    expect(model.verifiedBusinesses, 212);
    expect(model.projects, 418);
    expect(model.draftProjects, 31);
    expect(model.openProjects, 57);
    expect(model.inProgressProjects, 96);
    expect(model.completedProjects, 219);
    expect(model.cancelledProjects, 15);
    expect(model.marketItems, 640);
    expect(model.liveMarketItems, 588);
    expect(model.pendingLicenses, 7);
    expect(model.pendingDeeds, 3);
    expect(model.openReports, 5);
    expect(model.onlineUsers, 37);
    expect(model.blockchainFailed, 0);
    expect(model.blockchainPending, 0);
  });

  test('the blockchain row gives the card its counts', () {
    final model = AdminDashboardStatsModel.fromJson(const {
      'projects': 5,
      'blockchain_waiting': 1,
      'blockchain_retrying': 2,
      'blockchain_failed': 1,
    });

    expect(model.blockchainFailed, 1);
    expect(model.blockchainPending, 3);
  });

  test('a missing count reads as zero', () {
    final model = AdminDashboardStatsModel.fromJson(const {'projects': 2});

    expect(model.projects, 2);
    expect(model.pendingDeeds, 0);
  });
}
