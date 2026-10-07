class HeldCart {
  HeldCart({
    required this.id,
    required this.items,
    required this.createdAt,
    required this.cashierName,
    required this.totalAmount,
  });

  final int id;

  final Map<int, int> items;

  final DateTime createdAt;

  final String cashierName;

  final int totalAmount;
}
