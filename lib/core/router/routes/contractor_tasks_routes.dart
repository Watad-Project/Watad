abstract final class ContractorTasksRoutes {
  static const String projectTasksName = 'contractor-project-tasks';
  static const String projectTasksPath = '/contractor/tasks/:projectId';

  static const String taskUpdateName = 'contractor-task-update';
  static const String taskUpdatePath =
      '/contractor/tasks/:projectId/updates/new';

  static const String taskUpdateStatusName = 'contractor-task-update-status';
  static const String taskUpdateStatusPath =
      '/contractor/tasks/:projectId/updates/:updateId';
}
