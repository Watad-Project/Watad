import 'package:watad/core/utils/money.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_open_project.dart';

/// Project work type filter for contractor opportunities.
enum ContractorWorkType {
  foundation([
    '\u062a\u0623\u0633\u064a\u0633',
    '\u062a\u0627\u0633\u064a\u0633',
    '\u0633\u0628\u0627\u0643\u0629',
    '\u0643\u0647\u0631\u0628\u0627\u0621',
    '\u062a\u0645\u062f\u064a\u062f',
    '\u0642\u0648\u0627\u0639\u062f',
    '\u062e\u0631\u0633\u0627\u0646\u0629',
    'foundation',
  ]),
  building([
    '\u0628\u0646\u0627\u0621',
    '\u0639\u0638\u0645',
    '\u0641\u064a\u0644\u0627',
    '\u0645\u0644\u062d\u0642',
    '\u0639\u0645\u0627\u0631\u0629',
    '\u062f\u0648\u0631',
    'building',
    'build',
    'construction',
  ]),
  renovation([
    '\u062a\u0631\u0645\u064a\u0645',
    '\u062a\u0634\u0637\u064a\u0628',
    '\u062a\u062d\u062f\u064a\u062b',
    '\u0648\u0627\u062c\u0647\u0629',
    '\u062f\u0647\u0627\u0646',
    'renovation',
    'remodel',
  ]),
  repairs([
    '\u0625\u0635\u0644\u0627\u062d',
    '\u0627\u0635\u0644\u0627\u062d',
    '\u0635\u064a\u0627\u0646\u0629',
    '\u062a\u0633\u0631\u064a\u0628',
    '\u0639\u0632\u0644',
    '\u0633\u0628\u0627\u0643\u0629',
    '\u0643\u0647\u0631\u0628\u0627\u0621',
    'repairs',
    'repair',
    'fix',
  ]);

  const ContractorWorkType(this.keywords);

  final List<String> keywords;

  bool matchesText(String text) {
    final normalized = text.toLowerCase();
    return keywords.any(normalized.contains);
  }
}

/// Sorting options for contractor opportunities.
enum ContractorWorkSortBy { newest, highestBudget, nearestDistance }

/// Search and filter criteria for contractor opportunities (`v_open_projects`).
class ContractorWorkFilter {
  const ContractorWorkFilter({
    this.searchQuery = '',
    this.projectType,
    this.city = '',
    this.district = '',
    this.minBudget,
    this.sortBy = ContractorWorkSortBy.newest,
    this.zeroOffersOnly = false,
  });

  final String searchQuery;
  final ContractorWorkType? projectType;
  final String city;
  final String district;
  final Money? minBudget;
  final ContractorWorkSortBy sortBy;
  final bool zeroOffersOnly;

  bool get hasActiveFilters =>
      projectType != null ||
      city.trim().isNotEmpty ||
      district.trim().isNotEmpty ||
      (minBudget != null && minBudget! > const Money.zero()) ||
      sortBy != ContractorWorkSortBy.newest ||
      zeroOffersOnly;

  int get activeFilterCount {
    var count = 0;
    if (projectType != null) count++;
    if (city.trim().isNotEmpty || district.trim().isNotEmpty) count++;
    if ((minBudget != null && minBudget! > const Money.zero()) ||
        sortBy == ContractorWorkSortBy.highestBudget) {
      count++;
    }
    if (sortBy == ContractorWorkSortBy.nearestDistance) count++;
    if (zeroOffersOnly) count++;
    return count;
  }

  ContractorWorkFilter copyWith({
    String? searchQuery,
    ContractorWorkType? projectType,
    bool clearProjectType = false,
    String? city,
    String? district,
    Money? minBudget,
    bool clearMinBudget = false,
    ContractorWorkSortBy? sortBy,
    bool? zeroOffersOnly,
  }) {
    return ContractorWorkFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      projectType: clearProjectType ? null : (projectType ?? this.projectType),
      city: city ?? this.city,
      district: district ?? this.district,
      minBudget: clearMinBudget ? null : (minBudget ?? this.minBudget),
      sortBy: sortBy ?? this.sortBy,
      zeroOffersOnly: zeroOffersOnly ?? this.zeroOffersOnly,
    );
  }

  /// Filters and sorts [projects] according to this filter's criteria.
  List<ContractorOpenProject> apply(List<ContractorOpenProject> projects) {
    final trimmedQuery = searchQuery.trim().toLowerCase();
    final trimmedCity = city.trim().toLowerCase();
    final trimmedDistrict = district.trim().toLowerCase();
    final minBudgetHalalas = minBudget?.halalas ?? 0;

    final filtered = projects.where((project) {
      if (project.isMine) return false;

      if (trimmedQuery.isNotEmpty) {
        final searchable = [
          project.title,
          project.description,
          project.city,
          project.district ?? '',
          project.ownerName,
        ].join(' ').toLowerCase();
        if (!searchable.contains(trimmedQuery)) return false;
      }

      if (projectType case final type?) {
        final combined = '${project.title} ${project.description}';
        if (!type.matchesText(combined)) return false;
      }

      if (trimmedCity.isNotEmpty &&
          !project.city.toLowerCase().contains(trimmedCity)) {
        return false;
      }

      if (trimmedDistrict.isNotEmpty &&
          !(project.district ?? '').toLowerCase().contains(trimmedDistrict)) {
        return false;
      }

      if (minBudgetHalalas > 0) {
        final projectHalalas = project.budget?.halalas ?? 0;
        if (projectHalalas < minBudgetHalalas) return false;
      }

      if (zeroOffersOnly && project.offerCount > 0) {
        return false;
      }

      return true;
    }).toList();

    switch (sortBy) {
      case ContractorWorkSortBy.newest:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ContractorWorkSortBy.highestBudget:
        filtered.sort((a, b) {
          final aHalalas = a.budget?.halalas ?? -1;
          final bHalalas = b.budget?.halalas ?? -1;
          final cmp = bHalalas.compareTo(aHalalas);
          return cmp != 0 ? cmp : b.createdAt.compareTo(a.createdAt);
        });
      case ContractorWorkSortBy.nearestDistance:
        filtered.sort((a, b) {
          final cityCmp = a.city.compareTo(b.city);
          if (cityCmp != 0) return cityCmp;
          final distCmp = (a.district ?? '').compareTo(b.district ?? '');
          return distCmp != 0 ? distCmp : b.createdAt.compareTo(a.createdAt);
        });
    }

    return List<ContractorOpenProject>.unmodifiable(filtered);
  }
}
