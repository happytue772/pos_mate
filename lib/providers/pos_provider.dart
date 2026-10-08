import 'dart:async';

import 'package:flutter/material.dart';

import '../data/database/local_database.dart';
import '../data/demo/demo_products.dart';
import '../data/models/audit_log.dart';
import '../data/models/held_cart.dart';
import '../data/models/product.dart';
import '../data/models/price_change_history.dart';
import '../data/models/promotion.dart';
import '../data/models/refund_transaction.dart';
import '../data/models/sale.dart';
import '../data/models/sale_item.dart';
import '../data/models/stock_adjustment_reason.dart';
import '../data/models/stock_movement.dart';
import '../services/audit_log_service.dart';

class PosProvider extends ChangeNotifier {
  final LocalDatabase _database = LocalDatabase.instance;
  final AuditLogService _audit = AuditLogService.instance;

  final List<Product> _products = [];
  final Map<int, int> _cart = {};
  final List<Sale> _sales = [];
  final List<RefundTransaction> _refundTransactions = [];
  final List<HeldCart> _heldCarts = [];
  final List<StockMovement> _stockMovements = [];
  final List<Promotion> _promotions = [];
  final Set<int> _favoriteProductIds = <int>{};
  final List<PriceChangeHistory> _priceChangeHistory = [];

  int _nextProductId = 1;
  int _nextSaleId = 1;
  int _nextRefundTransactionId = 1;
  int _nextStockMovementId = 1;
  int _nextHeldCartId = 1;
  int _nextPromotionId = 1;
  int _nextPriceChangeId = 1;

  bool _isLoading = true;

  bool get isLoading => _isLoading;

  PosProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _products.clear();
      _sales.clear();
      _refundTransactions.clear();
      _stockMovements.clear();
      _heldCarts.clear();
      _promotions.clear();
      _favoriteProductIds.clear();
      _priceChangeHistory.clear();

      final savedProducts = await _database.getProducts();
      final catalogProducts = createDemoProducts();

      if (savedProducts.isEmpty) {
        _products.addAll(catalogProducts);
        await _database.insertProducts(catalogProducts);
      } else {
        // 기존 판매/재고 이력은 유지한다.
        // 과거 DEMO 상품은 새 카탈로그의 이름/바코드만 정리하고,
        // 사용 중인 가격·원가·재고·최소재고는 그대로 보존한다.
        final catalogById = {
          for (final product in catalogProducts) product.id: product,
        };

        final normalizedProducts = <Product>[];

        for (final saved in savedProducts) {
          final catalog = catalogById[saved.id];

          if (catalog != null &&
              (saved.name.contains('데모') ||
                  saved.barcode.startsWith('DEMO-'))) {
            final normalized = Product(
              id: saved.id,
              barcode: catalog.barcode,
              name: catalog.name,
              category: catalog.category,
              subCategory: catalog.subCategory,
              price: saved.price,
              costPrice: saved.costPrice,
              stock: saved.stock,
              minimumStock: saved.minimumStock,
              adultProduct: catalog.adultProduct,
              expirationDate: saved.expirationDate,
            );

            normalizedProducts.add(normalized);
            await _database.upsertProduct(normalized);
          } else {
            normalizedProducts.add(saved);
          }
        }

        _products.addAll(normalizedProducts);

        final existingIds = normalizedProducts
            .map((product) => product.id)
            .toSet();

        final existingBarcodes = normalizedProducts
            .map((product) => product.barcode)
            .toSet();

        final missingCatalogProducts = catalogProducts
            .where(
              (product) =>
                  !existingIds.contains(product.id) &&
                  !existingBarcodes.contains(product.barcode),
            )
            .toList();

        if (missingCatalogProducts.isNotEmpty) {
          _products.addAll(missingCatalogProducts);

          await _database.insertProducts(missingCatalogProducts);
        }
      }

      _sales.addAll(await _database.getSales());
      _refundTransactions.addAll(await _database.getRefundTransactions());
      _stockMovements.addAll(await _database.getStockMovements());
      _heldCarts.addAll(await _database.getHeldCarts());

      _favoriteProductIds.addAll(await _database.getFavoriteProductIds());

