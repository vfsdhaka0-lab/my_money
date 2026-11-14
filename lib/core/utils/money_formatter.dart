
String formatMoney(int paisa) {
  final taka = paisa ~/ 100;
  final remainder =
      (paisa % 100).toString().padLeft(2, '0');

  return '৳$taka.$remainder';
}
