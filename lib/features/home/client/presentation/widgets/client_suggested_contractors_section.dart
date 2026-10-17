import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_business_mini_card.dart';
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
          LayoutBuilder(
            builder: (context, constraints) {
              const horizontalPadding = AppSpacing.lg * 2;
              const spacing = AppSpacing.md;
              final cardWidth =
                  (constraints.maxWidth - horizontalPadding - spacing) / 2;

              return SizedBox(
                height: 155,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: contractors.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final contractor = contractors[index];
                      final isArabic = context.locale.languageCode == 'ar';
                      final ratingStr = contractor.rating.toStringAsFixed(1);
                      final countStr = contractor.completedProjectsCount
                          .toString();

                      return SizedBox(
                        width: cardWidth,
                        child: AppBusinessMiniCard(
                          name: contractor.companyName,
                          ratingLabel: _formatNumber(ratingStr, isArabic),
                          projectsLabel:
                              '\u200F${'home.projects_count'.tr(args: [_formatNumber(countStr, isArabic)])}',
                          isVerified: contractor.isVerified,
                          imageUrl: contractor.avatarPath,
                          onTap: () {},
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  static String _formatNumber(String input, bool isArabic) {
    if (!isArabic) return input;
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.'];
    const arabic = [
      '\u0660',
      '\u0661',
      '\u0662',
      '\u0663',
      '\u0664',
      '\u0665',
      '\u0666',
      '\u0667',
      '\u0668',
      '\u0669',
      '\u066B',
    ];
    var result = input;
    for (var i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], arabic[i]);
    }
    return result;
  }
}
