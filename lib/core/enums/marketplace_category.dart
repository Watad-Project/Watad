/// Mirror of the Postgres enum `marketplace_category` (ARCHITECTURE.md §4):
/// what kind of item a marketplace listing is. New listings are [other]
/// until the seller picks one.
enum MarketplaceCategory {
  buildingMaterials('building_materials'),
  steelMetals('steel_metals'),
  wood('wood'),
  toolsEquipment('tools_equipment'),
  electricalLighting('electrical_lighting'),
  plumbingSanitary('plumbing_sanitary'),
  paints('paints'),
  insulation('insulation'),
  flooringTiles('flooring_tiles'),
  doorsWindows('doors_windows'),
  hvac('hvac'),
  safety('safety'),
  outdoor('outdoor'),
  other('other');

  const MarketplaceCategory(this.value);

  /// The exact value stored in Postgres.
  final String value;

  /// Throws on an unknown value: never guess a category.
  static MarketplaceCategory fromJson(String value) =>
      values.firstWhere((category) => category.value == value);

  String toJson() => value;
}
