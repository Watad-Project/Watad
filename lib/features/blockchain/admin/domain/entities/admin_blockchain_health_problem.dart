/// Why the blockchain didn't answer the health check.
enum AdminBlockchainHealthProblem {
  /// It took longer than the check waits.
  timeout,

  /// It couldn't be reached at all.
  unreachable,

  /// It answered, but not with 200.
  badStatus,
}
