import 'package:flutter/material.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.appointmentId,
    this.discountRequestId,
  });

  final String id;

  /// booking_created, booking_confirmed, booking_completed, booking_cancelled, booking_new,
  /// payment_verified, payment_failed, discount_request, discount_approved, discount_declined
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final String? appointmentId;
  final String? discountRequestId;

  IconData get icon => switch (type) {
        'booking_created' || 'booking_new' => Icons.event_available_outlined,
        'booking_confirmed' => Icons.check_circle_outline,
        'booking_completed' => Icons.task_alt,
        'booking_cancelled' => Icons.event_busy_outlined,
        'payment_verified' => Icons.verified_outlined,
        'payment_failed' => Icons.error_outline,
        'discount_request' || 'discount_approved' || 'discount_declined' => Icons.local_offer_outlined,
        _ => Icons.notifications_outlined,
      };

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        appointmentId: appointmentId,
        discountRequestId: discountRequestId,
      );

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return AppNotification(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      appointmentId: data?['appointmentId'] as String?,
      discountRequestId: data?['discountRequestId'] as String?,
    );
  }
}
