enum StockMovementType { sale, restock, refund, adjustment }

extension StockMovementTypeLabel on StockMovementType {
  String get label {
    switch (this) {
      case StockMovementType.sale:
        return '판매';

      case StockMovementType.restock:
        return '입고';

      case StockMovementType.refund:
        return '환불';

      case StockMovementType.adjustment:
        return '재고 조정';
    }
  }
}

class StockMovement {
  const StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.beforeStock,
    required this.afterStock,
    required this.createdAt,
    this.referenceId,
  });

  final int id;

  final int productId;
  final String productName;

  final StockMovementType type;

  final int quantity;

  final int beforeStock;
  final int afterStock;

  final DateTime createdAt;

  final String? referenceId;
}
