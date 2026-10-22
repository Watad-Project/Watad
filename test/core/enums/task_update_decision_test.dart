import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/task_update_decision.dart';

void main() {
  test('round-trips every task_update_decision value', () {
    for (final decision in TaskUpdateDecision.values) {
      expect(TaskUpdateDecision.fromJson(decision.toJson()), decision);
    }
    expect(TaskUpdateDecision.pending.toJson(), 'pending');
    expect(TaskUpdateDecision.accepted.toJson(), 'accepted');
    expect(TaskUpdateDecision.rejected.toJson(), 'rejected');
  });

  test('throws on an unknown task_update_decision value', () {
    expect(() => TaskUpdateDecision.fromJson('unknown'), throwsStateError);
  });
}
