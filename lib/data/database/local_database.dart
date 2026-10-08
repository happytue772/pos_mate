import 'package:sqflite/sqflite.dart';

import 'database_platform_stub.dart'
    if (dart.library.js_interop) 'database_platform_web.dart';

import '../models/audit_log.dart';
import '../models/cash_movement.dart';
import '../models/cashier_shift.dart';
import '../models/held_cart.dart';
import '../models/product.dart';
import '../models/price_change_history.dart';
import '../models/promotion.dart';
import '../models/refund_transaction.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../models/stock_movement.dart';
import '../models/staff_account.dart';

class LocalDatabase {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    configureDatabasePlatform();

    final path = await resolvePosMateDatabasePath();

    return openDatabase(
      path,
      version: 6,
      onCreate: (db, version) async {
        await _createTables(db);
        await _ensureShiftSummaryColumns(db);
        await _ensureSaleVoidColumns(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _createTables(db);
        await _ensureShiftSummaryColumns(db);
        await _ensureSaleVoidColumns(db);
      },
      onOpen: (db) async {
        await _createTables(db);
        await _ensureShiftSummaryColumns(db);
        await _ensureSaleVoidColumns(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY,
        barcode TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        sub_category TEXT NOT NULL,
        price INTEGER NOT NULL,
        cost_price INTEGER NOT NULL DEFAULT 0,
        stock INTEGER NOT NULL,
        minimum_stock INTEGER NOT NULL,
        adult_product INTEGER NOT NULL DEFAULT 0,
        expiration_date TEXT
      )
      ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales (
        id INTEGER PRIMARY KEY,
        shift_id INTEGER NOT NULL,
        receipt_number TEXT NOT NULL UNIQUE,
        total_amount INTEGER NOT NULL,
        payment_method TEXT NOT NULL,
        cashier_name TEXT NOT NULL,
        sold_at TEXT NOT NULL,
        received_amount INTEGER,
        change_amount INTEGER,
        status TEXT NOT NULL,
        refunded_at TEXT,
        voided_at TEXT,
        voided_by TEXT,
        void_reason TEXT
      )
      ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        unit_price INTEGER NOT NULL,
        unit_cost INTEGER NOT NULL DEFAULT 0,
        quantity INTEGER NOT NULL,
        refunded_quantity INTEGER NOT NULL DEFAULT 0,
        promotion_type TEXT,
        promotion_percent INTEGER,
        promotion_special_price INTEGER
      )
      ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS refund_transactions (
        id INTEGER PRIMARY KEY,
        sale_id INTEGER NOT NULL,
        receipt_number TEXT NOT NULL,
        refund_number TEXT NOT NULL UNIQUE,
        total_amount INTEGER NOT NULL,
        reason TEXT NOT NULL,
        processed_by TEXT NOT NULL,
        created_at TEXT NOT NULL,
        memo TEXT
      )
      ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS refund_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        refund_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        refund_amount INTEGER NOT NULL
      )
      ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS stock_movements (
        id INTEGER PRIMARY KEY,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        before_stock INTEGER NOT NULL,
        after_stock INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        reference_id TEXT,
        memo TEXT
      )
      ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS promotions (
        id INTEGER PRIMARY KEY,
        product_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        percent INTEGER,
        special_price INTEGER,
        enabled INTEGER NOT NULL DEFAULT 1
      )
      ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS held_carts (
        id INTEGER PRIMARY KEY,
        cashier_name TEXT NOT NULL,
        total_amount INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
      ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS held_cart_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        held_cart_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL
      )
      ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS shifts (
        id INTEGER PRIMARY KEY,
        cashier_id INTEGER NOT NULL,
        cashier_name TEXT NOT NULL,
        opened_at TEXT NOT NULL,
        opening_cash INTEGER NOT NULL,
        status TEXT NOT NULL,
        closed_at TEXT,
        actual_cash INTEGER,
        cash_difference INTEGER,
        summary_completed_sales_count INTEGER,
        summary_total_sales INTEGER,
        summary_cash_sales INTEGER,
        summary_card_sales INTEGER,
        summary_mobile_sales INTEGER,
        summary_refund_count INTEGER,
        summary_refund_amount INTEGER,
        summary_cash_in_amount INTEGER,
        summary_cash_out_amount INTEGER,
        summary_expected_cash INTEGER
      )
      ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cash_movements (
        id INTEGER PRIMARY KEY,
        shift_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        amount INTEGER NOT NULL,
        reason TEXT NOT NULL,
        cashier_name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
      ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        actor_name TEXT NOT NULL,
        actor_role TEXT NOT NULL,
        action TEXT NOT NULL,
        target_type TEXT NOT NULL,
        target_id TEXT,
        target_name TEXT,
        detail TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
      ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS product_favorites (
        product_id INTEGER PRIMARY KEY,
        created_at TEXT NOT NULL
      )
      ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS price_change_history (
        id INTEGER PRIMARY KEY,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        before_price INTEGER NOT NULL,
        after_price INTEGER NOT NULL,
        before_cost_price INTEGER NOT NULL,
        after_cost_price INTEGER NOT NULL,
        changed_by TEXT NOT NULL,
        changed_at TEXT NOT NULL
      )
      ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS staff_accounts (
        id INTEGER PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        password TEXT NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
      ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sale_items_sale_id
      ON sale_items(sale_id)
      ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_refund_transactions_sale_id
      ON refund_transactions(sale_id)
      ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_refund_items_refund_id
      ON refund_items(refund_id)
      ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_stock_movements_product_id
      ON stock_movements(product_id)
      ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_held_cart_items_cart_id
      ON held_cart_items(held_cart_id)
      ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_cash_movements_shift_id
      ON cash_movements(shift_id)
      ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_promotions_product_id
      ON promotions(product_id)
      ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at
      ON audit_logs(created_at)
      ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_audit_logs_action
      ON audit_logs(action)
      ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_price_change_product
      ON price_change_history(product_id, changed_at)
      ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_staff_accounts_username
      ON staff_accounts(username)
      ''');
  }

  Future<void> _ensureShiftSummaryColumns(Database db) async {
    final info = await db.rawQuery('PRAGMA table_info(shifts)');
    final columns = info.map((row) => row['name'] as String).toSet();

    Future<void> addColumn(String column) async {
      if (columns.contains(column)) {
        return;
      }

      await db.execute('ALTER TABLE shifts ADD COLUMN $column INTEGER');

      columns.add(column);
    }

    await addColumn('summary_completed_sales_count');
    await addColumn('summary_total_sales');
    await addColumn('summary_cash_sales');
    await addColumn('summary_card_sales');
    await addColumn('summary_mobile_sales');
    await addColumn('summary_refund_count');
    await addColumn('summary_refund_amount');
    await addColumn('summary_cash_in_amount');
    await addColumn('summary_cash_out_amount');
    await addColumn('summary_expected_cash');
  }

  Future<void> _ensureSaleVoidColumns(Database db) async {
    final info = await db.rawQuery('PRAGMA table_info(sales)');

    final columns = info.map((row) => row['name'] as String).toSet();

    Future<void> addTextColumn(String column) async {
      if (columns.contains(column)) {
        return;
      }

      await db.execute('ALTER TABLE sales ADD COLUMN $column TEXT');

      columns.add(column);
    }

    await addTextColumn('voided_at');
    await addTextColumn('voided_by');
    await addTextColumn('void_reason');
  }

  Future<List<Product>> getProducts() async {
    final db = await database;
    final rows = await db.query('products', orderBy: 'id ASC');

    return rows.map((row) {
      return Product(
        id: row['id'] as int,
        barcode: row['barcode'] as String,
        name: row['name'] as String,
        category: ProductCategory.values.byName(row['category'] as String),
        subCategory: row['sub_category'] as String,
        price: row['price'] as int,
        costPrice: row['cost_price'] as int,
        stock: row['stock'] as int,
        minimumStock: row['minimum_stock'] as int,
        adultProduct: (row['adult_product'] as int) == 1,
        expirationDate: row['expiration_date'] == null
            ? null
            : DateTime.parse(row['expiration_date'] as String),
      );
    }).toList();
  }

  Future<void> upsertProduct(Product product) async {
    final db = await database;

    await db.insert('products', {
      'id': product.id,
      'barcode': product.barcode,
      'name': product.name,
      'category': product.category.name,
      'sub_category': product.subCategory,
      'price': product.price,
      'cost_price': product.costPrice,
      'stock': product.stock,
      'minimum_stock': product.minimumStock,
      'adult_product': product.adultProduct ? 1 : 0,
      'expiration_date': product.expirationDate?.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertProducts(List<Product> products) async {
    final db = await database;
    final batch = db.batch();

    for (final product in products) {
      batch.insert('products', {
        'id': product.id,
        'barcode': product.barcode,
        'name': product.name,
        'category': product.category.name,
        'sub_category': product.subCategory,
        'price': product.price,
        'cost_price': product.costPrice,
        'stock': product.stock,
        'minimum_stock': product.minimumStock,
        'adult_product': product.adultProduct ? 1 : 0,
        'expiration_date': product.expirationDate?.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  Future<void> deleteProduct(int productId) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [productId]);
  }

  Future<List<Sale>> getSales() async {
    final db = await database;
    final rows = await db.query('sales', orderBy: 'id ASC');
    final result = <Sale>[];

    for (final row in rows) {
      final saleId = row['id'] as int;

      final itemRows = await db.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleId],
        orderBy: 'id ASC',
      );

      final items = itemRows.map((item) {
        final promotionType = item['promotion_type'];

        return SaleItem(
          productId: item['product_id'] as int,
          productName: item['product_name'] as String,
          unitPrice: item['unit_price'] as int,
          unitCost: item['unit_cost'] as int,
          quantity: item['quantity'] as int,
          refundedQuantity: item['refunded_quantity'] as int,
          promotionType: promotionType == null
              ? null
              : PromotionType.values.byName(promotionType as String),
          promotionPercent: item['promotion_percent'] as int?,
          promotionSpecialPrice: item['promotion_special_price'] as int?,
        );
      }).toList();

      result.add(
        Sale(
          id: saleId,
          shiftId: row['shift_id'] as int,
          receiptNumber: row['receipt_number'] as String,
          items: items,
          totalAmount: row['total_amount'] as int,
          paymentMethod: PaymentMethod.values.byName(
            row['payment_method'] as String,
          ),
          cashierName: row['cashier_name'] as String,
          soldAt: DateTime.parse(row['sold_at'] as String),
          receivedAmount: row['received_amount'] as int?,
          changeAmount: row['change_amount'] as int?,
          status: SaleStatus.values.byName(row['status'] as String),
          refundedAt: row['refunded_at'] == null
              ? null
              : DateTime.parse(row['refunded_at'] as String),
          voidedAt: row['voided_at'] == null
              ? null
              : DateTime.parse(row['voided_at'] as String),
          voidedBy: row['voided_by'] as String?,
          voidReason: row['void_reason'] as String?,
        ),
      );
    }

    return result;
  }

  Future<void> upsertSale(Sale sale) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.insert('sales', {
        'id': sale.id,
        'shift_id': sale.shiftId,
        'receipt_number': sale.receiptNumber,
        'total_amount': sale.totalAmount,
        'payment_method': sale.paymentMethod.name,
        'cashier_name': sale.cashierName,
        'sold_at': sale.soldAt.toIso8601String(),
        'received_amount': sale.receivedAmount,
        'change_amount': sale.changeAmount,
        'status': sale.status.name,
        'refunded_at': sale.refundedAt?.toIso8601String(),
        'voided_at': sale.voidedAt?.toIso8601String(),
        'voided_by': sale.voidedBy,
        'void_reason': sale.voidReason,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await txn.delete(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [sale.id],
      );

      for (final item in sale.items) {
        await txn.insert('sale_items', {
          'sale_id': sale.id,
          'product_id': item.productId,
          'product_name': item.productName,
          'unit_price': item.unitPrice,
          'unit_cost': item.unitCost,
          'quantity': item.quantity,
          'refunded_quantity': item.refundedQuantity,
          'promotion_type': item.promotionType?.name,
          'promotion_percent': item.promotionPercent,
          'promotion_special_price': item.promotionSpecialPrice,
        });
      }
    });
  }

  Future<List<RefundTransaction>> getRefundTransactions() async {
    final db = await database;
    final rows = await db.query('refund_transactions', orderBy: 'id ASC');
    final result = <RefundTransaction>[];

    for (final row in rows) {
      final refundId = row['id'] as int;

      final itemRows = await db.query(
        'refund_items',
        where: 'refund_id = ?',
        whereArgs: [refundId],
        orderBy: 'id ASC',
      );

      final items = itemRows.map((item) {
        return RefundItem(
          productId: item['product_id'] as int,
          productName: item['product_name'] as String,
          quantity: item['quantity'] as int,
          refundAmount: item['refund_amount'] as int,
        );
      }).toList();

      result.add(
        RefundTransaction(
          id: refundId,
          saleId: row['sale_id'] as int,
          receiptNumber: row['receipt_number'] as String,
          refundNumber: row['refund_number'] as String,
          items: items,
          totalAmount: row['total_amount'] as int,
          reason: RefundReason.values.byName(row['reason'] as String),
          processedBy: row['processed_by'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
          memo: row['memo'] as String?,
        ),
      );
    }

    return result;
  }

  Future<void> insertRefundTransaction(RefundTransaction refund) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.insert('refund_transactions', {
        'id': refund.id,
        'sale_id': refund.saleId,
        'receipt_number': refund.receiptNumber,
        'refund_number': refund.refundNumber,
        'total_amount': refund.totalAmount,
        'reason': refund.reason.name,
        'processed_by': refund.processedBy,
        'created_at': refund.createdAt.toIso8601String(),
        'memo': refund.memo,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await txn.delete(
        'refund_items',
        where: 'refund_id = ?',
        whereArgs: [refund.id],
      );

      for (final item in refund.items) {
        await txn.insert('refund_items', {
          'refund_id': refund.id,
          'product_id': item.productId,
          'product_name': item.productName,
          'quantity': item.quantity,
          'refund_amount': item.refundAmount,
        });
      }
    });
  }

  Future<List<StockMovement>> getStockMovements() async {
    final db = await database;
    final rows = await db.query('stock_movements', orderBy: 'id ASC');

    return rows.map((row) {
      return StockMovement(
        id: row['id'] as int,
        productId: row['product_id'] as int,
        productName: row['product_name'] as String,
        type: StockMovementType.values.byName(row['type'] as String),
        quantity: row['quantity'] as int,
        beforeStock: row['before_stock'] as int,
        afterStock: row['after_stock'] as int,
        createdAt: DateTime.parse(row['created_at'] as String),
        referenceId: row['reference_id'] as String?,
        memo: row['memo'] as String?,
      );
    }).toList();
  }

  Future<void> upsertStockMovement(StockMovement movement) async {
    final db = await database;

    await db.insert('stock_movements', {
      'id': movement.id,
      'product_id': movement.productId,
      'product_name': movement.productName,
      'type': movement.type.name,
      'quantity': movement.quantity,
      'before_stock': movement.beforeStock,
      'after_stock': movement.afterStock,
      'created_at': movement.createdAt.toIso8601String(),
      'reference_id': movement.referenceId,
      'memo': movement.memo,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Promotion>> getPromotions() async {
    final db = await database;
    final rows = await db.query('promotions', orderBy: 'id ASC');

    return rows.map((row) {
      return Promotion(
        id: row['id'] as int,
        productId: row['product_id'] as int,
        type: PromotionType.values.byName(row['type'] as String),
        startDate: DateTime.parse(row['start_date'] as String),
        endDate: DateTime.parse(row['end_date'] as String),
        percent: row['percent'] as int?,
        specialPrice: row['special_price'] as int?,
        enabled: (row['enabled'] as int) == 1,
      );
    }).toList();
  }

  Future<void> upsertPromotion(Promotion promotion) async {
    final db = await database;

    await db.insert('promotions', {
      'id': promotion.id,
      'product_id': promotion.productId,
      'type': promotion.type.name,
      'start_date': promotion.startDate.toIso8601String(),
      'end_date': promotion.endDate.toIso8601String(),
      'percent': promotion.percent,
      'special_price': promotion.specialPrice,
      'enabled': promotion.enabled ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertPromotions(List<Promotion> promotions) async {
    final db = await database;
    final batch = db.batch();

    for (final promotion in promotions) {
      batch.insert('promotions', {
        'id': promotion.id,
        'product_id': promotion.productId,
        'type': promotion.type.name,
        'start_date': promotion.startDate.toIso8601String(),
        'end_date': promotion.endDate.toIso8601String(),
        'percent': promotion.percent,
        'special_price': promotion.specialPrice,
        'enabled': promotion.enabled ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  Future<void> deletePromotion(int promotionId) async {
    final db = await database;
    await db.delete('promotions', where: 'id = ?', whereArgs: [promotionId]);
  }

  Future<void> deletePromotionsForProduct(int productId) async {
    final db = await database;
    await db.delete(
      'promotions',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
  }

  Future<List<HeldCart>> getHeldCarts() async {
    final db = await database;
    final rows = await db.query('held_carts', orderBy: 'id ASC');
    final result = <HeldCart>[];

    for (final row in rows) {
      final cartId = row['id'] as int;

      final itemRows = await db.query(
        'held_cart_items',
        where: 'held_cart_id = ?',
        whereArgs: [cartId],
        orderBy: 'id ASC',
      );

      final items = <int, int>{};

      for (final item in itemRows) {
        items[item['product_id'] as int] = item['quantity'] as int;
      }

      result.add(
        HeldCart(
          id: cartId,
          items: items,
          createdAt: DateTime.parse(row['created_at'] as String),
          cashierName: row['cashier_name'] as String,
          totalAmount: row['total_amount'] as int,
        ),
      );
    }

    return result;
  }

  Future<void> upsertHeldCart(HeldCart cart) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.insert('held_carts', {
        'id': cart.id,
        'cashier_name': cart.cashierName,
        'total_amount': cart.totalAmount,
        'created_at': cart.createdAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await txn.delete(
        'held_cart_items',
        where: 'held_cart_id = ?',
        whereArgs: [cart.id],
      );

      for (final entry in cart.items.entries) {
        await txn.insert('held_cart_items', {
          'held_cart_id': cart.id,
          'product_id': entry.key,
          'quantity': entry.value,
        });
      }
    });
  }

  Future<void> deleteHeldCart(int heldCartId) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete(
        'held_cart_items',
        where: 'held_cart_id = ?',
        whereArgs: [heldCartId],
      );
      await txn.delete('held_carts', where: 'id = ?', whereArgs: [heldCartId]);
    });
  }

  Future<List<CashierShift>> getShifts() async {
    final db = await database;
    final rows = await db.query('shifts', orderBy: 'id ASC');

    return rows.map((row) {
      ShiftSummary? summary;

      if (row['summary_expected_cash'] != null) {
        summary = ShiftSummary(
          completedSalesCount:
              (row['summary_completed_sales_count'] as int?) ?? 0,
          totalSales: (row['summary_total_sales'] as int?) ?? 0,
          cashSales: (row['summary_cash_sales'] as int?) ?? 0,
          cardSales: (row['summary_card_sales'] as int?) ?? 0,
          mobileSales: (row['summary_mobile_sales'] as int?) ?? 0,
          refundCount: (row['summary_refund_count'] as int?) ?? 0,
          refundAmount: (row['summary_refund_amount'] as int?) ?? 0,
          cashInAmount: (row['summary_cash_in_amount'] as int?) ?? 0,
          cashOutAmount: (row['summary_cash_out_amount'] as int?) ?? 0,
          expectedCash: row['summary_expected_cash'] as int,
        );
      }

      return CashierShift(
        id: row['id'] as int,
        cashierId: row['cashier_id'] as int,
        cashierName: row['cashier_name'] as String,
        openedAt: DateTime.parse(row['opened_at'] as String),
        openingCash: row['opening_cash'] as int,
        status: ShiftStatus.values.byName(row['status'] as String),
        closedAt: row['closed_at'] == null
            ? null
            : DateTime.parse(row['closed_at'] as String),
        actualCash: row['actual_cash'] as int?,
        cashDifference: row['cash_difference'] as int?,
        summary: summary,
      );
    }).toList();
  }

  Future<void> upsertShift(CashierShift shift) async {
    final db = await database;
    final summary = shift.summary;

    await db.insert('shifts', {
      'id': shift.id,
      'cashier_id': shift.cashierId,
      'cashier_name': shift.cashierName,
      'opened_at': shift.openedAt.toIso8601String(),
      'opening_cash': shift.openingCash,
      'status': shift.status.name,
      'closed_at': shift.closedAt?.toIso8601String(),
      'actual_cash': shift.actualCash,
      'cash_difference': shift.cashDifference,
      'summary_completed_sales_count': summary?.completedSalesCount,
      'summary_total_sales': summary?.totalSales,
      'summary_cash_sales': summary?.cashSales,
      'summary_card_sales': summary?.cardSales,
      'summary_mobile_sales': summary?.mobileSales,
      'summary_refund_count': summary?.refundCount,
      'summary_refund_amount': summary?.refundAmount,
      'summary_cash_in_amount': summary?.cashInAmount,
      'summary_cash_out_amount': summary?.cashOutAmount,
      'summary_expected_cash': summary?.expectedCash,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<CashMovement>> getCashMovements() async {
    final db = await database;
    final rows = await db.query('cash_movements', orderBy: 'id ASC');

    return rows.map((row) {
      return CashMovement(
        id: row['id'] as int,
        shiftId: row['shift_id'] as int,
        type: CashMovementType.values.byName(row['type'] as String),
        amount: row['amount'] as int,
        reason: row['reason'] as String,
        cashierName: row['cashier_name'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
    }).toList();
  }

  Future<void> upsertCashMovement(CashMovement movement) async {
    final db = await database;

    await db.insert('cash_movements', {
      'id': movement.id,
      'shift_id': movement.shiftId,
      'type': movement.type.name,
      'amount': movement.amount,
      'reason': movement.reason,
      'cashier_name': movement.cashierName,
      'created_at': movement.createdAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Set<int>> getFavoriteProductIds() async {
    final db = await database;

    final rows = await db.query('product_favorites', orderBy: 'created_at ASC');

    return rows.map((row) => row['product_id'] as int).toSet();
  }

  Future<void> setProductFavorite({
    required int productId,
    required bool favorite,
  }) async {
    final db = await database;

    if (favorite) {
      await db.insert('product_favorites', {
        'product_id': productId,
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return;
    }

    await db.delete(
      'product_favorites',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
  }

  Future<List<PriceChangeHistory>> getPriceChangeHistory() async {
    final db = await database;

    final rows = await db.query(
      'price_change_history',
      orderBy: 'changed_at DESC, id DESC',
    );

    return rows.map((row) {
      return PriceChangeHistory(
        id: row['id'] as int,
        productId: row['product_id'] as int,
        productName: row['product_name'] as String,
        beforePrice: row['before_price'] as int,
        afterPrice: row['after_price'] as int,
        beforeCostPrice: row['before_cost_price'] as int,
        afterCostPrice: row['after_cost_price'] as int,
        changedBy: row['changed_by'] as String,
        changedAt: DateTime.parse(row['changed_at'] as String),
      );
    }).toList();
  }

  Future<void> insertPriceChangeHistory(PriceChangeHistory history) async {
    final db = await database;

    await db.insert('price_change_history', {
      'id': history.id,
      'product_id': history.productId,
      'product_name': history.productName,
      'before_price': history.beforePrice,
      'after_price': history.afterPrice,
      'before_cost_price': history.beforeCostPrice,
      'after_cost_price': history.afterCostPrice,
      'changed_by': history.changedBy,
      'changed_at': history.changedAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<StaffAccount>> getStaffAccounts() async {
    final db = await database;

    final rows = await db.query('staff_accounts', orderBy: 'id ASC');

    return rows.map((row) {
      return StaffAccount(
        id: row['id'] as int,
        username: row['username'] as String,
        name: row['name'] as String,
        password: row['password'] as String,
        enabled: (row['enabled'] as int) == 1,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
    }).toList();
  }

  Future<void> upsertStaffAccount(StaffAccount account) async {
    final db = await database;

    await db.insert('staff_accounts', {
      'id': account.id,
      'username': account.username,
      'name': account.name,
      'password': account.password,
      'enabled': account.enabled ? 1 : 0,
      'created_at': account.createdAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> insertAuditLog(AuditLog log) async {
    final db = await database;

    return db.insert('audit_logs', {
      'actor_name': log.actorName,
      'actor_role': log.actorRole,
      'action': log.action.name,
      'target_type': log.targetType,
      'target_id': log.targetId,
      'target_name': log.targetName,
      'detail': log.detail,
      'created_at': log.createdAt.toIso8601String(),
    });
  }

  Future<List<AuditLog>> getAuditLogs() async {
    final db = await database;

    final rows = await db.query(
      'audit_logs',
      orderBy: 'created_at DESC, id DESC',
    );

    return rows.map((row) {
      return AuditLog(
        id: row['id'] as int,
        actorName: row['actor_name'] as String,
        actorRole: row['actor_role'] as String,
        action: AuditAction.values.byName(row['action'] as String),
        targetType: row['target_type'] as String,
        targetId: row['target_id'] as String?,
        targetName: row['target_name'] as String?,
        detail: row['detail'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
    }).toList();
  }

  Future<void> deleteEverything() async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete('product_favorites');
      await txn.delete('price_change_history');
      await txn.delete('staff_accounts');
      await txn.delete('audit_logs');
      await txn.delete('held_cart_items');
      await txn.delete('held_carts');
      await txn.delete('cash_movements');
      await txn.delete('shifts');
      await txn.delete('refund_items');
      await txn.delete('refund_transactions');
      await txn.delete('stock_movements');
      await txn.delete('sale_items');
      await txn.delete('sales');
      await txn.delete('promotions');
      await txn.delete('products');
    });
  }
}
