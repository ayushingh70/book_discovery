class FilterOptions {
  final String? category;
  final String? orderBy;
  final bool onlyFree;
  final bool onlyPaid;
  final double? priceMin;
  final double? priceMax;

  const FilterOptions({
    this.category,
    this.orderBy,
    this.onlyFree = false,
    this.onlyPaid = false,
    this.priceMin,
    this.priceMax,
  });

  FilterOptions copyWith({
    String? category,
    String? orderBy,
    bool? onlyFree,
    bool? onlyPaid,
    double? priceMin,
    double? priceMax,
  }) {
    return FilterOptions(
      category: category ?? this.category,
      orderBy: orderBy ?? this.orderBy,
      onlyFree: onlyFree ?? this.onlyFree,
      onlyPaid: onlyPaid ?? this.onlyPaid,
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
    );
  }

  static const empty = FilterOptions();
}