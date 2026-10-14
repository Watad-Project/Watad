class BusinessSignUp {
  const BusinessSignUp({
    required this.companyName,
    required this.crNumber,
    required this.email,
    required this.phone,
    this.specializedField = 'contractor',
    this.role = 'contractor',
  });

  final String companyName;
  final String crNumber;
  final String email;
  final String phone;
  final String specializedField;
  final String role;
}
