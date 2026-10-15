/// An amount in SAR, kept as halalas (1 SAR = 100 halalas) so sums never
/// drift. Postgres stores it as `numeric` with at most 2 decimals.
final class Money implements Comparable<Money> {
  const Money.halalas(this.halalas);

  /// Parses a `numeric` value as Supabase sends it.
  factory Money.fromJson(num value) => Money.halalas((value * 100).round());

  final int halalas;

  /// The value to send to a `numeric` column or an RPC parameter.
  num toJson() => halalas / 100;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money &&
          runtimeType == other.runtimeType &&
          halalas == other.halalas;

  @override
  int get hashCode => halalas.hashCode;

  @override
  int compareTo(Money other) => halalas.compareTo(other.halalas);

  bool operator <(Money other) => halalas < other.halalas;
  bool operator <=(Money other) => halalas <= other.halalas;
  bool operator >(Money other) => halalas > other.halalas;
  bool operator >=(Money other) => halalas >= other.halalas;

  Money operator +(Money other) => Money.halalas(halalas + other.halalas);
  Money operator -(Money other) => Money.halalas(halalas - other.halalas);

  @override
  String toString() => (halalas / 100).toStringAsFixed(2);
}
