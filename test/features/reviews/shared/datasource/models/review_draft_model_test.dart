import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/reviews/shared/datasource/models/review_draft_model.dart';

void main() {
  test('fromJson maps the name and my earlier review', () {
    final draft = ReviewDraftModel.fromJson(const {
      'display_name': 'مؤسسة البناء المتين',
      'my_review': {'id': 'r-1', 'rating': 3, 'comment': 'تأخر يومين'},
    });

    expect(draft.targetName, 'مؤسسة البناء المتين');
    expect(draft.existing?.id, 'r-1');
    expect(draft.existing?.rating, 3);
    expect(draft.existing?.comment, 'تأخر يومين');
  });

  test('without a review of mine yet', () {
    final draft = ReviewDraftModel.fromJson(const {
      'display_name': null,
      'my_review': null,
    });

    expect(draft.targetName, '');
    expect(draft.existing, isNull);
  });
}
