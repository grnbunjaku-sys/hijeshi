String formatPrice(dynamic price) {
  try {
    final value = double.tryParse(price.toString()) ?? 0;
    return value.toStringAsFixed(2);
  } catch (_) {
    return "0.00";
  }
}