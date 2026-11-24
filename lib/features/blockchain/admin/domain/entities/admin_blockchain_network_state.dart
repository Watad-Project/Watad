/// Whether the blockchain network is up now, by the uptime monitor's last
/// check.
enum AdminBlockchainNetworkState {
  /// The last check, recent enough, found it healthy.
  up,

  /// The last check, recent enough, found it down.
  down,

  /// No recent check: the monitor is stopped, or hasn't answered lately.
  unknown,
}
