import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

enum PaymentType {
  cash('Cash', Icons.payments_outlined),
  card('Card', Icons.credit_card),
  mobileWallet('Mobile wallet', Icons.phone_android),
  bank('Bank transfer', Icons.account_balance_outlined);

  const PaymentType(this.label, this.icon);
  final String label;
  final IconData icon;

  /// The API value (`mobile_wallet`).
  String get apiValue => switch (this) {
        PaymentType.mobileWallet => 'mobile_wallet',
        _ => name,
      };

  static PaymentType parse(String value) => PaymentType.values.firstWhere(
        (t) => t.apiValue == value,
        orElse: () => PaymentType.cash,
      );
}

enum PaymentStatus {
  unpaid('Unpaid', Icons.payments_outlined),
  submitted('Awaiting verification', Icons.hourglass_top_rounded),
  paid('Paid', Icons.verified_outlined),
  failed('Payment failed', Icons.error_outline);

  const PaymentStatus(this.label, this.icon);
  final String label;
  final IconData icon;

  Color get color => switch (this) {
        PaymentStatus.unpaid => const Color(0xFF868E96),
        PaymentStatus.submitted => AppColors.warning,
        PaymentStatus.paid => AppColors.success,
        PaymentStatus.failed => const Color(0xFFC92A2A),
      };

  static PaymentStatus parse(String value) =>
      PaymentStatus.values.firstWhere((s) => s.name == value, orElse: () => PaymentStatus.unpaid);
}

/// A payment option an admin offers (cash, card, bKash, Nagad, ...).
class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    this.instructions,
    this.accountNumber,
    this.requiresReference = false,
    this.isActive = true,
    this.sortOrder = 0,
  });

  final String id;
  final String code;
  final String name;
  final PaymentType type;
  final String? instructions;
  final String? accountNumber;

  /// Wallet-style methods need the customer's transaction ID.
  final bool requiresReference;
  final bool isActive;
  final int sortOrder;

  factory PaymentMethod.fromJson(Map<String, dynamic> json) => PaymentMethod(
        id: json['id'] as String,
        code: json['code'] as String,
        name: json['name'] as String,
        type: PaymentType.parse(json['type'] as String),
        instructions: json['instructions'] as String?,
        accountNumber: json['accountNumber'] as String?,
        requiresReference: json['requiresReference'] as bool? ?? false,
        isActive: json['isActive'] as bool? ?? true,
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      );
}
