import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_projects_filter.dart';

void main() {
  ClientProject project(ProjectStatus status) => ClientProject(
    id: 'p-1',
    title: 'فيلا سكنية',
    status: status,
    city: 'المدينة المنورة',
    pendingOfferCount: 0,
    createdAt: DateTime.utc(2026, 10, 18),
  );

  /// The one chip that shows a project of [status].
  ClientProjectsFilter chipOf(ProjectStatus status) => ClientProjectsFilter
      .values
      .singleWhere((filter) => filter.matches(project(status)));

  test('waiting: drafts waiting for the deed, and open for offers', () {
    expect(chipOf(ProjectStatus.draft), ClientProjectsFilter.waiting);
    expect(chipOf(ProjectStatus.open), ClientProjectsFilter.waiting);
  });

  test('in progress: being built', () {
    expect(chipOf(ProjectStatus.inProgress), ClientProjectsFilter.inProgress);
  });

  test('done: finished, or cancelled', () {
    expect(chipOf(ProjectStatus.completed), ClientProjectsFilter.done);
    expect(chipOf(ProjectStatus.cancelled), ClientProjectsFilter.done);
  });
}
