import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/enums/business_document_type.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/kyc/shared/domain/entities/kyc_document.dart';
import 'package:watad/features/kyc/shared/domain/usecases/get_kyc_document_use_case.dart';
import 'package:watad/features/kyc/shared/domain/usecases/sign_out_kyc_use_case.dart';
import 'package:watad/features/kyc/shared/domain/usecases/watch_kyc_document_use_case.dart';

part 'kyc_status_event.dart';
part 'kyc_status_state.dart';

class KycStatusBloc extends Bloc<KycStatusEvent, KycStatusState> {
  KycStatusBloc(
    this._getDocument, [
    WatchKycDocumentUseCase? watchDocument,
    this._signOut,
  ]) : super(const KycStatusInitial()) {
    on<KycStatusStarted>(_onStarted);
    on<KycStatusRefreshed>(_onRefreshed);
    on<KycStatusUpdated>(_onUpdated);
    on<KycStatusSignedOut>(_onSignedOut);
  }

  final GetKycDocumentUseCase _getDocument;
  final SignOutKycUseCase? _signOut;

  Future<void> _onStarted(
    KycStatusStarted event,
    Emitter<KycStatusState> emit,
  ) async {
    if (event.initialStatus != null) {
      emit(
        KycStatusLoadSuccess(
          KycDocument(
            id: '',
            documentType: event.documentType,
            status: event.initialStatus!,
          ),
        ),
      );
    } else {
      emit(const KycStatusLoadInProgress());
      final result = await _getDocument(event.documentType);
      switch (result) {
        case Success(:final data):
          emit(KycStatusLoadSuccess(data));
        case Failed(:final failure):
          emit(KycStatusLoadFailure(failure));
      }
    }
  }

  Future<void> _onRefreshed(
    KycStatusRefreshed event,
    Emitter<KycStatusState> emit,
  ) async {
    final result = await _getDocument(event.documentType);
    switch (result) {
      case Success(:final data):
        emit(KycStatusLoadSuccess(data));
      case Failed(:final failure):
        emit(KycStatusLoadFailure(failure));
    }
    event.completer?.complete();
  }

  void _onUpdated(KycStatusUpdated event, Emitter<KycStatusState> emit) {
    emit(KycStatusLoadSuccess(event.document));
  }

  Future<void> _onSignedOut(
    KycStatusSignedOut event,
    Emitter<KycStatusState> emit,
  ) async {
    final signOut = _signOut;
    if (signOut == null) {
      emit(const KycStatusSignOutSuccess());
      return;
    }
    emit(const KycStatusLoadInProgress());
    final result = await signOut(const NoParams());
    switch (result) {
      case Success():
        emit(const KycStatusSignOutSuccess());
      case Failed(:final failure):
        emit(KycStatusLoadFailure(failure));
    }
  }
}
