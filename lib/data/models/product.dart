enum ProductCategory {
  beverage,
  alcohol,
  ramen,
  bakery,
  snack,
  dairy,
  readyMeal,
  frozen,
  household,
  tobacco,
  other,
}

extension ProductCategoryLabel on ProductCategory {
  String get label {
    switch (this) {
      case ProductCategory.beverage:
        return '음료';
      case ProductCategory.alcohol:
        return '주류';
      case ProductCategory.ramen:
        return '라면';
      case ProductCategory.bakery:
        return '빵';
      case ProductCategory.snack:
        return '과자 / 간식';
      case ProductCategory.dairy:
        return '유제품';
      case ProductCategory.readyMeal:
        return '즉석식품';
      case ProductCategory.frozen:
        return '냉동식품';
      case ProductCategory.household:
        return '생활용품';
      case ProductCategory.tobacco:
        return '담배';
      case ProductCategory.other:
        return '기타';
    }
  }
}

enum ExpirationStatus { none, normal, soon, today, expired }

class Product {
  Product({
    required this.id,
    required this.barcode,
    required this.name,
    required this.category,
    required this.subCategory,
    required this.price,
    required this.stock,
    required this.minimumStock,
    this.adultProduct = false,
    this.expirationDate,
  });

  final int id;
  final String barcode;
  final String name;

  final ProductCategory category;
  final String subCategory;

  final int price;

  int stock;

  final int minimumStock;

  final bool adultProduct;

  final DateTime? expirationDate;

  bool get isLowStock => stock <= minimumStock;

  int? get daysUntilExpiration {
    if (expirationDate == null) {
      return null;
    }

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final expiration = DateTime(
      expirationDate!.year,
      expirationDate!.month,
      expirationDate!.day,
    );

    return expiration.difference(today).inDays;
  }

  ExpirationStatus get expirationStatus {
    final days = daysUntilExpiration;

    if (days == null) {
      return ExpirationStatus.none;
    }

    if (days < 0) {
      return ExpirationStatus.expired;
    }

    if (days == 0) {
      return ExpirationStatus.today;
    }

    if (days <= 3) {
      return ExpirationStatus.soon;
    }

    return ExpirationStatus.normal;
  }

  String get expirationLabel {
    switch (expirationStatus) {
      case ExpirationStatus.none:
        return '유통기한 관리 안 함';

      case ExpirationStatus.normal:
        return '유통기한 $daysUntilExpiration일 남음';

      case ExpirationStatus.soon:
        return '유통기한 임박 · $daysUntilExpiration일 남음';

      case ExpirationStatus.today:
        return '오늘까지';

      case ExpirationStatus.expired:
        return '유통기한 만료';
    }
  }

  Product copyWith({
    int? id,
    String? barcode,
    String? name,
    ProductCategory? category,
    String? subCategory,
    int? price,
    int? stock,
    int? minimumStock,
    bool? adultProduct,
    DateTime? expirationDate,
    bool clearExpirationDate = false,
  }) {
    return Product(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      minimumStock: minimumStock ?? this.minimumStock,
      adultProduct: adultProduct ?? this.adultProduct,
      expirationDate: clearExpirationDate
          ? null
          : expirationDate ?? this.expirationDate,
    );
  }
}
