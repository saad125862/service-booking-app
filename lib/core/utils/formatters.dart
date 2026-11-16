import 'package:intl/intl.dart';

class Formatters {
  const Formatters._();

  /// Prices are in Bangladeshi taka (BDT): 2500 -> "৳2,500", 45.5 -> "৳45.50".
  static String price(num value) {
    final whole = value == value.roundToDouble();
    return NumberFormat.currency(locale: 'en_US', symbol: '৳', decimalDigits: whole ? 0 : 2).format(value);
  }

  /// 45 -> "45 min", 60 -> "1 h", 90 -> "1 h 30 min".
  static String duration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h h' : '$h h $m min';
  }

  /// "just now", "5 min ago", "2 h ago", "3 days ago", then the date.
  static String timeAgo(DateTime time, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    return DateFormat('MMM d, y').format(time);
  }

  /// "Fri, Nov 20, 2026" style date.
  static String date(DateTime value) => DateFormat('EEE, MMM d, y').format(value);
}
