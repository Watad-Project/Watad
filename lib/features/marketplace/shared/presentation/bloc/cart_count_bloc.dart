import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_cart_count_use_case.dart';

part 'cart_count_event.dart';
part 'cart_count_state.dart';

/// The number on the browse tab's cart icon.
class CartCountBloc extends Bloc<CartCountEvent, CartCountState> {
  CartCountBloc(this._getCount) : super(const CartCountState()) {
    on<CartCountRefreshed>(_onRefreshed);
  }

  final GetCartCountUseCase _getCount;

  Future<void> _onRefreshed(
    CartCountRefreshed event,
    Emitter<CartCountState> emit,
  ) async {
    final result = await _getCount();
    switch (result) {
      case Success(:final data):
        emit(CartCountState(count: data));
      case Failed(:final failure):
        // The badge keeps its last number; the page says what went wrong.
        emit(CartCountState(count: state.count, failure: failure));
    }
  }
}
