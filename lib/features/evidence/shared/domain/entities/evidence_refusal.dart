/// Why no evidence came back: the errors of the `project-evidence` Edge
/// Function (ARCHITECTURE.md §6).
enum EvidenceRefusal {
  notAllowed,
  notFound,

  /// The project has no accepted offer.
  notOnChain,

  /// Agreed, but the sync hasn't copied it to the chain yet.
  notOnChainYet,

  /// The blockchain didn't answer, or refused.
  ledgerUnavailable,
  timeout,

  /// The function's secrets aren't set, or another server error.
  unavailable,
}
