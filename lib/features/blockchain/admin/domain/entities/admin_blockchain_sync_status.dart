/// Where a contracted project's copy on the blockchain stands: the
/// `sync_status` of `v_admin_blockchain_sync` (ARCHITECTURE.md §9).
///
/// In the order the admin should look at them: what needs a person first.
enum AdminBlockchainSyncStatus {
  /// The API refused the record, or the run reported NEEDS ATTENTION. It is
  /// not retried: someone fixes the data, then resyncs.
  failed,

  /// An attempt failed for a reason that may pass; it runs again later.
  retrying,

  /// A change waits to be copied.
  waiting,

  /// The chain matches the database.
  synced,
}
