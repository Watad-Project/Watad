import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/home/client/domain/entities/client_suggested_contractor.dart';

class ClientSuggestedContractorsSection extends StatelessWidget {
  const ClientSuggestedContractorsSection({
    required this.contractors,
    this.onViewAllTap,
    super.key,
  });

  final List<ClientSuggestedContractor> contractors;
  final VoidCallback? onViewAllTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('home.suggested_contractors'.tr(), style: AppTextStyles.h2),
              InkWell(
                onTap: onViewAllTap,
                child: Text(
                  'home.view_all'.tr(),
                  style: AppTextStyles.label.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (contractors.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadius.md),
                ),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(
                  'home.no_contractors'.tr(),
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 165,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: contractors.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) {
                final contractor = contractors[index];
                return _ContractorCard(contractor: contractor);
              },
            ),
          ),
      ],
    );
  }
}

class _ContractorCard extends StatelessWidget {
  const _ContractorCard({required this.contractor});

  final ClientSuggestedContractor contractor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.neutralLight,
                child: Icon(
                  Icons.business,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (contractor.isVerified)
                const Icon(
                  Icons.check_circle,
                  size: 16,
                  color: AppColors.success,
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contractor.companyName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label,
              ),
              if (contractor.specializedField != null &&
                  contractor.specializedField!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  contractor.specializedField!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                ),
              ],
            ],
          ),
          Row(
            children: [
              const Icon(Icons.star, size: 14, color: AppColors.primary),
              const SizedBox(width: 2),
              Text(
                contractor.rating.toStringAsFixed(1),
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 4),
              const Text('·', style: AppTextStyles.caption),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'home.projects_count'.tr(
                    args: [contractor.completedProjectsCount.toString()],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
