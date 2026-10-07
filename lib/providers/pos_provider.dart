import 'package:flutter/material.dart';

import '../data/demo/demo_products.dart';
import '../data/models/product.dart';
import '../data/models/promotion.dart';
import '../data/models/sale.dart';
import '../data/models/sale_item.dart';
import '../data/models/stock_movement.dart';
import '../data/models/held_cart.dart';
import '../data/models/stock_adjustment_reason.dart';

class PosProvider extends ChangeNotifier {
  final List<Product> _products = createDemoProducts();

  final Map<int, int> _cart = {};

  final List<Sale> _sales = [];
  final List<HeldCart> _heldCarts = [];

  int _nextHeldCartId = 1;

  final List<StockMovement> _stockMovements = [];

  // =========================================================
  // 행사 / 프로모션
  // =========================================================

  final List<Promotion> _promotions = [
    Promotion(
      id: 1,
      productId: 2,
      type: PromotionType.onePlusOne,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 365)),
    ),
    Promotion(
      id: 2,
      productId: 7,
      type: PromotionType.twoPlusOne,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 365)),
    ),
    Promotion(
      id: 3,
      productId: 11,
      type: PromotionType.percentDiscount,
      percent: 20,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 365)),
    ),
    Promotion(
      id: 4,
      productId: 10,
      type: PromotionType.specialPrice,
      specialPrice: 2500,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 365)),
    ),
  ];

  int _nextProductId = 15;
  int _nextSaleId = 1;
  int _nextStockMovementId = 1;

  // =========================================================
  // 기본 Getter
  // =========================================================

  List<Product> get products {
    return List.unmodifiable(_products);
  }

  List<HeldCart> get heldCarts {
    return List.unmodifiable(_heldCarts.reversed);
  }

  Map<int, int> get cart {
    return Map.unmodifiable(_cart);
  }

  List<Sale> get sales {
    return List.unmodifiable(_sales.reversed);
  }

  List<StockMovement> get stockMovements {
    return List.unmodifiable(_stockMovements.reversed);
  }

  List<Promotion> get promotions {
    return List.unmodifiable(_promotions);
  }

  // =========================================================
  // 판매 통계
  // =========================================================

  int get completedSales {
    return _sales.where((sale) => sale.netAmount > 0).length;
  }

  int get refundedSales {
    return _sales.where((sale) => sale.refundedAmount > 0).length;
  }

  int get totalSalesAmount {
    return _sales.fold<int>(0, (sum, sale) => sum + sale.netAmount);
  }

  // =========================================================
  // 행사 / 프로모션
  // =========================================================

  Promotion? activePromotionForProduct(int productId) {
    for (final promotion in _promotions) {
      if (promotion.productId == productId && promotion.isActive) {
        return promotion;
      }
    }

    return null;
  }

  int calculateProductTotal(Product product, int quantity) {
    if (quantity <= 0) {
      return 0;
    }

    final promotion = activePromotionForProduct(product.id);

    if (promotion == null) {
      return product.price * quantity;
    }

    switch (promotion.type) {
      case PromotionType.onePlusOne:
        final paidQuantity = (quantity + 1) ~/ 2;

        return product.price * paidQuantity;

      case PromotionType.twoPlusOne:
        final freeQuantity = quantity ~/ 3;

        final paidQuantity = quantity - freeQuantity;

        return product.price * paidQuantity;

      case PromotionType.percentDiscount:
        final percent = promotion.percent ?? 0;

        final discountedPrice = product.price * (100 - percent) ~/ 100;

        return discountedPrice * quantity;

      case PromotionType.specialPrice:
        final specialPrice = promotion.specialPrice ?? product.price;

        return specialPrice * quantity;
    }
  }

  String? promotionLabelForProduct(Product product) {
    final promotion = activePromotionForProduct(product.id);

    if (promotion == null) {
      return null;
    }

    switch (promotion.type) {
      case PromotionType.onePlusOne:
        return '1+1 행사';

      case PromotionType.twoPlusOne:
        return '2+1 행사';

      case PromotionType.percentDiscount:
        return '${promotion.percent ?? 0}% 할인';

      case PromotionType.specialPrice:
        return '${promotion.specialPrice ?? product.price}원 특가';
    }
  }

  // =========================================================
  // 장바구니
  // =========================================================

  int quantityOf(int productId) {
    return _cart[productId] ?? 0;
  }

  int get cartItemCount {
    return _cart.values.fold<int>(0, (sum, quantity) => sum + quantity);
  }

  int get cartTotal {
    int total = 0;

    for (final product in _products) {
      final quantity = _cart[product.id] ?? 0;

      total += calculateProductTotal(product, quantity);
    }

    return total;
  }

  bool get cartContainsAdultProduct {
    for (final product in _products) {
      final quantity = _cart[product.id] ?? 0;

      if (quantity > 0 && product.adultProduct) {
        return true;
      }
    }

    return false;
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

  // =========================================================
  // 결제 / 판매
  // =========================================================

  Sale? checkout({
    required int shiftId,
    required PaymentMethod paymentMethod,
    required String cashierName,
    int? receivedAmount,
  }) {
    if (_cart.isEmpty) {
      return null;
    }

    // 결제 직전 재고 확인
    for (final product in _products) {
      final quantity = _cart[product.id] ?? 0;

      if (quantity > product.stock) {
        return null;
      }
    }

    final total = cartTotal;

    // 현금 결제 금액 확인
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

      final promotion = activePromotionForProduct(product.id);

      items.add(
        SaleItem(
          productId: product.id,
          productName: product.name,
          unitPrice: product.price,
          quantity: quantity,
          promotionType: promotion?.type,
          promotionPercent: promotion?.percent,
          promotionSpecialPrice: promotion?.specialPrice,
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
      shiftId: shiftId,
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

  // =========================================================
  // 부분 환불
  // =========================================================

  int? refundSaleItems({
    required int saleId,
    required Map<int, int> refundQuantities,
  }) {
    final saleIndex = _sales.indexWhere((sale) => sale.id == saleId);

    if (saleIndex == -1) {
      return null;
    }

    final sale = _sales[saleIndex];

    if (sale.status == SaleStatus.refunded) {
      return null;
    }

    final selected = refundQuantities.entries
        .where((entry) => entry.value > 0)
        .toList();

    if (selected.isEmpty) {
      return null;
    }

    // 환불 가능 여부 먼저 검사
    for (final entry in selected) {
      final itemIndex = sale.items.indexWhere(
        (item) => item.productId == entry.key,
      );

      if (itemIndex == -1) {
        return null;
      }

      final item = sale.items[itemIndex];

      if (entry.value > item.remainingQuantity) {
        return null;
      }

      final productExists = _products.any((product) => product.id == entry.key);

      if (!productExists) {
        return null;
      }
    }

    final now = DateTime.now();

    int refundAmount = 0;

    for (final entry in selected) {
      final item = sale.items.firstWhere((item) => item.productId == entry.key);

      final quantity = entry.value;

      refundAmount += item.refundAmountFor(quantity);

      item.refundedQuantity += quantity;

      final productIndex = _products.indexWhere(
        (product) => product.id == item.productId,
      );

      final product = _products[productIndex];

      final beforeStock = product.stock;

      product.stock += quantity;

      _stockMovements.add(
        StockMovement(
          id: _nextStockMovementId++,
          productId: product.id,
          productName: product.name,
          type: StockMovementType.refund,
          quantity: quantity,
          beforeStock: beforeStock,
          afterStock: product.stock,
          createdAt: now,
          referenceId: sale.receiptNumber,
        ),
      );
    }

    final allRefunded = sale.items.every((item) => item.remainingQuantity == 0);

    sale.status = allRefunded
        ? SaleStatus.refunded
        : SaleStatus.partiallyRefunded;

    sale.refundedAt = now;

    notifyListeners();

    return refundAmount;
  }

  // =========================================================
  // 전체 환불
  // =========================================================

  bool refundSale(int saleId) {
    final saleIndex = _sales.indexWhere((sale) => sale.id == saleId);

    if (saleIndex == -1) {
      return false;
    }

    final sale = _sales[saleIndex];

    if (sale.status == SaleStatus.refunded) {
      return false;
    }

    final quantities = <int, int>{};

    for (final item in sale.items) {
      if (item.remainingQuantity > 0) {
        quantities[item.productId] = item.remainingQuantity;
      }
    }

    if (quantities.isEmpty) {
      return false;
    }

    final result = refundSaleItems(
      saleId: saleId,
      refundQuantities: quantities,
    );

    return result != null;
  }

  // =========================================================
  // 상품 관리
  // =========================================================

  bool barcodeExists(String barcode, {int? exceptProductId}) {
    return _products.any(
      (product) => product.barcode == barcode && product.id != exceptProductId,
    );
  }

  void addProduct({
    required String barcode,
    required String name,
    required ProductCategory category,
    required String subCategory,
    required int price,
    required int stock,
    required int minimumStock,
    required bool adultProduct,
    DateTime? expirationDate,
  }) {
    final product = Product(
      id: _nextProductId++,
      barcode: barcode,
      name: name,
      category: category,
      subCategory: subCategory,
      price: price,
      stock: stock,
      minimumStock: minimumStock,
      adultProduct: adultProduct,
      expirationDate: expirationDate,
    );

    _products.add(product);

    notifyListeners();
  }

  bool adjustStock({
    required int productId,
    required int actualStock,
    required StockAdjustmentReason reason,
    String? memo,
  }) {
    if (actualStock < 0) {
      return false;
    }

    final index = _products.indexWhere((product) => product.id == productId);

    if (index == -1) {
      return false;
    }

    final product = _products[index];

    final beforeStock = product.stock;

    if (beforeStock == actualStock) {
      return false;
    }

    product.stock = actualStock;

    final difference = (actualStock - beforeStock).abs();

    _stockMovements.add(
      StockMovement(
        id: _nextStockMovementId++,
        productId: product.id,
        productName: product.name,
        type: StockMovementType.adjustment,
        quantity: difference,
        beforeStock: beforeStock,
        afterStock: actualStock,
        createdAt: DateTime.now(),
        memo: memo == null || memo.trim().isEmpty
            ? reason.label
            : '${reason.label} · ${memo.trim()}',
      ),
    );

    notifyListeners();

    return true;
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

  // =========================================================
  // 입고
  // =========================================================

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

  // =========================================================
  // 유통기한 / 폐기
  // =========================================================

  bool disposeStock({
    required int productId,
    required int quantity,
    String memo = '유통기한 / 상품 폐기',
  }) {
    if (quantity <= 0) {
      return false;
    }

    final index = _products.indexWhere((product) => product.id == productId);

    if (index == -1) {
      return false;
    }

    final product = _products[index];

    if (quantity > product.stock) {
      return false;
    }

    final beforeStock = product.stock;

    product.stock -= quantity;

    _stockMovements.add(
      StockMovement(
        id: _nextStockMovementId++,
        productId: product.id,
        productName: product.name,
        type: StockMovementType.disposal,
        quantity: quantity,
        beforeStock: beforeStock,
        afterStock: product.stock,
        createdAt: DateTime.now(),
        memo: memo,
      ),
    );

    notifyListeners();

    return true;
  }

  bool restoreHeldCart(int heldCartId) {
    if (_cart.isNotEmpty) {
      return false;
    }

    final index = _heldCarts.indexWhere((cart) => cart.id == heldCartId);

    if (index == -1) {
      return false;
    }

    final held = _heldCarts[index];

    for (final entry in held.items.entries) {
      final productIndex = _products.indexWhere(
        (product) => product.id == entry.key,
      );

      if (productIndex == -1) {
        return false;
      }

      final product = _products[productIndex];

      if (entry.value > product.stock) {
        return false;
      }
    }

    _cart.addAll(held.items);

    _heldCarts.removeAt(index);

    notifyListeners();

    return true;
  }

  void deleteHeldCart(int heldCartId) {
    _heldCarts.removeWhere((cart) => cart.id == heldCartId);

    notifyListeners();
  }

  bool holdCurrentCart({required String cashierName}) {
    if (_cart.isEmpty) {
      return false;
    }

    final heldCart = HeldCart(
      id: _nextHeldCartId++,
      items: Map<int, int>.from(_cart),
      createdAt: DateTime.now(),
      cashierName: cashierName,
      totalAmount: cartTotal,
    );

    _heldCarts.add(heldCart);

    _cart.clear();

    notifyListeners();

    return true;
  }

  // =========================================================
  // 영수증 번호 생성
  // =========================================================

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
