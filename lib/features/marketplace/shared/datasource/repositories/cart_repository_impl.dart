import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/marketplace/shared/datasource/local/cart_local_data_source.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_line.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/cart_repository.dart';

class CartRepositoryImpl implements CartRepository {
  const CartRepositoryImpl(this._local);

  final CartLocalDataSource _local;

  @override
  Future<Result<List<CartLine>>> getLines() =>
      guardSupabaseCall(_local.getLines);

  @override
  Future<Result<void>> saveLines(List<CartLine> lines) =>
      guardSupabaseCall(() => _local.saveLines(lines));
}
