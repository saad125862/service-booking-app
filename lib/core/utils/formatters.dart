import 'package:intl/intl.dart';

class Formatters {
  const Formatters._();

  /// 60 -> "$60", 45.5 -> "$45.50".
  static String price(num value) {
    final whole = value == value.roundToDouble();
    return NumberFormat.currency(symbol: r'$', decimalDigits: whole ? 0 : 2).format(value);
  }

  /// 45 -> "45 min", 60 -> "1 h", 90 -> "1 h 30 min".
  static String duration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h h' : '$h h $m min';
  }

  /// "Fri, Nov 20, 2026" style date.
  static String date(DateTime value) => DateFormat('EEE, MMM d, y').format(value);
}
