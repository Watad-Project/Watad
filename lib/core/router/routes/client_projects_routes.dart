/// The routes of lib/features/projects/client/. Any feature navigates to
/// them with these names (APP_ARCHITECTURE.md §11).
abstract final class ClientProjectsRoutes {
  static const String postProjectName = 'client-post-project';
  static const String postProjectPath = '/client/projects/post-project';

  static const String projectsName = 'client-projects';
  static const String projectsPath = '/client/projects';

  static const String projectTasksName = 'client-project-tasks';
  static const String projectTasksPath = '/client/projects/:projectId';

  static const String projectOffersName = 'client-project-offers';
  static const String projectOffersPath = '/client/projects/:projectId/offers';

  static const String projectDeedName = 'client-project-deed';
  static const String projectDeedPath = '/client/projects/:projectId/deed';

  static const String taskDetailsName = 'client-task-details';
  static const String taskDetailsPath =
      '/client/projects/:projectId/tasks/:taskId';

  static const String taskUpdateName = 'client-task-update';
  static const String taskUpdatePath =
      '/client/projects/:projectId/updates/:updateId';
}
