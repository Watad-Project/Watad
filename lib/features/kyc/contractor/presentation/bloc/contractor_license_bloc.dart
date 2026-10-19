import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/kyc/contractor/domain/entities/contractor_license_submission.dart';
import 'package:watad/features/kyc/contractor/domain/usecases/contractor_upload_license_use_case.dart';

part 'contractor_license_event.dart';
part 'contractor_license_state.dart';

class ContractorLicenseBloc
    extends Bloc<ContractorLicenseEvent, ContractorLicenseState> {
  ContractorLicenseBloc(this._uploadLicense)
    : super(const ContractorLicenseInitial()) {
    on<ContractorLicenseFileSelected>(_onFileSelected);
    on<ContractorLicenseSubmitted>(_onSubmitted);
  }

  final ContractorUploadLicenseUseCase _uploadLicense;

  Uint8List? _selectedBytes;
  String? _selectedFileName;

  void _onFileSelected(
    ContractorLicenseFileSelected event,
    Emitter<ContractorLicenseState> emit,
  ) {
    _selectedBytes = event.bytes;
    _selectedFileName = event.fileName;
    emit(ContractorLicenseReady(bytes: event.bytes, fileName: event.fileName));
  }

  Future<void> _onSubmitted(
    ContractorLicenseSubmitted event,
    Emitter<ContractorLicenseState> emit,
  ) async {
    final bytes = _selectedBytes;
    final fileName = _selectedFileName;
    if (bytes == null || fileName == null) {
      emit(
        const ContractorLicenseLoadFailure(
          ValidationFailure('validation.file_required'),
        ),
      );
      return;
    }

    emit(const ContractorLicenseLoadInProgress());
    final result = await _uploadLicense(
      ContractorUploadLicenseParams(bytes: bytes, fileName: fileName),
    );

    switch (result) {
      case Success(:final data):
        emit(ContractorLicenseLoadSuccess(data));
      case Failed(:final failure):
        emit(ContractorLicenseLoadFailure(failure));
    }
  }
}
