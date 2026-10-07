import '../models/product.dart';

List<Product> createDemoProducts() {
  final now = DateTime.now();

  return [
    Product(
      id: 1,
      barcode: '880000000001',
      name: '생수 500ml',
      category: ProductCategory.beverage,
      subCategory: '생수',
      price: 1000,
      stock: 20,
      minimumStock: 5,
    ),

    Product(
      id: 2,
      barcode: '880000000002',
      name: '콜라 500ml',
      category: ProductCategory.beverage,
      subCategory: '탄산음료',
      price: 2200,
      stock: 12,
      minimumStock: 5,
    ),

    Product(
      id: 3,
      barcode: '880000000003',
      name: '아메리카노 캔커피',
      category: ProductCategory.beverage,
      subCategory: '커피',
      price: 1800,
      stock: 15,
      minimumStock: 4,
    ),

    Product(
      id: 4,
      barcode: '880000000004',
      name: '맥주 500ml',
      category: ProductCategory.alcohol,
      subCategory: '맥주',
      price: 3000,
      stock: 20,
      minimumStock: 5,
      adultProduct: true,
    ),

    Product(
      id: 5,
      barcode: '880000000005',
      name: '소주 360ml',
      category: ProductCategory.alcohol,
      subCategory: '소주',
      price: 1900,
      stock: 20,
      minimumStock: 5,
      adultProduct: true,
    ),

    Product(
      id: 6,
      barcode: '880000000006',
      name: '컵라면',
      category: ProductCategory.ramen,
      subCategory: '컵라면',
      price: 1800,
      stock: 18,
      minimumStock: 5,
      expirationDate: now.add(const Duration(days: 120)),
    ),

    Product(
      id: 7,
      barcode: '880000000007',
      name: '삼각김밥',
      category: ProductCategory.readyMeal,
      subCategory: '삼각김밥',
      price: 1500,
      stock: 8,
      minimumStock: 3,
      expirationDate: now.add(const Duration(days: 1)),
    ),

    Product(
      id: 8,
      barcode: '880000000008',
      name: '편의점 도시락',
      category: ProductCategory.readyMeal,
      subCategory: '도시락',
      price: 5500,
      stock: 5,
      minimumStock: 2,
      expirationDate: now.add(const Duration(days: 2)),
    ),

    Product(
      id: 9,
      barcode: '880000000009',
      name: '크림빵',
      category: ProductCategory.bakery,
      subCategory: '조리빵',
      price: 2000,
      stock: 10,
      minimumStock: 3,
      expirationDate: now.add(const Duration(days: 3)),
    ),

    Product(
      id: 10,
      barcode: '880000000010',
      name: '우유 900ml',
      category: ProductCategory.dairy,
      subCategory: '우유',
      price: 2900,
      stock: 7,
      minimumStock: 3,
      expirationDate: now.add(const Duration(days: 5)),
    ),

    Product(
      id: 11,
      barcode: '880000000011',
      name: '초콜릿',
      category: ProductCategory.snack,
      subCategory: '초콜릿',
      price: 2000,
      stock: 12,
      minimumStock: 4,
      expirationDate: now.add(const Duration(days: 180)),
    ),

    Product(
      id: 12,
      barcode: '880000000012',
      name: '냉동 만두',
      category: ProductCategory.frozen,
      subCategory: '냉동간편식',
      price: 6500,
      stock: 8,
      minimumStock: 2,
      expirationDate: now.add(const Duration(days: 90)),
    ),

    Product(
      id: 13,
      barcode: '880000000013',
      name: '세탁세제',
      category: ProductCategory.household,
      subCategory: '세제',
      price: 7500,
      stock: 6,
      minimumStock: 2,
    ),

    Product(
      id: 14,
      barcode: '880000000014',
      name: '담배 DEMO',
      category: ProductCategory.tobacco,
      subCategory: '담배',
      price: 4500,
      stock: 20,
      minimumStock: 5,
      adultProduct: true,
    ),
  ];
}
