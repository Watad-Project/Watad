/// What a report is about, when it's about something: the screen it was
/// sent from fills it in (the public profile, an item, an order…).
class SupportTarget {
  const SupportTarget({required this.kind, required this.id});

  final SupportTargetKind kind;
  final String id;
}

/// The `target_*` columns of `help_reports`; a report has at most one.
enum SupportTargetKind {
  user('user'),
  project('project'),
  item('item'),
  order('order'),
  review('review'),
  message('message');

  const SupportTargetKind(this.value);

  /// The name in the route's query and in `v_my_help_reports.target_type`.
  final String value;

  /// The kind named [value]; null for anything else.
  static SupportTargetKind? named(String? value) {
    for (final kind in values) {
      if (kind.value == value) return kind;
    }
    return null;
  }
}
