import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/enums/marketplace_category.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item_draft.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/create_marketplace_item_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_my_marketplace_item_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/update_marketplace_item_use_case.dart';

part 'my_item_form_event.dart';
part 'my_item_form_state.dart';

/// Manages the add (`/marketplace/my-items/new`) and edit
/// (`/marketplace/my-items/:itemId/edit`) listing form.
class MyItemFormBloc extends Bloc<MyItemFormEvent, MyItemFormState> {
  MyItemFormBloc(this._getMyItem, this._createItem, this._updateItem)
    : super(const MyItemFormState()) {
    on<MyItemFormStarted>(_onStarted);
    on<MyItemFormNameChanged>(
      (event, emit) =>
          emit(state.copyWith(name: event.name, submitFailure: () => null)),
    );
    on<MyItemFormDescriptionChanged>(
      (event, emit) => emit(
        state.copyWith(
          description: event.description,
          submitFailure: () => null,
        ),
      ),
    );
    on<MyItemFormPriceChanged>(
      (event, emit) => emit(
        state.copyWith(priceText: event.priceText, submitFailure: () => null),
      ),
    );
    on<MyItemFormStockChanged>(
      (event, emit) => emit(
        state.copyWith(stockText: event.stockText, submitFailure: () => null),
      ),
    );
    on<MyItemFormCategoryChanged>(
      (event, emit) => emit(
        state.copyWith(
          category: () => event.category,
          submitFailure: () => null,
        ),
      ),
    );
    on<MyItemFormPhotoAdded>(_onPhotoAdded);
    on<MyItemFormPhotoRemoved>(_onPhotoRemoved);
    on<MyItemFormSubmitted>(_onSubmitted);
  }

  final GetMyMarketplaceItemUseCase _getMyItem;
  final CreateMarketplaceItemUseCase _createItem;
  final UpdateMarketplaceItemUseCase _updateItem;

  Future<void> _onStarted(
    MyItemFormStarted event,
    Emitter<MyItemFormState> emit,
  ) async {
    final id = event.itemId;
    if (id == null) {
      emit(const MyItemFormState(status: MyItemFormStatus.ready));
      return;
    }
    emit(
      state.copyWith(
        status: MyItemFormStatus.loading,
        itemId: () => id,
        loadFailure: () => null,
        submitFailure: () => null,
      ),
    );
    switch (await _getMyItem(id)) {
      case Success(:final data):
        emit(
          MyItemFormState(
            status: MyItemFormStatus.ready,
            itemId: data.id,
            name: data.name,
            description: data.description ?? '',
            priceText: _formatInitialMoney(data.price),
            stockText: data.stockQuantity.toString(),
            category: data.category,
            photos: List<String>.unmodifiable(data.photoPaths),
            isActive: data.isActive,
            removedAt: data.removedAt,
            removalReason: data.removalReason,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: MyItemFormStatus.failure,
            loadFailure: () => failure,
          ),
        );
    }
  }

  void _onPhotoAdded(
    MyItemFormPhotoAdded event,
    Emitter<MyItemFormState> emit,
  ) {
    if (state.isRemoved || state.photos.length >= MyItemFormState.maxPhotos) {
      return;
    }
    final path = event.path.trim();
    if (path.isEmpty) return;
    emit(
      state.copyWith(
        photos: List<String>.unmodifiable([...state.photos, path]),
        submitFailure: () => null,
      ),
    );
  }

  void _onPhotoRemoved(
    MyItemFormPhotoRemoved event,
    Emitter<MyItemFormState> emit,
  ) {
    if (state.isRemoved ||
        event.index < 0 ||
        event.index >= state.photos.length) {
      return;
    }
    final updated = [...state.photos]..removeAt(event.index);
    emit(
      state.copyWith(
        photos: List<String>.unmodifiable(updated),
        submitFailure: () => null,
      ),
    );
  }

  Future<void> _onSubmitted(
    MyItemFormSubmitted event,
    Emitter<MyItemFormState> emit,
  ) async {
    if (state.isRemoved || state.status == MyItemFormStatus.submitting) return;
    if (!state.isValid) {
      emit(state.copyWith(showValidationErrors: true));
      return;
    }

    emit(
      state.copyWith(
        status: MyItemFormStatus.submitting,
        showValidationErrors: true,
        submitFailure: () => null,
      ),
    );

    final trimmedDescription = state.description.trim();
    final draft = MarketplaceItemDraft(
      name: state.name.trim(),
      description: trimmedDescription.isEmpty ? null : trimmedDescription,
      price: state.parsedPrice!,
      stockQuantity: state.parsedStock!,
      category: state.category!,
      photos: state.photos,
      isActive: state.isActive,
    );

    final result = switch (state.itemId) {
      final id? => await _updateItem((itemId: id, draft: draft)),
      null => await _createItem(draft),
    };

    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(status: MyItemFormStatus.saved, savedItem: () => data),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: MyItemFormStatus.ready,
            submitFailure: () => failure,
          ),
        );
    }
  }

  static String _formatInitialMoney(Money money) {
    if (money.halalas % 100 == 0) {
      return (money.halalas ~/ 100).toString();
    }
    return (money.halalas / 100).toStringAsFixed(2);
  }
}
