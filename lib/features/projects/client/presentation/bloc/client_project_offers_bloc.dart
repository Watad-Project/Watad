import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_offer.dart';
import 'package:watad/features/projects/client/domain/usecases/client_accept_offer_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_project_by_id_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_project_offers_use_case.dart';

part 'client_project_offers_event.dart';
part 'client_project_offers_state.dart';

class ClientProjectOffersBloc
    extends Bloc<ClientProjectOffersEvent, ClientProjectOffersState> {
  ClientProjectOffersBloc(
    this._getProjectById,
    this._getProjectOffers,
    this._acceptOffer,
  ) : super(const ClientProjectOffersInitial()) {
    on<ClientProjectOffersFetched>(_onFetched);
    on<ClientProjectOfferAccepted>(_onOfferAccepted);
  }

  final ClientGetProjectByIdUseCase _getProjectById;
  final ClientGetProjectOffersUseCase _getProjectOffers;
  final ClientAcceptOfferUseCase _acceptOffer;

  Future<void> _onFetched(
    ClientProjectOffersFetched event,
    Emitter<ClientProjectOffersState> emit,
  ) async {
    emit(const ClientProjectOffersLoadInProgress());

    final projectResult = await _getProjectById(event.projectId);
    switch (projectResult) {
      case Failed(:final failure):
        emit(ClientProjectOffersLoadFailure(failure));
        return;
      case Success(data: final project):
        final offersResult = await _getProjectOffers(event.projectId);
        switch (offersResult) {
          case Failed(:final failure):
            emit(ClientProjectOffersLoadFailure(failure));
          case Success(data: final offers):
            emit(
              ClientProjectOffersLoadSuccess(project: project, offers: offers),
            );
        }
    }
  }

  Future<void> _onOfferAccepted(
    ClientProjectOfferAccepted event,
    Emitter<ClientProjectOffersState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ClientProjectOffersLoadSuccess) return;

    final result = await _acceptOffer((
      offerId: event.offerId,
      expectedAmount: event.expectedAmount,
    ));

    switch (result) {
      case Success():
        emit(currentState.copyWith(acceptedOfferId: event.offerId));
      case Failed(:final failure):
        emit(ClientProjectOffersLoadFailure(failure));
    }
  }
}
