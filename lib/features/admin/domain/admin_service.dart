/// Types of custom field an admin can add to the service form.
enum FieldType {
  text('Short text'),
  textarea('Long text'),
  number('Number'),
  boolean('Yes / No'),
  select('Dropdown');

  const FieldType(this.label);
  final String label;

  static FieldType parse(String value) =>
      FieldType.values.firstWhere((t) => t.name == value, orElse: () => FieldType.text);
}

/// Definition of one extra field on the add / edit service form.
class ServiceField {
  const ServiceField({
    required this.id,
    required this.key,
    required this.label,
    required this.type,
    this.options = const [],
    this.required = false,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String id;
  final String key;
  final String label;
  final FieldType type;

  /// Allowed values of a dropdown.
  final List<String> options;
  final bool required;
  final int sortOrder;
  final bool isActive;

  factory ServiceField.fromJson(Map<String, dynamic> json) => ServiceField(
    id: json['id'] as String,
    key: json['key'] as String,
    label: json['label'] as String,
    type: FieldType.parse(json['type'] as String),
    options: [for (final o in (json['options'] as List? ?? const [])) '$o'],
    required: json['required'] as bool? ?? false,
    sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    isActive: json['isActive'] as bool? ?? true,
  );
}

/// A service as admins see it, including hidden ones and the raw custom-field values.
class AdminService {
  const AdminService({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.category,
    required this.isFeatured,
    required this.isActive,
    this.imageUrl,
    this.bookingsCount = 0,
    this.attributeValues = const {},
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final int durationMinutes;
  final String category;
  final bool isFeatured;
  final bool isActive;
  final String? imageUrl;
  final int bookingsCount;

  /// Values of the custom fields, keyed by field key.
  final Map<String, dynamic> attributeValues;

  factory AdminService.fromJson(Map<String, dynamic> json) => AdminService(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    price: (json['price'] as num).toDouble(),
    durationMinutes: (json['durationMinutes'] as num).toInt(),
    category: json['category'] as String,
    isFeatured: json['isFeatured'] as bool? ?? false,
    isActive: json['isActive'] as bool? ?? true,
    imageUrl: json['imageUrl'] as String?,
    bookingsCount: (json['bookingsCount'] as num?)?.toInt() ?? 0,
    attributeValues: Map<String, dynamic>.from(json['attributeValues'] as Map? ?? const {}),
  );
}
