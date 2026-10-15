/// The routes of lib/features/projects/client/. Any feature navigates to
/// them with these names (APP_ARCHITECTURE.md §11).
abstract final class ClientProjectsRoutes {
  static const String projectsName = 'client-projects';
  static const String projectsPath = '/client/projects';

  static const String projectOffersName = 'client-project-offers';
  static const String projectOffersPath = '/client/projects/:projectId/offers';
}