      _priceChangeHistory.addAll(await _database.getPriceChangeHistory());

      final savedPromotions = await _database.getPromotions();

      if (savedPromotions.isEmpty) {
        final demoPromotions = _createDemoPromotions();
        _promotions.addAll(demoPromotions);
        await _database.insertPromotions(demoPromotions);
      } else {
        _promotions.addAll(savedPromotions);
      }

      _updateNextIds();
    } catch (error) {
      debugPrint('SQLite 초기화 오류: $error');

      if (_products.isEmpty) {
        _products.addAll(createDemoProducts());
      }

      if (_promotions.isEmpty) {
        _promotions.addAll(_createDemoPromotions());
      }

      _updateNextIds();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Promotion> _createDemoPromotions() {
    return [
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
  }

  void _updateNextIds() {
    _nextProductId = _nextId(_products.map((e) => e.id));
    _nextSaleId = _nextId(_sales.map((e) => e.id));
    _nextRefundTransactionId = _nextId(_refundTransactions.map((e) => e.id));
    _nextStockMovementId = _nextId(_stockMovements.map((e) => e.id));
    _nextHeldCartId = _nextId(_heldCarts.map((e) => e.id));
    _nextPromotionId = _nextId(_promotions.map((e) => e.id));
    _nextPriceChangeId = _nextId(_priceChangeHistory.map((e) => e.id));
  }

  int _nextId(Iterable<int> ids) {
    if (ids.isEmpty) {
      return 1;
    }

    final maxId = ids.reduce((a, b) => a > b ? a : b);
    return maxId + 1;
  }

  void _writeAudit({
    required AuditAction action,
    required String targetType,
    required String detail,
    String? targetId,
    String? targetName,
  }) {
    unawaited(
      _audit.logCurrent(
        action: action,
        targetType: targetType,
        targetId: targetId,
        targetName: targetName,
        detail: detail,
      ),
    );
  }

  List<Product> get products => List.unmodifiable(_products);
  Map<int, int> get cart => Map.unmodifiable(_cart);
  List<Sale> get sales => List.unmodifiable(_sales.reversed);

  List<RefundTransaction> get refundTransactions {
    return List.unmodifiable(_refundTransactions.reversed);
  }

  List<StockMovement> get stockMovements {
    return List.unmodifiable(_stockMovements.reversed);
  }

  List<HeldCart> get heldCarts {
    return List.unmodifiable(_heldCarts.reversed);
  }

  List<Promotion> get promotions => List.unmodifiable(_promotions);

  List<PriceChangeHistory> get priceChangeHistory {
    return List.unmodifiable(_priceChangeHistory.reversed);
  }

  bool isFavoriteProduct(int productId) {
    return _favoriteProductIds.contains(productId);
  }

  List<Product> get favoriteProducts {
    return _products
        .where((product) => _favoriteProductIds.contains(product.id))
        .toList(growable: false);
  }

  void toggleFavoriteProduct(int productId) {
    final exists = _products.any((product) => product.id == productId);

    if (!exists) {
      return;
    }

    final favorite = !_favoriteProductIds.contains(productId);

    if (favorite) {
      _favoriteProductIds.add(productId);
    } else {
      _favoriteProductIds.remove(productId);
    }

    unawaited(
      _database.setProductFavorite(productId: productId, favorite: favorite),
    );

    notifyListeners();
  }

  int get completedSales {
    return _sales.where((sale) => sale.netAmount > 0).length;
  }

  int get refundedSales {
    return _sales
        .where(
          (sale) =>
              sale.status == SaleStatus.partiallyRefunded ||
              sale.status == SaleStatus.refunded,
        )
        .length;
  }

  int get totalSalesAmount {
    return _sales.fold<int>(0, (sum, sale) => sum + sale.netAmount);
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  Promotion? activePromotionForProduct(int productId) {
    for (final promotion in _promotions) {
      if (promotion.productId == productId && promotion.isActive) {
        return promotion;
      }
    }

    return null;
  }

  bool hasPromotionConflict({
    required int productId,
    required DateTime startDate,
    required DateTime endDate,
    int? exceptPromotionId,
  }) {
    final start = _dateOnly(startDate);
    final end = _dateOnly(endDate);

    for (final promotion in _promotions) {
      if (!promotion.enabled) {
        continue;
      }

      if (promotion.id == exceptPromotionId) {
        continue;
      }

      if (promotion.productId != productId) {
        continue;
      }

      final existingStart = _dateOnly(promotion.startDate);
      final existingEnd = _dateOnly(promotion.endDate);

      if (!end.isBefore(existingStart) && !start.isAfter(existingEnd)) {
        return true;
      }
    }

    return false;
  }

  bool addPromotion({
    required int productId,
    required PromotionType type,
    required DateTime startDate,
    required DateTime endDate,
    int? percent,
    int? specialPrice,
    bool enabled = true,
  }) {
    final productIndex = _products.indexWhere(
      (product) => product.id == productId,
    );

    if (productIndex == -1) {
      return false;
    }

    if (_dateOnly(endDate).isBefore(_dateOnly(startDate))) {
      return false;
    }

    if (type == PromotionType.percentDiscount &&
        (percent == null || percent <= 0 || percent >= 100)) {
      return false;
    }

    if (type == PromotionType.specialPrice &&
        (specialPrice == null || specialPrice <= 0)) {
      return false;
    }

    if (enabled &&
        hasPromotionConflict(
          productId: productId,
          startDate: startDate,
          endDate: endDate,
        )) {
      return false;
    }

    final promotion = Promotion(
      id: _nextPromotionId++,
      productId: productId,
      type: type,
      startDate: _dateOnly(startDate),
      endDate: _dateOnly(endDate),
      percent: type == PromotionType.percentDiscount ? percent : null,
      specialPrice: type == PromotionType.specialPrice ? specialPrice : null,
      enabled: enabled,
    );

    _promotions.add(promotion);

    unawaited(_database.upsertPromotion(promotion));

    final product = _products[productIndex];

    _writeAudit(
      action: AuditAction.promotionCreate,
      targetType: 'PROMOTION',
      targetId: promotion.id.toString(),
      targetName: product.name,
      detail: '${type.label} 행사 등록 · ${enabled ? '활성' : '비활성'}',
    );

    notifyListeners();
    return true;
  }

  bool updatePromotion(Promotion promotion) {
    final index = _promotions.indexWhere((item) => item.id == promotion.id);

    if (index == -1) {
      return false;
    }

    final productIndex = _products.indexWhere(
      (product) => product.id == promotion.productId,
    );

    if (productIndex == -1) {
      return false;
    }

    if (_dateOnly(promotion.endDate).isBefore(_dateOnly(promotion.startDate))) {
      return false;
    }

    if (promotion.type == PromotionType.percentDiscount &&
        (promotion.percent == null ||
            promotion.percent! <= 0 ||
            promotion.percent! >= 100)) {
      return false;
    }

    if (promotion.type == PromotionType.specialPrice &&
        (promotion.specialPrice == null || promotion.specialPrice! <= 0)) {
      return false;
    }

    if (promotion.enabled &&
        hasPromotionConflict(
          productId: promotion.productId,
          startDate: promotion.startDate,
          endDate: promotion.endDate,
          exceptPromotionId: promotion.id,
        )) {
      return false;
    }

    final before = _promotions[index];

    final normalized = Promotion(
      id: promotion.id,
      productId: promotion.productId,
      type: promotion.type,
      startDate: _dateOnly(promotion.startDate),
      endDate: _dateOnly(promotion.endDate),
      percent: promotion.type == PromotionType.percentDiscount
          ? promotion.percent
          : null,
      specialPrice: promotion.type == PromotionType.specialPrice
          ? promotion.specialPrice
          : null,
      enabled: promotion.enabled,
    );

    _promotions[index] = normalized;
    unawaited(_database.upsertPromotion(normalized));

    final product = _products[productIndex];

    _writeAudit(
      action: AuditAction.promotionUpdate,
      targetType: 'PROMOTION',
      targetId: normalized.id.toString(),
      targetName: product.name,
      detail:
          '행사 수정 · ${before.type.label} → ${normalized.type.label} · '
          '${before.enabled ? '활성' : '비활성'} → '
          '${normalized.enabled ? '활성' : '비활성'}',
    );

    notifyListeners();
    return true;
  }

  bool togglePromotion(int promotionId) {
    final index = _promotions.indexWhere(
      (promotion) => promotion.id == promotionId,
    );

    if (index == -1) {
      return false;
    }

    final current = _promotions[index];

    return updatePromotion(current.copyWith(enabled: !current.enabled));
  }

  bool deletePromotion(int promotionId) {
    final index = _promotions.indexWhere(
      (promotion) => promotion.id == promotionId,
    );

    if (index == -1) {
      return false;
    }

    final promotion = _promotions[index];

    final productIndex = _products.indexWhere(
      (product) => product.id == promotion.productId,
    );

    final productName = productIndex == -1
        ? '삭제된 상품'
        : _products[productIndex].name;

    _promotions.removeAt(index);
    unawaited(_database.deletePromotion(promotionId));

    _writeAudit(
      action: AuditAction.promotionDelete,
      targetType: 'PROMOTION',
      targetId: promotion.id.toString(),
      targetName: productName,
      detail: '${promotion.type.label} 행사 삭제',
    );

    notifyListeners();
    return true;
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
        return product.price * ((quantity + 1) ~/ 2);

      case PromotionType.twoPlusOne:
        final freeQuantity = quantity ~/ 3;
        return product.price * (quantity - freeQuantity);

      case PromotionType.percentDiscount:
        final percent = promotion.percent ?? 0;
        final discountedPrice = product.price * (100 - percent) ~/ 100;
        return discountedPrice * quantity;

      case PromotionType.specialPrice:
        return (promotion.specialPrice ?? product.price) * quantity;
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

  int quantityOf(int productId) {
    return _cart[productId] ?? 0;
  }

  int get cartItemCount {
    return _cart.values.fold<int>(0, (sum, quantity) => sum + quantity);
  }

  int get cartTotal {
    int total = 0;

    for (final product in _products) {
      total += calculateProductTotal(product, _cart[product.id] ?? 0);
    }

    return total;
  }

  bool get cartContainsAdultProduct {
    return _products.any(
      (product) => (_cart[product.id] ?? 0) > 0 && product.adultProduct,
    );
  }

  void addToCart(Product product) {
    final quantity = quantityOf(product.id);

    if (quantity >= product.stock) {
      return;
    }

    _cart[product.id] = quantity + 1;
    notifyListeners();
  }

  void removeFromCart(Product product) {
    final quantity = quantityOf(product.id);

    if (quantity <= 0) {
      return;
    }

    if (quantity == 1) {
      _cart.remove(product.id);
    } else {
      _cart[product.id] = quantity - 1;
    }

    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  Sale? checkout({
    required int shiftId,
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

      final promotion = activePromotionForProduct(product.id);

      items.add(
        SaleItem(
          productId: product.id,
          productName: product.name,
          unitPrice: product.price,
          unitCost: product.costPrice,
          quantity: quantity,
          promotionType: promotion?.type,
          promotionPercent: promotion?.percent,
          promotionSpecialPrice: promotion?.specialPrice,
        ),
      );

      final beforeStock = product.stock;
      product.stock -= quantity;

      final movement = StockMovement(
        id: _nextStockMovementId++,
        productId: product.id,
        productName: product.name,
        type: StockMovementType.sale,
        quantity: quantity,
        beforeStock: beforeStock,
        afterStock: product.stock,
        createdAt: now,
        referenceId: receiptNumber,
      );

      _stockMovements.add(movement);
      unawaited(_database.upsertStockMovement(movement));
      unawaited(_database.upsertProduct(product));
    }

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
      changeAmount: paymentMethod == PaymentMethod.cash
          ? receivedAmount! - total
          : null,
    );

    _sales.add(sale);
    unawaited(_database.upsertSale(sale));

    _cart.clear();
    notifyListeners();

    return sale;
  }

  int? refundSaleItems({
    required int saleId,
    required Map<int, int> refundQuantities,
    RefundReason reason = RefundReason.customerChange,
    String processedBy = '시스템',
    String? memo,
  }) {
    final saleIndex = _sales.indexWhere((sale) => sale.id == saleId);

    if (saleIndex == -1) {
      return null;
    }

    final sale = _sales[saleIndex];

    if (sale.status == SaleStatus.refunded ||
        sale.status == SaleStatus.voided) {
      return null;
    }

    final selected = refundQuantities.entries
        .where((entry) => entry.value > 0)
        .toList();

    if (selected.isEmpty) {
      return null;
    }

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

      if (!_products.any((product) => product.id == entry.key)) {
        return null;
      }
    }

    final now = DateTime.now();
    int totalRefundAmount = 0;
    final refundItems = <RefundItem>[];

    for (final entry in selected) {
      final item = sale.items.firstWhere((item) => item.productId == entry.key);

      final quantity = entry.value;
      final itemRefundAmount = item.refundAmountFor(quantity);

      totalRefundAmount += itemRefundAmount;

      refundItems.add(
        RefundItem(
          productId: item.productId,
          productName: item.productName,
          quantity: quantity,
          refundAmount: itemRefundAmount,
        ),
      );

      item.refundedQuantity += quantity;

      final productIndex = _products.indexWhere(
        (product) => product.id == item.productId,
      );

      if (productIndex == -1) {
        return null;
      }

      final product = _products[productIndex];
      final beforeStock = product.stock;

      product.stock += quantity;

      final movement = StockMovement(
        id: _nextStockMovementId++,
        productId: product.id,
        productName: product.name,
        type: StockMovementType.refund,
        quantity: quantity,
        beforeStock: beforeStock,
        afterStock: product.stock,
        createdAt: now,
        referenceId: sale.receiptNumber,
      );

      _stockMovements.add(movement);
      unawaited(_database.upsertStockMovement(movement));
      unawaited(_database.upsertProduct(product));
    }

    final allRefunded = sale.items.every((item) => item.remainingQuantity == 0);

    sale.status = allRefunded
        ? SaleStatus.refunded
        : SaleStatus.partiallyRefunded;

    sale.refundedAt = now;
    unawaited(_database.upsertSale(sale));

    final refundId = _nextRefundTransactionId++;

    final refund = RefundTransaction(
      id: refundId,
      saleId: sale.id,
      receiptNumber: sale.receiptNumber,
      refundNumber: _createRefundNumber(refundId, now),
      items: refundItems,
      totalAmount: totalRefundAmount,
      reason: reason,
      processedBy: processedBy.trim().isEmpty ? '알 수 없음' : processedBy.trim(),
      createdAt: now,
      memo: memo == null || memo.trim().isEmpty ? null : memo.trim(),
    );

    _refundTransactions.add(refund);
    unawaited(_database.insertRefundTransaction(refund));

    _writeAudit(
      action: AuditAction.refund,
      targetType: 'REFUND',
      targetId: refund.id.toString(),
      targetName: refund.refundNumber,
      detail:
          '영수증 ${refund.receiptNumber} · 환불금액 ${refund.totalAmount}원 · '
          '사유 ${refund.reason.label} · 처리자 ${refund.processedBy}',
    );

    notifyListeners();

    return totalRefundAmount;
  }

  bool refundSale(
    int saleId, {
    RefundReason reason = RefundReason.customerChange,
    String processedBy = '시스템',
    String? memo,
  }) {
    final saleIndex = _sales.indexWhere((sale) => sale.id == saleId);

    if (saleIndex == -1) {
      return false;
    }

    final sale = _sales[saleIndex];

    if (sale.status == SaleStatus.refunded ||
        sale.status == SaleStatus.voided) {
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

    return refundSaleItems(
          saleId: saleId,
          refundQuantities: quantities,
          reason: reason,
          processedBy: processedBy,
          memo: memo,
        ) !=
        null;
  }

  bool canVoidSale({required Sale sale, required int activeShiftId}) {
    return sale.shiftId == activeShiftId && sale.canVoid;
  }

  bool voidSale({
    required int saleId,
    required int activeShiftId,
    required String reason,
  }) {
    final saleIndex = _sales.indexWhere((sale) => sale.id == saleId);

    if (saleIndex == -1) {
      return false;
    }

    final sale = _sales[saleIndex];

    if (!canVoidSale(sale: sale, activeShiftId: activeShiftId)) {
      return false;
    }

    final normalizedReason = reason.trim();

    if (normalizedReason.isEmpty) {
      return false;
    }

    final now = DateTime.now();

    for (final item in sale.items) {
      final productIndex = _products.indexWhere(
        (product) => product.id == item.productId,
      );

      if (productIndex == -1) {
        return false;
      }
    }

    for (final item in sale.items) {
      final productIndex = _products.indexWhere(
        (product) => product.id == item.productId,
      );

      final product = _products[productIndex];

      final beforeStock = product.stock;

      product.stock += item.quantity;

      final movement = StockMovement(
        id: _nextStockMovementId++,
        productId: product.id,
        productName: product.name,
        type: StockMovementType.adjustment,
        quantity: item.quantity,
        beforeStock: beforeStock,
        afterStock: product.stock,
        createdAt: now,
        referenceId: sale.receiptNumber,
        memo: '거래 취소 · $normalizedReason',
      );

      _stockMovements.add(movement);

      unawaited(_database.upsertStockMovement(movement));

      unawaited(_database.upsertProduct(product));
    }

    sale.status = SaleStatus.voided;
    sale.voidedAt = now;
    sale.voidedBy = _audit.currentUser?.name ?? 'SYSTEM';
    sale.voidReason = normalizedReason;

    unawaited(_database.upsertSale(sale));

    _writeAudit(
      action: AuditAction.saleVoid,
      targetType: 'SALE',
      targetId: sale.id.toString(),
      targetName: sale.receiptNumber,
      detail:
          '거래 취소 · ${sale.totalAmount}원 · '
          '사유 $normalizedReason · '
          '처리자 ${sale.voidedBy}',
    );

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
    required ProductCategory category,
    required String subCategory,
    required int price,
    required int costPrice,
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
      costPrice: costPrice,
      stock: stock,
      minimumStock: minimumStock,
      adultProduct: adultProduct,
      expirationDate: expirationDate,
    );

    _products.add(product);
    unawaited(_database.upsertProduct(product));

    _writeAudit(
      action: AuditAction.productCreate,
      targetType: 'PRODUCT',
      targetId: product.id.toString(),
      targetName: product.name,
      detail:
          '상품 등록 · 판매가 ${product.price}원 · 원가 ${product.costPrice}원 · '
          '초기재고 ${product.stock}개',
    );

    notifyListeners();
  }

  void updateProduct(Product product) {
    final index = _products.indexWhere((item) => item.id == product.id);

    if (index == -1) {
      return;
    }

    final before = _products[index];

    final priceChanged =
        before.price != product.price || before.costPrice != product.costPrice;

    if (priceChanged) {
      final history = PriceChangeHistory(
        id: _nextPriceChangeId++,
        productId: product.id,
        productName: product.name,
        beforePrice: before.price,
        afterPrice: product.price,
        beforeCostPrice: before.costPrice,
        afterCostPrice: product.costPrice,
        changedBy: _audit.currentUser?.name ?? 'SYSTEM',
        changedAt: DateTime.now(),
      );

      _priceChangeHistory.add(history);

      unawaited(_database.insertPriceChangeHistory(history));

      _writeAudit(
        action: AuditAction.priceChange,
        targetType: 'PRODUCT',
        targetId: product.id.toString(),
        targetName: product.name,
        detail:
            '가격 변경 · 판매가 ${before.price}원 → ${product.price}원 · '
            '원가 ${before.costPrice}원 → ${product.costPrice}원',
      );
    }

    _products[index] = product;

    unawaited(_database.upsertProduct(product));

    _writeAudit(
      action: AuditAction.productUpdate,
      targetType: 'PRODUCT',
      targetId: product.id.toString(),
      targetName: product.name,
      detail:
          '상품 수정 · 이름 ${before.name} → ${product.name} · '
          '판매가 ${before.price}원 → ${product.price}원 · '
          '원가 ${before.costPrice}원 → ${product.costPrice}원 · '
          '최소재고 ${before.minimumStock}개 → ${product.minimumStock}개',
    );

    notifyListeners();
  }

  bool deleteProduct(int productId) {
    if (_cart.containsKey(productId)) {
      return false;
    }

    if (_sales.any(
      (sale) => sale.items.any((item) => item.productId == productId),
    )) {
      return false;
    }

    final index = _products.indexWhere((product) => product.id == productId);

    if (index == -1) {
      return false;
    }

    final product = _products[index];

    _products.removeAt(index);
    _promotions.removeWhere((promotion) => promotion.productId == productId);
    _favoriteProductIds.remove(productId);

    unawaited(
      _database.setProductFavorite(productId: productId, favorite: false),
    );

    unawaited(_database.deleteProduct(productId));
    unawaited(_database.deletePromotionsForProduct(productId));

    _writeAudit(
      action: AuditAction.productDelete,
      targetType: 'PRODUCT',
      targetId: product.id.toString(),
      targetName: product.name,
      detail: '상품 삭제 · 바코드 ${product.barcode}',
    );

    notifyListeners();
    return true;
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

    final movement = StockMovement(
      id: _nextStockMovementId++,
      productId: product.id,
      productName: product.name,
      type: StockMovementType.adjustment,
      quantity: (actualStock - beforeStock).abs(),
      beforeStock: beforeStock,
      afterStock: actualStock,
      createdAt: DateTime.now(),
      memo: memo == null || memo.trim().isEmpty
          ? reason.label
          : '${reason.label} · ${memo.trim()}',
    );

    _stockMovements.add(movement);
    unawaited(_database.upsertStockMovement(movement));
    unawaited(_database.upsertProduct(product));

    _writeAudit(
      action: AuditAction.stockAdjust,
      targetType: 'PRODUCT',
      targetId: product.id.toString(),
      targetName: product.name,
      detail:
          '재고 $beforeStock개 → $actualStock개 · 사유 ${reason.label}'
          '${memo == null || memo.trim().isEmpty ? '' : ' · ${memo.trim()}'}',
    );

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

    final movement = StockMovement(
      id: _nextStockMovementId++,
      productId: product.id,
      productName: product.name,
      type: StockMovementType.restock,
      quantity: quantity,
      beforeStock: beforeStock,
      afterStock: product.stock,
      createdAt: DateTime.now(),
    );

    _stockMovements.add(movement);
    unawaited(_database.upsertStockMovement(movement));
    unawaited(_database.upsertProduct(product));

    _writeAudit(
      action: AuditAction.stockIn,
      targetType: 'PRODUCT',
      targetId: product.id.toString(),
      targetName: product.name,
      detail: '상품 입고 +$quantity개 · 재고 $beforeStock개 → ${product.stock}개',
    );

    notifyListeners();
  }

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

    final movement = StockMovement(
      id: _nextStockMovementId++,
      productId: product.id,
      productName: product.name,
      type: StockMovementType.disposal,
      quantity: quantity,
      beforeStock: beforeStock,
      afterStock: product.stock,
      createdAt: DateTime.now(),
      memo: memo,
    );

    _stockMovements.add(movement);
    unawaited(_database.upsertStockMovement(movement));
    unawaited(_database.upsertProduct(product));

    _writeAudit(
      action: AuditAction.stockDispose,
      targetType: 'PRODUCT',
      targetId: product.id.toString(),
      targetName: product.name,
      detail:
          '상품 폐기 -$quantity개 · 재고 $beforeStock개 → ${product.stock}개 · '
          '$memo',
    );

    notifyListeners();
    return true;
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
    unawaited(_database.upsertHeldCart(heldCart));

    _cart.clear();
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
    unawaited(_database.deleteHeldCart(heldCartId));

    notifyListeners();
    return true;
  }

  void deleteHeldCart(int heldCartId) {
    _heldCarts.removeWhere((cart) => cart.id == heldCartId);
    unawaited(_database.deleteHeldCart(heldCartId));
    notifyListeners();
  }

  String _createReceiptNumber(int saleId, DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');

    final dateText = '${date.year}${two(date.month)}${two(date.day)}';
    final number = saleId.toString().padLeft(4, '0');

    return 'R$dateText-$number';
  }

  String _createRefundNumber(int refundId, DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');

    final dateText = '${date.year}${two(date.month)}${two(date.day)}';
    final number = refundId.toString().padLeft(4, '0');

    return 'RF$dateText-$number';
  }
}
