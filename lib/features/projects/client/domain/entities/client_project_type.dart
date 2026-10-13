/// The types of project a client can post.
///
/// Decides whether the post-project flow requires an ownership deed
/// (4 steps total) or publishes directly without a deed (3 steps total).
enum ClientProjectType {
  newHouse(
    titleKey: 'projects.client.type_new_house',
    hintKey: 'projects.client.type_new_house_hint',
    requiresDeed: true,
    totalSteps: 4,
  ),
  renovation(
    titleKey: 'projects.client.type_renovation',
    hintKey: 'projects.client.type_renovation_hint',
    requiresDeed: true,
    totalSteps: 4,
  ),
  repairs(
    titleKey: 'projects.client.type_repairs',
    hintKey: 'projects.client.type_repairs_hint',
    requiresDeed: false,
    totalSteps: 3,
  );

  const ClientProjectType({
    required this.titleKey,
    required this.hintKey,
    required this.requiresDeed,
    required this.totalSteps,
  });

  /// The translation key for the type's title.
  final String titleKey;

  /// The translation key for the type's hint/sub-label.
  final String hintKey;

  /// Whether publishing this project type requires an ownership deed.
  final bool requiresDeed;

  /// Total number of steps in the post-project flow for this type.
  final int totalSteps;
}
