class Product {
  Product({
    required this.id,
    required this.barcode,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.minimumStock,
    this.adultProduct = false,
    this.expirationDate,
  });

  final int id;
  final String barcode;
  final String name;
  final String category;
  final int price;

  int stock;

  final int minimumStock;
  final bool adultProduct;
  final DateTime? expirationDate;

  bool get isLowStock => stock <= minimumStock;
}
