import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/business_document_type.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/router/routes/kyc_routes.dart';
import 'package:watad/features/kyc/shared/presentation/bloc/kyc_status_bloc.dart';
import 'package:watad/features/kyc/shared/presentation/pages/status_page.dart';

final List<RouteBase> kycRoutes = [
  GoRoute(
    name: KycRoutes.statusName,
    path: KycRoutes.statusPath,
    builder: (context, state) {
      final typeParam = state.uri.queryParameters['type'];
      final statusParam = state.uri.queryParameters['status'];

      final documentType = switch (typeParam) {
        'vat_certificate' => BusinessDocumentType.vatCertificate,
        'national_address' => BusinessDocumentType.nationalAddress,
        'other' => BusinessDocumentType.other,
        _ => BusinessDocumentType.commercialRegistration,
      };

      final initialStatus = switch (statusParam) {
        'verified' => VerificationStatus.verified,
        'rejected' => VerificationStatus.rejected,
        'pending' => VerificationStatus.pending,
        'suspended' => VerificationStatus.suspended,
        'unverified' => VerificationStatus.unverified,
        _ => null,
      };

      return BlocProvider(
        create: (_) => getIt<KycStatusBloc>()
          ..add(
            KycStatusStarted(
              documentType: documentType,
              initialStatus: initialStatus,
            ),
          ),
        child: StatusPage(
          documentType: documentType,
          initialStatus: initialStatus,
        ),
      );
    },
  ),
];
