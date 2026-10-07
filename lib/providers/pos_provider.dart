import 'package:flutter/material.dart';

import '../data/demo/demo_products.dart';
import '../data/models/product.dart';
import '../data/models/sale.dart';
import '../data/models/sale_item.dart';
import '../data/models/stock_movement.dart';

class PosProvider extends ChangeNotifier {
  final List<Product> _products = createDemoProducts();

  final Map<int, int> _cart = {};

  final List<Sale> _sales = [];

  final List<StockMovement> _stockMovements = [];

  int _nextProductId = 6;
  int _nextSaleId = 1;
  int _nextStockMovementId = 1;

  List<Product> get products => List.unmodifiable(_products);

  Map<int, int> get cart => Map.unmodifiable(_cart);

  List<Sale> get sales {
    return List.unmodifiable(_sales.reversed);
  }

  List<StockMovement> get stockMovements {
    return List.unmodifiable(_stockMovements.reversed);
  }

  int get completedSales {
    return _sales.where((sale) => sale.status == SaleStatus.completed).length;
  }

  int get refundedSales {
    return _sales.where((sale) => sale.status == SaleStatus.refunded).length;
  }

  int get totalSalesAmount {
    return _sales
        .where((sale) => sale.status == SaleStatus.completed)
        .fold(0, (sum, sale) => sum + sale.totalAmount);
  }

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

  void clearCart() {
    _cart.clear();

    notifyListeners();
  }

  Sale? checkout({
    required PaymentMethod paymentMethod,
    required String cashierName,
    int? receivedAmount,
  }) {
    if (_cart.isEmpty) {
      return null;
    }

    for (final product in _products) {
      final quantity = _cart[product.id] ?? 0;

      if (quantity > product.stock) {
        return null;
      }
    }

    final total = cartTotal;

    if (paymentMethod == PaymentMethod.cash &&
        (receivedAmount == null || receivedAmount < total)) {
      return null;
    }

    final saleId = _nextSaleId++;

    final now = DateTime.now();

    final receiptNumber = _createReceiptNumber(saleId, now);

    final items = <SaleItem>[];

    for (final product in _products) {
      final quantity = _cart[product.id] ?? 0;

      if (quantity <= 0) {
        continue;
      }

      items.add(
        SaleItem(
          productId: product.id,
          productName: product.name,
          unitPrice: product.price,
          quantity: quantity,
        ),
      );

      final beforeStock = product.stock;

      product.stock -= quantity;

      _stockMovements.add(
        StockMovement(
          id: _nextStockMovementId++,
          productId: product.id,
          productName: product.name,
          type: StockMovementType.sale,
          quantity: quantity,
          beforeStock: beforeStock,
          afterStock: product.stock,
          createdAt: now,
          referenceId: receiptNumber,
        ),
      );
    }

    final changeAmount = paymentMethod == PaymentMethod.cash
        ? receivedAmount! - total
        : null;

    final sale = Sale(
      id: saleId,
      receiptNumber: receiptNumber,
      items: items,
      totalAmount: total,
      paymentMethod: paymentMethod,
      cashierName: cashierName,
      soldAt: now,
      receivedAmount: paymentMethod == PaymentMethod.cash
          ? receivedAmount
          : null,
      changeAmount: changeAmount,
    );

    _sales.add(sale);

    _cart.clear();

    notifyListeners();

    return sale;
  }

  bool refundSale(int saleId) {
    final saleIndex = _sales.indexWhere((sale) => sale.id == saleId);

    if (saleIndex == -1) {
      return false;
    }

    final sale = _sales[saleIndex];

    if (sale.status == SaleStatus.refunded) {
      return false;
    }

    for (final item in sale.items) {
      final exists = _products.any((product) => product.id == item.productId);

      if (!exists) {
        return false;
      }
    }

    final now = DateTime.now();

    for (final item in sale.items) {
      final productIndex = _products.indexWhere(
        (product) => product.id == item.productId,
      );

      final product = _products[productIndex];

      final beforeStock = product.stock;

      product.stock += item.quantity;

      _stockMovements.add(
        StockMovement(
          id: _nextStockMovementId++,
          productId: product.id,
          productName: product.name,
          type: StockMovementType.refund,
          quantity: item.quantity,
          beforeStock: beforeStock,
          afterStock: product.stock,
          createdAt: now,
          referenceId: sale.receiptNumber,
        ),
      );
    }

    sale.status = SaleStatus.refunded;

    sale.refundedAt = now;

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

    final usedInSale = _sales.any(
      (sale) => sale.items.any((item) => item.productId == productId),
    );

    if (usedInSale) {
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

    final product = _products[index];

    final beforeStock = product.stock;

    product.stock += quantity;

    _stockMovements.add(
      StockMovement(
        id: _nextStockMovementId++,
        productId: product.id,
        productName: product.name,
        type: StockMovementType.restock,
        quantity: quantity,
        beforeStock: beforeStock,
        afterStock: product.stock,
        createdAt: DateTime.now(),
      ),
    );

    notifyListeners();
  }

  String _createReceiptNumber(int saleId, DateTime dateTime) {
    String two(int value) {
      return value.toString().padLeft(2, '0');
    }

    final date =
        '${dateTime.year}'
        '${two(dateTime.month)}'
        '${two(dateTime.day)}';

    final number = saleId.toString().padLeft(4, '0');

    return 'R$date-$number';
  }
}
