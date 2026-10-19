import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:watad/core/components/display/app_business_mini_card.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/features/home/client/domain/entities/client_contractor.dart';

/// One contractor as a card: photo (or the default avatar), name with the
/// verified check, rating and completed projects («٤٫٨ · ٦٤ مشروعًا»), and
/// the city it works in. Used in «مقاولون مقترحون»
/// and in the «الكل» grid.
class ClientContractorCard extends StatelessWidget {
  const ClientContractorCard({required this.contractor, super.key});

  final ClientContractor contractor;

  /// The card's height in a row or a grid, at the phone's text size.
  static double heightOf(BuildContext context) =>
      AppBusinessMiniCard.heightOf(context, withLocation: true);

  @override
  Widget build(BuildContext context) {
    final rating = contractor.ratingAvg;
    final projects = contractor.completedProjectCount;
    return AppBusinessMiniCard(
      name: contractor.companyName,
      isVerified: true,
      imageUrl: contractor.avatarUrl,
      location: contractor.city ?? context.tr('home.city_unknown'),
      ratingLabel: rating == null
          ? '–'
          : context.formatNumber(rating, decimals: 1),
      projectsLabel: context.plural(
        'home.projects_count',
        projects,
        args: [context.formatNumber(projects)],
      ),
    );
  }
}
