import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_contract_project.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_open_project.dart';
import 'package:watad/features/work/contractor/presentation/bloc/contractor_work_bloc.dart';
import 'package:watad/features/work/contractor/presentation/pages/contractor_work_page.dart';

/// The contractor's work tab displayed in the bottom navigation.
class ContractorWorkTab extends StatefulWidget {
  const ContractorWorkTab({
    required this.bloc,
    this.onSubmitOffer,
    this.onPendingOfferTap,
    this.onContractTap,
    super.key,
  });

  final ContractorWorkBloc bloc;
  final ValueChanged<ContractorOpenProject>? onSubmitOffer;
  final ValueChanged<ContractorOpenProject>? onPendingOfferTap;
  final ValueChanged<ContractorContractProject>? onContractTap;

  @override
  State<ContractorWorkTab> createState() => _ContractorWorkTabState();
}

class _ContractorWorkTabState extends State<ContractorWorkTab> {
  @override
  void dispose() {
    widget.bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.bloc,
      child: ContractorWorkPage(
        onSubmitOffer: widget.onSubmitOffer,
        onPendingOfferTap: widget.onPendingOfferTap,
        onContractTap: widget.onContractTap,
      ),
    );
  }
}
