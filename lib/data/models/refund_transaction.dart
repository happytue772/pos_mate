enum RefundReason { customerChange, defective, wrongPayment, expired, other }

extension RefundReasonLabel on RefundReason {
  String get label {
    switch (this) {
      case RefundReason.customerChange:
        return '단순 변심';

      case RefundReason.defective:
        return '상품 불량';

      case RefundReason.wrongPayment:
        return '결제 오류';

      case RefundReason.expired:
        return '유통기한 / 품질 문제';

      case RefundReason.other:
        return '기타';
    }
  }
}

class RefundItem {
  const RefundItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.refundAmount,
  });

  final int productId;
  final String productName;
  final int quantity;
  final int refundAmount;
}

class RefundTransaction {
  const RefundTransaction({
    required this.id,
    required this.saleId,
    required this.receiptNumber,
    required this.refundNumber,
    required this.items,
    required this.totalAmount,
    required this.reason,
    required this.processedBy,
    required this.createdAt,
    this.memo,
  });

  final int id;
  final int saleId;
  final String receiptNumber;
  final String refundNumber;
  final List<RefundItem> items;
  final int totalAmount;
  final RefundReason reason;
  final String processedBy;
  final DateTime createdAt;
  final String? memo;
}
