import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/projects/client/domain/entities/client_accept_offer_params.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_offer.dart';
import 'package:watad/features/projects/client/domain/usecases/client_accept_offer_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_project_offers_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_project_use_case.dart';

part 'client_project_offers_event.dart';
part 'client_project_offers_state.dart';

/// «العروض الواردة»: one project's offers, and accepting one.
class ClientProjectOffersBloc
    extends Bloc<ClientProjectOffersEvent, ClientProjectOffersState> {
  ClientProjectOffersBloc(this._getProject, this._getOffers, this._accept)
    : super(const ClientProjectOffersState()) {
    on<ClientProjectOffersFetched>(_onFetched);
    on<ClientProjectOfferAccepted>(_onAccepted);
  }

  final ClientGetProjectUseCase _getProject;
  final ClientGetProjectOffersUseCase _getOffers;
  final ClientAcceptOfferUseCase _accept;

  Future<void> _onFetched(
    ClientProjectOffersFetched event,
    Emitter<ClientProjectOffersState> emit,
  ) async {
    emit(state.copyWith(status: ClientProjectOffersStatus.loading));
    await _load(event.projectId, emit);
  }

  Future<void> _onAccepted(
    ClientProjectOfferAccepted event,
    Emitter<ClientProjectOffersState> emit,
  ) async {
    if (state.acceptingOfferId != null) return;
    final offer = event.offer;
    emit(state.copyWith(acceptingOfferId: () => offer.id));
    final result = await _accept(
      ClientAcceptOfferParams(offerId: offer.id, expectedAmount: offer.amount),
    );
    // Read again either way: the server decides what changed.
    await _load(offer.projectId, emit);
    emit(
      state.copyWith(
        acceptingOfferId: () => null,
        message: () => switch (result) {
          Success() => const ClientProjectOffersMessage(
            'projects.offer_accepted',
            isError: false,
          ),
          Failed(:final failure) => ClientProjectOffersMessage(
            failure.messageKey,
            isError: true,
          ),
        },
      ),
    );
  }

  Future<void> _load(
    String projectId,
    Emitter<ClientProjectOffersState> emit,
  ) async {
    final (project, offers) = await (
      _getProject(projectId),
      _getOffers(projectId),
    ).wait;
    switch ((project, offers)) {
      case (Success(data: final p), Success(data: final o)):
        emit(
          state.copyWith(
            status: ClientProjectOffersStatus.success,
            project: p,
            offers: o,
            failure: () => null,
          ),
        );
      case (Failed(:final failure), _) || (_, Failed(:final failure)):
        emit(
          state.copyWith(
            status: ClientProjectOffersStatus.failure,
            failure: () => failure,
          ),
        );
    }
  }
}
