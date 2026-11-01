import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/cart_count_bloc.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/marketplace_bloc.dart';
import 'package:watad/features/marketplace/shared/presentation/pages/marketplace_page.dart';

/// The «السوق» tab displayed in the client and contractor bottom navigation.
class MarketplaceTab extends StatefulWidget {
  const MarketplaceTab({
    required this.bloc,
    required this.cartCountBloc,
    this.onCartTap,
    this.onItemTap,
    super.key,
  });

  final MarketplaceBloc bloc;

  /// The number on the cart icon.
  final CartCountBloc cartCountBloc;

  final VoidCallback? onCartTap;
  final ValueChanged<MarketplaceItem>? onItemTap;

  @override
  State<MarketplaceTab> createState() => _MarketplaceTabState();
}

class _MarketplaceTabState extends State<MarketplaceTab> {
  @override
  void dispose() {
    widget.bloc.close();
    widget.cartCountBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.bloc,
      child: BlocProvider.value(
        value: widget.cartCountBloc,
        child: MarketplacePage(
          onCartTap: widget.onCartTap,
          onItemTap: widget.onItemTap,
        ),
      ),
    );
  }
}
