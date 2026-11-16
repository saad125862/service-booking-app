class Service {
  const Service({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.category,
    this.imageUrl,
    this.isFeatured = false,
    this.bookingsCount = 0,
    this.attributes = const [],
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final int durationMinutes;
  final String category;
  final String? imageUrl;
  final bool isFeatured;

  /// How many times the service has been booked (used for "popular").
  final int bookingsCount;

  /// Values of the admin-defined custom fields (only on the details response).
  final List<ServiceAttribute> attributes;

  factory Service.fromJson(Map<String, dynamic> json) => Service(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    price: (json['price'] as num).toDouble(),
    durationMinutes: json['durationMinutes'] as int,
    category: json['category'] as String,
    imageUrl: json['imageUrl'] as String?,
    isFeatured: json['isFeatured'] as bool? ?? false,
    bookingsCount: (json['bookingsCount'] as num?)?.toInt() ?? 0,
    attributes: [
      for (final a in (json['attributes'] as List? ?? const [])) ServiceAttribute.fromJson(a as Map<String, dynamic>),
    ],
  );
}

/// One "extra detail" of a service, e.g. Specialist level: Senior specialist.
class ServiceAttribute {
  const ServiceAttribute({required this.key, required this.label, required this.type, required this.value});

  final String key;
  final String label;
  final String type;
  final Object? value;

  /// Text to show: booleans as Yes / No, numbers without a trailing .0.
  String get display {
    final v = value;
    if (v is bool) return v ? 'Yes' : 'No';
    if (v is num) return v % 1 == 0 ? v.toInt().toString() : v.toString();
    return '$v';
  }

  bool get isLong => type == 'textarea';

  factory ServiceAttribute.fromJson(Map<String, dynamic> json) => ServiceAttribute(
    key: json['key'] as String,
    label: json['label'] as String,
    type: json['type'] as String? ?? 'text',
    value: json['value'],
  );
}

class ServiceCategory {
  const ServiceCategory({required this.name, required this.count});

  final String name;
  final int count;

  factory ServiceCategory.fromJson(Map<String, dynamic> json) =>
      ServiceCategory(name: json['name'] as String, count: (json['count'] as num).toInt());
}

/// One page of a paginated list.
class ServicePage {
  const ServicePage({required this.items, required this.page, required this.totalPages, required this.total});

  final List<Service> items;
  final int page;
  final int totalPages;
  final int total;

  bool get hasMore => page < totalPages;
}
