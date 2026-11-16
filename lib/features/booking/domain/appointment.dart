import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'payment_method.dart';

enum AppointmentStatus {
  pending('Pending', Icons.hourglass_top_rounded),
  confirmed('Confirmed', Icons.check_circle_outline),
  cancelled('Cancelled', Icons.cancel_outlined),
  completed('Completed', Icons.task_alt);

  const AppointmentStatus(this.label, this.icon);
  final String label;
  final IconData icon;

  /// Accent colour used by chips and cards.
  Color get color => switch (this) {
    AppointmentStatus.pending => AppColors.warning,
    AppointmentStatus.confirmed => AppColors.success,
    AppointmentStatus.cancelled => const Color(0xFFC92A2A),
    AppointmentStatus.completed => AppColors.info,
  };

  static AppointmentStatus parse(String value) =>
      AppointmentStatus.values.firstWhere((s) => s.name == value, orElse: () => AppointmentStatus.pending);
}

/// The service part embedded in an appointment.
class AppointmentService {
  const AppointmentService({
    required this.id,
    required this.name,
    required this.price,
    required this.durationMinutes,
    required this.category,
    this.imageUrl,
  });

  final String id;
  final String name;
  final double price;
  final int durationMinutes;
  final String category;
  final String? imageUrl;

  factory AppointmentService.fromJson(Map<String, dynamic> json) => AppointmentService(
    id: json['id'] as String,
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(),
    durationMinutes: json['durationMinutes'] as int,
    category: json['category'] as String,
    imageUrl: json['imageUrl'] as String?,
  );
}

/// The customer behind a booking (admin views only).
class AppointmentCustomer {
  const AppointmentCustomer({required this.id, required this.name, required this.email, this.phone});

  final String id;
  final String name;
  final String email;
  final String? phone;

  factory AppointmentCustomer.fromJson(Map<String, dynamic> json) => AppointmentCustomer(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String?,
  );
}

class Appointment {
  const Appointment({
    required this.id,
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.startLabel,
    required this.service,
    this.address,
    this.notes,
    this.createdAt,
    this.price = 0,
    this.originalPrice = 0,
    this.discountAmount = 0,
    this.paymentStatus = PaymentStatus.unpaid,
    this.paymentReference,
    this.paidAt,
    this.paymentMethod,
    this.canPayOnline = false,
    this.customer,
  });

  final String id;
  final AppointmentStatus status;
  final DateTime startTime;
  final DateTime endTime;

  /// Start time already formatted by the server in the business time zone,
  /// e.g. "Fri, Nov 20, 2026, 10:00 AM", so every device shows the same time.
  final String startLabel;
  final AppointmentService service;

  /// Where the service takes place (null for bookings made before addresses existed).
  final String? address;
  final String? notes;
  final DateTime? createdAt;

  /// Price snapshot taken when the booking was made, in BDT: what to pay, the list price
  /// and the discount that was applied.
  final double price;
  final double originalPrice;
  final double discountAmount;
  final PaymentStatus paymentStatus;
  final String? paymentReference;
  final DateTime? paidAt;
  final PaymentMethod? paymentMethod;

  /// An online payment link can still be created for this booking.
  final bool canPayOnline;

  /// Set only in admin responses.
  final AppointmentCustomer? customer;

  bool get hasDiscount => discountAmount > 0;

  /// What the customer pays. Bookings made before prices were snapshotted fall back to the service price.
  double get amount => price > 0 ? price : service.price;

  bool get isPending => status == AppointmentStatus.pending;

  /// Short reference shown to the user.
  String get reference => (id.length > 8 ? id.substring(0, 8) : id).toUpperCase();

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: json['id'] as String,
    status: AppointmentStatus.parse(json['status'] as String),
    startTime: DateTime.parse(json['startTime'] as String),
    endTime: DateTime.parse(json['endTime'] as String),
    startLabel: json['startLabel'] as String,
    address: json['address'] as String?,
    notes: json['notes'] as String?,
    createdAt: json['createdAt'] == null ? null : DateTime.parse(json['createdAt'] as String),
    service: AppointmentService.fromJson(json['service'] as Map<String, dynamic>),
    price: (json['price'] as num?)?.toDouble() ?? 0,
    originalPrice: (json['originalPrice'] as num?)?.toDouble() ?? 0,
    discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
    paymentStatus: PaymentStatus.parse(json['paymentStatus'] as String? ?? 'unpaid'),
    paymentReference: json['paymentReference'] as String?,
    paidAt: json['paidAt'] == null ? null : DateTime.parse(json['paidAt'] as String),
    paymentMethod: json['paymentMethod'] == null
        ? null
        : PaymentMethod.fromJson(json['paymentMethod'] as Map<String, dynamic>),
    canPayOnline: json['canPayOnline'] as bool? ?? false,
    customer: json['customer'] == null ? null : AppointmentCustomer.fromJson(json['customer'] as Map<String, dynamic>),
  );
}
