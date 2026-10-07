import 'package:flutter/material.dart';

import '../data/demo/demo_products.dart';
import '../data/models/product.dart';

class PosProvider extends ChangeNotifier {
  final List<Product> _products = createDemoProducts();

  final Map<int, int> _cart = {};

  int _nextProductId = 6;

  int _completedSales = 0;
  int _totalSalesAmount = 0;

  List<Product> get products => List.unmodifiable(_products);

  Map<int, int> get cart => Map.unmodifiable(_cart);

  int get completedSales => _completedSales;

  int get totalSalesAmount => _totalSalesAmount;

  int quantityOf(int productId) {
    return _cart[productId] ?? 0;
  }

  int get cartItemCount {
    return _cart.values.fold(0, (sum, quantity) => sum + quantity);
  }

  int get cartTotal {
    int total = 0;

    for (final product in _products) {
      final quantity = _cart[product.id] ?? 0;

      total += product.price * quantity;
    }

    return total;
  }

  void addToCart(Product product) {
    final currentQuantity = _cart[product.id] ?? 0;

    if (currentQuantity >= product.stock) {
      return;
    }

    _cart[product.id] = currentQuantity + 1;

    notifyListeners();
  }

  void removeFromCart(Product product) {
    final currentQuantity = _cart[product.id] ?? 0;

    if (currentQuantity <= 0) {
      return;
    }

    if (currentQuantity == 1) {
      _cart.remove(product.id);
    } else {
      _cart[product.id] = currentQuantity - 1;
    }

    notifyListeners();
  }

  bool checkout() {
    if (_cart.isEmpty) {
      return false;
    }

    final saleAmount = cartTotal;

    for (final product in _products) {
      final quantity = _cart[product.id] ?? 0;

      if (quantity > 0) {
        product.stock -= quantity;
      }
    }

    _completedSales++;
    _totalSalesAmount += saleAmount;

    _cart.clear();

    notifyListeners();

    return true;
  }

  bool barcodeExists(String barcode, {int? exceptProductId}) {
    return _products.any(
      (product) => product.barcode == barcode && product.id != exceptProductId,
    );
  }

  void addProduct({
    required String barcode,
    required String name,
    required String category,
    required int price,
    required int stock,
    required int minimumStock,
    required bool adultProduct,
  }) {
    final product = Product(
      id: _nextProductId++,
      barcode: barcode,
      name: name,
      category: category,
      price: price,
      stock: stock,
      minimumStock: minimumStock,
      adultProduct: adultProduct,
    );

    _products.add(product);

    notifyListeners();
  }

  void updateProduct(Product updatedProduct) {
    final index = _products.indexWhere(
      (product) => product.id == updatedProduct.id,
    );

    if (index == -1) {
      return;
    }

    _products[index] = updatedProduct;

    notifyListeners();
  }

  bool deleteProduct(int productId) {
    if (_cart.containsKey(productId)) {
      return false;
    }

    _products.removeWhere((product) => product.id == productId);

    notifyListeners();

    return true;
  }

  void restockProduct(int productId, int quantity) {
    if (quantity <= 0) {
      return;
    }

    final index = _products.indexWhere((product) => product.id == productId);

    if (index == -1) {
      return;
    }

    _products[index].stock += quantity;

    notifyListeners();
  }
}
