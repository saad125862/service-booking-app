import '../../booking/domain/payment_link.dart';

/// A service the assistant recommends (shown as a tappable card under its reply).
class RecommendedService {
  const RecommendedService({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.durationMinutes,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final int durationMinutes;
  final String? imageUrl;

  factory RecommendedService.fromJson(Map<String, dynamic> json) => RecommendedService(
    id: json['id'] as String,
    name: json['name'] as String,
    category: json['category'] as String,
    price: (json['price'] as num).toDouble(),
    durationMinutes: (json['durationMinutes'] as num).toInt(),
    imageUrl: json['imageUrl'] as String?,
  );
}

/// What the server returns for one chat turn.
class ChatReply {
  const ChatReply({
    required this.reply,
    required this.language,
    this.recommended = const [],
    this.discountRequestId,
    this.paymentLink,
  });

  final String reply;

  /// en | bn | banglish
  final String language;
  final List<RecommendedService> recommended;

  /// Set when the customer asked for a discount: the assistant filed a request and an admin decides.
  final String? discountRequestId;

  /// Set when the customer asked to pay: a gateway checkout for the exact booking amount.
  final PaymentLink? paymentLink;

  factory ChatReply.fromJson(Map<String, dynamic> json) {
    final discount = json['discountRequest'] as Map<String, dynamic>?;
    return ChatReply(
      reply: json['reply'] as String,
      language: json['language'] as String? ?? 'en',
      recommended: [
        for (final s in (json['recommendedServices'] as List? ?? const []))
          RecommendedService.fromJson(s as Map<String, dynamic>),
      ],
      discountRequestId: discount?['id'] as String?,
      paymentLink: json['paymentLink'] == null
          ? null
          : PaymentLink.fromJson(json['paymentLink'] as Map<String, dynamic>),
    );
  }
}

enum ChatRole { user, assistant }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.recommended = const [],
    this.discountRequestId,
    this.paymentLink,
    this.isError = false,
    this.isGreeting = false,
  });

  final int id;
  final ChatRole role;
  final String text;
  final List<RecommendedService> recommended;

  /// The discount request this message started; its decision is shown inline when it arrives.
  final String? discountRequestId;

  /// A payment link the assistant made for one of the customer's bookings.
  final PaymentLink? paymentLink;
  final bool isError;
  final bool isGreeting;

  bool get isUser => role == ChatRole.user;
}
