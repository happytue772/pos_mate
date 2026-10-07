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

  Product copyWith({
    int? id,
    String? barcode,
    String? name,
    String? category,
    int? price,
    int? stock,
    int? minimumStock,
    bool? adultProduct,
    DateTime? expirationDate,
  }) {
    return Product(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      minimumStock: minimumStock ?? this.minimumStock,
      adultProduct: adultProduct ?? this.adultProduct,
      expirationDate: expirationDate ?? this.expirationDate,
    );
  }
}
