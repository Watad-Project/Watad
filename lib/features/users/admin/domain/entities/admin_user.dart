import 'package:watad/core/enums/user_role.dart';
import 'package:watad/core/enums/verification_status.dart';

/// A user as an admin sees them: a `v_admin_users` row.
class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.role,
    required this.memberSince,
    this.avatarUrl,
    this.isDeleted = false,
    this.isMe = false,
    this.lastSeenAt,
    this.isOnline = false,
    this.isBusiness = false,
    this.companyName,
    this.specialty,
    this.businessCity,
    this.verificationStatus,
    this.isSuspended = false,
    this.suspensionReason,
    this.suspendedAt,
    this.suspendedByName,
    this.clientProjectCount = 0,
    this.contractorProjectCount = 0,
    this.listingCount = 0,
    this.openReportCount = 0,
    this.email,
    this.phone,
    this.nationalId,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final UserRole role;

  /// When they joined, and when they were last seen (UTC).
  final DateTime memberSince;
  final DateTime? lastSeenAt;

  /// The app is open on their phone now.
  final bool isOnline;

  /// The account is closed: nothing can change it.
  final bool isDeleted;

  /// It is the admin looking at it.
  final bool isMe;

  /// The business, when they have one.
  final bool isBusiness;
  final String? companyName;
  final String? specialty;
  final String? businessCity;
  final VerificationStatus? verificationStatus;

  /// The open suspension, when there is one.
  final bool isSuspended;
  final String? suspensionReason;
  final DateTime? suspendedAt;
  final String? suspendedByName;

  /// Projects as a client (owner) and as a contractor (taker), listings,
  /// and reports about them still open or in review.
  final int clientProjectCount;
  final int contractorProjectCount;
  final int listingCount;
  final int openReportCount;

  /// How to reach them and who they are: null when unknown (a phone and an
  /// ID number come with finishing sign-up, and go with closing the
  /// account). Personal data: never log it.
  final String? email;
  final String? phone;
  final String? nationalId;

  /// A user with a business is a contractor; everyone else is a client
  /// (ARCHITECTURE.md §2). Admins are shown as admins.
  bool get isContractor => isBusiness;

  bool get isAdmin => role == UserRole.admin;

  bool get isVerifiedBusiness =>
      isBusiness && verificationStatus == VerificationStatus.verified;

  /// «إيقاف المستخدم» applies: not closed, not me, not an admin (they lose
  /// the role first) and not already suspended.
  bool get canBeSuspended => !isDeleted && !isMe && !isAdmin && !isSuspended;

  /// «رفع الإيقاف» applies.
  bool get canBeUnsuspended => !isDeleted && isSuspended;

  /// «تعيين كمشرف» / «إزالة صلاحية المشرف» applies: not closed, and an
  /// admin can't remove their own role.
  bool get canChangeRole => !isDeleted && !(isMe && isAdmin);
}
