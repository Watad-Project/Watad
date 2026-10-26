/// Whether a task can be paid now, or why not (GRA-50).
enum ClientTaskPayability {
  /// Approved and priced, and its payment stage waits for the money.
  payable,

  /// Its payment stage is paid.
  paid,

  /// A receipt was sent for it; the contractor hasn't confirmed it yet.
  awaitingConfirmation,

  /// The client hasn't approved it yet.
  notApproved,

  /// Approved, but without an amount: there's nothing to pay.
  noAmount,

  /// Its payment stage was cancelled or refunded.
  unavailable,
}
