/// Mirror of the Postgres enum `business_document_type` (ARCHITECTURE.md §4).
enum BusinessDocumentType {
  commercialRegistration('commercial_registration'),
  vatCertificate('vat_certificate'),
  nationalAddress('national_address'),
  other('other');

  const BusinessDocumentType(this.value);

  final String value;
}
