/// The routes of lib/features/evidence/shared/. Any feature navigates to
/// them with these names (APP_ARCHITECTURE.md §11).
abstract final class EvidenceRoutes {
  /// My contracted projects, to export one (from settings).
  static const String evidenceProjectsName = 'evidence-projects';
  static const String evidenceProjectsPath = '/evidence';

  /// One project's evidence PDF; `projectId` is the project's id.
  static const String evidenceExportName = 'evidence-export';
  static const String evidenceExportPath = '/evidence/:projectId';
}
