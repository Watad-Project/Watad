import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/project_status.dart';

void main() {
  test('ProjectStatus serializes and deserializes', () {
    expect(ProjectStatus.fromJson('draft'), ProjectStatus.draft);
    expect(ProjectStatus.fromJson('open'), ProjectStatus.open);
    expect(ProjectStatus.fromJson('in_progress'), ProjectStatus.inProgress);
    expect(ProjectStatus.fromJson('completed'), ProjectStatus.completed);
    expect(ProjectStatus.fromJson('cancelled'), ProjectStatus.cancelled);

    expect(ProjectStatus.open.toJson(), 'open');
    expect(() => ProjectStatus.fromJson('unknown'), throwsStateError);
  });
}
