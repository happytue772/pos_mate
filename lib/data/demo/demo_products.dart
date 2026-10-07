import '../models/product.dart';

List<Product> createDemoProducts() {
  return [
    Product(
      id: 1,
      barcode: '880000000001',
      name: '생수 500ml',
      category: '음료',
      price: 1000,
      stock: 20,
      minimumStock: 5,
    ),
    Product(
      id: 2,
      barcode: '880000000002',
      name: '콜라 500ml',
      category: '음료',
      price: 2200,
      stock: 12,
      minimumStock: 5,
    ),
    Product(
      id: 3,
      barcode: '880000000003',
      name: '삼각김밥',
      category: '식품',
      price: 1500,
      stock: 8,
      minimumStock: 3,
    ),
    Product(
      id: 4,
      barcode: '880000000004',
      name: '컵라면',
      category: '식품',
      price: 1800,
      stock: 15,
      minimumStock: 5,
    ),
    Product(
      id: 5,
      barcode: '880000000005',
      name: '초콜릿',
      category: '간식',
      price: 2000,
      stock: 3,
      minimumStock: 3,
    ),
  ];
}
