/// What stops an account from closing (the checks of
/// `private.close_account()`).
enum SettingsDeleteBlocker {
  /// An order paid or shipped, as buyer or seller.
  activeOrders,

  /// A project in progress, as client or contractor.
  activeProjects,
}
