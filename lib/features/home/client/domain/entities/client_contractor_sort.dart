/// How the contractors list is ordered, after the client's own city.
enum ClientContractorSort {
  /// Highest average rating first; contractors without ratings last.
  rating,

  /// Most completed projects first.
  projects,
}
