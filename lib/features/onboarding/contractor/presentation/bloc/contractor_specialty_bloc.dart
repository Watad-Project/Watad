import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/onboarding/contractor/domain/usecases/contractor_save_specialty_use_case.dart';

part 'contractor_specialty_event.dart';
part 'contractor_specialty_state.dart';

class ContractorSpecialtyBloc
    extends Bloc<ContractorSpecialtyEvent, ContractorSpecialtyState> {
  ContractorSpecialtyBloc(this._saveSpecialty)
    : super(const ContractorSpecialtyInitial()) {
    on<ContractorSpecialtySelected>(_onSelected);
    on<ContractorSpecialtySaved>(_onSaved);
  }

  final ContractorSaveSpecialtyUseCase _saveSpecialty;

  void _onSelected(
    ContractorSpecialtySelected event,
    Emitter<ContractorSpecialtyState> emit,
  ) {
    emit(ContractorSpecialtyInitial(selectedSpecialty: event.specialty));
  }

  Future<void> _onSaved(
    ContractorSpecialtySaved event,
    Emitter<ContractorSpecialtyState> emit,
  ) async {
    emit(ContractorSpecialtySaveInProgress(selectedSpecialty: event.specialty));
    final result = await _saveSpecialty(event.specialty);
    switch (result) {
      case Success():
        emit(ContractorSpecialtySaveSuccess(specialty: event.specialty));
      case Failed(:final failure):
        emit(
          ContractorSpecialtySaveFailure(
            failure: failure,
            selectedSpecialty: event.specialty,
          ),
        );
    }
  }
}
