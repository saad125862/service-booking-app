/// A gateway checkout the customer opens to pay a booking online.
class PaymentLink {
  const PaymentLink({
    required this.url,
    required this.amount,
    required this.providerName,
    this.appointmentId,
    this.serviceName,
    this.startLabel,
  });

  final String url;

  /// Exactly the booking price in BDT.
  final double amount;
  final String providerName;
  final String? appointmentId;
  final String? serviceName;
  final String? startLabel;

  factory PaymentLink.fromJson(Map<String, dynamic> json) => PaymentLink(
    url: json['url'] as String,
    amount: (json['amount'] as num).toDouble(),
    providerName: json['providerName'] as String? ?? 'the payment gateway',
    appointmentId: json['appointmentId'] as String?,
    serviceName: json['serviceName'] as String?,
    startLabel: json['startLabel'] as String?,
  );
}
