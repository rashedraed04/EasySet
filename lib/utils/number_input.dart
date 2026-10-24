/// Converts Arabic-Indic / Persian digits and decimal separators to plain ASCII
/// so that numbers typed on an Arabic keyboard parse correctly.
String normalizeDigits(String input) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  final out = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    var digit = arabic.indexOf(ch);
    if (digit < 0) digit = persian.indexOf(ch);
    if (digit >= 0) {
      out.write(digit);
    } else if (ch == '٫' || ch == ',' || ch == '،') {
      out.write('.');
    } else {
      out.write(ch);
    }
  }
  return out.toString().trim();
}

/// Returns null when [input] is not a valid non-negative number.
double? parseNumber(String input) {
  final value = double.tryParse(normalizeDigits(input));
  if (value == null || value.isNaN || value.isInfinite || value < 0) return null;
  return value;
}

/// Returns null when [input] is not a whole number.
int? parseWholeNumber(String input) {
  final value = parseNumber(input);
  if (value == null || value != value.truncateToDouble()) return null;
  return value.toInt();
}

/// 80 -> "80", 82.5 -> "82.5"
String formatNumber(double value) {
  return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
}
