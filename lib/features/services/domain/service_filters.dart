enum ServiceSort {
  featured('featured', 'Recommended'),
  popular('popular', 'Most popular'),
  priceAsc('price_asc', 'Price: low to high'),
  priceDesc('price_desc', 'Price: high to low'),
  name('name', 'Name: A to Z'),
  newest('newest', 'Newest');

  const ServiceSort(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

/// Highest price (in BDT) the filter slider offers; a maxPrice at this value means "no limit".
const double kPriceFilterCeiling = 20000;

/// Immutable search/filter state for the services list.
class ServiceFilters {
  const ServiceFilters({
    this.search = '',
    this.category,
    this.sort = ServiceSort.featured,
    this.minPrice,
    this.maxPrice,
  });

  final String search;
  final String? category;
  final ServiceSort sort;
  final double? minPrice;
  final double? maxPrice;

  bool get hasPriceFilter => minPrice != null || maxPrice != null;

  /// True when anything narrows or reorders the default list.
  bool get isActive =>
      search.trim().isNotEmpty || category != null || sort != ServiceSort.featured || hasPriceFilter;

  ServiceFilters copyWith({
    String? search,
    String? Function()? category,
    ServiceSort? sort,
    double? Function()? minPrice,
    double? Function()? maxPrice,
  }) =>
      ServiceFilters(
        search: search ?? this.search,
        category: category != null ? category() : this.category,
        sort: sort ?? this.sort,
        minPrice: minPrice != null ? minPrice() : this.minPrice,
        maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
      );

  /// Query parameters understood by GET /services.
  Map<String, dynamic> toQuery() => {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (category != null) 'category': category,
        if (sort != ServiceSort.featured) 'sort': sort.apiValue,
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
      };

  @override
  bool operator ==(Object other) =>
      other is ServiceFilters &&
      other.search == search &&
      other.category == category &&
      other.sort == sort &&
      other.minPrice == minPrice &&
      other.maxPrice == maxPrice;

  @override
  int get hashCode => Object.hash(search, category, sort, minPrice, maxPrice);
}
