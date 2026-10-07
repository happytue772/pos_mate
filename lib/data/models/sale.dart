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

enum SaleStatus { completed, refunded }

extension SaleStatusLabel on SaleStatus {
  String get label {
    switch (this) {
      case SaleStatus.completed:
        return '결제 완료';

      case SaleStatus.refunded:
        return '환불 완료';
    }
  }
}

class Sale {
  Sale({
    required this.id,
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
}
