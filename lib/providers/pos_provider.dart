import 'package:flutter/material.dart';

import '../data/demo/demo_products.dart';
import '../data/models/product.dart';

class PosProvider extends ChangeNotifier {
  final List<Product> _products = createDemoProducts();

  final Map<int, int> _cart = {};

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
}
