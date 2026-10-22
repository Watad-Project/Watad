import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/task_update_state.dart';

void main() {
  test('round-trips every task_update_state value', () {
    for (final state in TaskUpdateState.values) {
      expect(TaskUpdateState.fromJson(state.toJson()), state);
    }
    expect(TaskUpdateState.inProgress.toJson(), 'in_progress');
    expect(TaskUpdateState.done.toJson(), 'done');
  });

  test('throws on an unknown task_update_state value', () {
    expect(() => TaskUpdateState.fromJson('unknown'), throwsStateError);
  });
}
