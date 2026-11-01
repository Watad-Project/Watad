import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/cart_repository.dart';

/// The number on the browse tab's cart icon: how many lines (different
/// items) the cart holds.
class GetCartCountUseCase implements UseCase<int, NoParams> {
  const GetCartCountUseCase(this._repository);

  final CartRepository _repository;

  @override
  Future<Result<int>> call([NoParams params = const NoParams()]) async {
    final result = await _repository.getLines();
    return switch (result) {
      Success(:final data) => Success(data.length),
      Failed(:final failure) => Failed(failure),
    };
  }
}
