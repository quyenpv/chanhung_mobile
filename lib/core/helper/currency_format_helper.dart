import 'package:intl/intl.dart';

class CurrencyFormatHelper {
  static String format(
    dynamic amount, {
    String? symbol,
    String? position,
    String? currencyCode,
  }) {
    final rawSymbol = (symbol ?? '').trim();
    final rawCode = (currencyCode ?? '').trim();
    final normalizedSymbol = rawSymbol.toLowerCase();
    final normalizedCode = rawCode.toLowerCase();
    final isVnd = normalizedSymbol == 'vnd' ||
        normalizedSymbol == 'vn\u0111' ||
        normalizedSymbol == '\u0111' ||
        normalizedSymbol == '\u20ab' ||
        normalizedCode == 'vnd';

    final number = _toDouble(amount);
    final text = number == null
        ? (amount?.toString() ?? '0')
        : NumberFormat('#,##0.##', isVnd ? 'vi_VN' : 'en_US').format(number);

    if (isVnd) {
      return '$text VN\u0110';
    }

    if (rawSymbol.isEmpty) {
      return text;
    }

    final normalizedPosition = (position ?? '').trim().toLowerCase();
    if (normalizedPosition == 'right' ||
        normalizedPosition == 'after' ||
        normalizedPosition == 'suffix') {
      return '$text $rawSymbol';
    }

    return '$rawSymbol$text';
  }

  static double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) {
      return 0;
    }

    final normalized =
        raw.replaceAll(RegExp(r'[^0-9,.\-]'), '').replaceAll(',', '');
    return double.tryParse(normalized);
  }
}
