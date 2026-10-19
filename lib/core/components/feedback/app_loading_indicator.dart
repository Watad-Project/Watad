import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';

/// The spinner shown while a page loads its data, centred in the space it
/// gets.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: context.tr('common.loading'),
        child: const CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}
