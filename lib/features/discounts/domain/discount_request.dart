import '../../../core/utils/formatters.dart';

/// A customer's discount request (made through the assistant) and the admin's decision.
class DiscountRequest {
  const DiscountRequest({
    required this.id,
    required this.status,
    required this.message,
    required this.language,
    required this.createdAt,
    this.serviceId,
    this.serviceName,
    this.servicePrice,
    this.discountType,
    this.discountValue,
    this.reply,
    this.expiresAt,
    this.decidedAt,
    this.adminNote,
    this.customerName,
    this.customerEmail,
  });

  final String id;

  /// pending | approved | declined | used | expired
  final String status;
  final String message;
  final String language;
  final DateTime createdAt;
  final String? serviceId;
  final String? serviceName;
  final double? servicePrice;
  final String? discountType;
  final double? discountValue;

  /// The assistant's answer to the customer once an admin decided.
  final String? reply;
  final DateTime? expiresAt;
  final DateTime? decidedAt;

  /// Admin-only fields.
  final String? adminNote;
  final String? customerName;
  final String? customerEmail;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';

  /// "15% off" or "৳300 off".
  String? get discountLabel {
    if (discountType == null || discountValue == null) return null;
    return discountType == 'percent'
        ? '${discountValue!.toStringAsFixed(discountValue! % 1 == 0 ? 0 : 1)}% off'
        : '${Formatters.price(discountValue!)} off';
  }

  /// Taka this discount would take off [price].
  double amountFor(double price) {
    if (discountType == null || discountValue == null) return 0;
    final raw = discountType == 'percent' ? price * discountValue! / 100 : discountValue!;
    final rounded = (raw * 100).round() / 100;
    return rounded > price ? price : rounded;
  }

  /// Can this (approved) discount apply to a booking of [forServiceId]?
  bool appliesTo(String forServiceId) =>
      isApproved && (serviceId == null || serviceId == forServiceId);

  factory DiscountRequest.fromJson(Map<String, dynamic> json) {
    final service = json['service'] as Map<String, dynamic>?;
    final customer = json['customer'] as Map<String, dynamic>?;
    return DiscountRequest(
      id: json['id'] as String,
      status: json['status'] as String,
      message: json['message'] as String? ?? '',
      language: json['language'] as String? ?? 'en',
      createdAt: DateTime.parse(json['createdAt'] as String),
      serviceId: service?['id'] as String?,
      serviceName: service?['name'] as String?,
      servicePrice: (service?['price'] as num?)?.toDouble(),
      discountType: json['discountType'] as String?,
      discountValue: (json['discountValue'] as num?)?.toDouble(),
      reply: json['reply'] as String?,
      expiresAt: json['expiresAt'] == null ? null : DateTime.parse(json['expiresAt'] as String),
      decidedAt: json['decidedAt'] == null ? null : DateTime.parse(json['decidedAt'] as String),
      adminNote: json['adminNote'] as String?,
      customerName: customer?['name'] as String?,
      customerEmail: customer?['email'] as String?,
    );
  }
}
