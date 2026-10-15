import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/project_status.dart';

void main() {
  test('fromJson parses every project status from ARCHITECTURE.md §4', () {
    expect(ProjectStatus.fromJson('draft'), ProjectStatus.draft);
    expect(ProjectStatus.fromJson('open'), ProjectStatus.open);
    expect(ProjectStatus.fromJson('in_progress'), ProjectStatus.inProgress);
    expect(ProjectStatus.fromJson('completed'), ProjectStatus.completed);
    expect(ProjectStatus.fromJson('cancelled'), ProjectStatus.cancelled);
  });

  test('fromJson throws on unknown status', () {
    expect(() => ProjectStatus.fromJson('unknown'), throwsStateError);
  });

  test('toJson matches the value', () {
    expect(ProjectStatus.open.toJson(), 'open');
    expect(ProjectStatus.inProgress.toJson(), 'in_progress');
  });
}
