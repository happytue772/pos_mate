enum StockAdjustmentReason { damage, loss, stocktake, staffUse, other }

extension StockAdjustmentReasonLabel on StockAdjustmentReason {
  String get label {
    switch (this) {
      case StockAdjustmentReason.damage:
        return '파손';

      case StockAdjustmentReason.loss:
        return '분실';

      case StockAdjustmentReason.stocktake:
        return '재고 실사';

      case StockAdjustmentReason.staffUse:
        return '직원 사용';

      case StockAdjustmentReason.other:
        return '기타';
    }
  }
}
