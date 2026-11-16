import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

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

class Appointment {
  const Appointment({
    required this.id,
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.startLabel,
    required this.service,
    this.notes,
    this.createdAt,
  });

  final String id;
  final AppointmentStatus status;
  final DateTime startTime;
  final DateTime endTime;

  /// Start time already formatted by the server in the business time zone,
  /// e.g. "Fri, Nov 20, 2026, 10:00 AM", so every device shows the same time.
  final String startLabel;
  final AppointmentService service;
  final String? notes;
  final DateTime? createdAt;

  bool get isPending => status == AppointmentStatus.pending;

  /// Short reference shown to the user.
  String get reference => id.substring(0, 8).toUpperCase();

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: json['id'] as String,
        status: AppointmentStatus.parse(json['status'] as String),
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        startLabel: json['startLabel'] as String,
        notes: json['notes'] as String?,
        createdAt: json['createdAt'] == null ? null : DateTime.parse(json['createdAt'] as String),
        service: AppointmentService.fromJson(json['service'] as Map<String, dynamic>),
      );
}
