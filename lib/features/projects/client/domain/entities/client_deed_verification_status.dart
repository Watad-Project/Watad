/// The verification lifecycle of a property or land ownership deed.
enum ClientDeedVerificationStatus {
  /// No deed has been uploaded yet.
  none,

  /// Deed uploaded and waiting for review; project is draft and hidden from contractors.
  underReview,

  /// Deed verified; project is published and visible with a verified deed badge.
  verified,

  /// Deed rejected with a reason; client must re-upload.
  rejected,
}
