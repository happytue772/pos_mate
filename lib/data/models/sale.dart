import 'sale_item.dart';

enum PaymentMethod { card, cash, mobile }

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.card:
        return '카드';

      case PaymentMethod.cash:
        return '현금';

      case PaymentMethod.mobile:
        return '모바일';
    }
  }
}

enum SaleStatus { completed, partiallyRefunded, refunded }

extension SaleStatusLabel on SaleStatus {
  String get label {
    switch (this) {
      case SaleStatus.completed:
        return '결제 완료';

      case SaleStatus.partiallyRefunded:
        return '부분 환불';

      case SaleStatus.refunded:
        return '전체 환불';
    }
  }
}

class Sale {
  Sale({
    required this.id,
    required this.shiftId,
    required this.receiptNumber,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    required this.cashierName,
    required this.soldAt,
    this.receivedAmount,
    this.changeAmount,
    this.status = SaleStatus.completed,
    this.refundedAt,
  });

  final int id;

  final int shiftId;

  final String receiptNumber;

  final List<SaleItem> items;

  final int totalAmount;

  final PaymentMethod paymentMethod;

  final String cashierName;

  final DateTime soldAt;

  final int? receivedAmount;

  final int? changeAmount;

  SaleStatus status;

  DateTime? refundedAt;

  int get refundedAmount {
    return items.fold<int>(0, (sum, item) => sum + item.refundedAmount);
  }

  int get netAmount {
    return totalAmount - refundedAmount;
  }
}
