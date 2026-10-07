class SaleItem {
  const SaleItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  final int productId;
  final String productName;
  final int unitPrice;
  final int quantity;

  int get subtotal => unitPrice * quantity;
}
