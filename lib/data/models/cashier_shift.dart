enum ShiftStatus { open, closed }

extension ShiftStatusLabel on ShiftStatus {
  String get label {
    switch (this) {
      case ShiftStatus.open:
        return '근무 중';
      case ShiftStatus.closed:
        return '근무 마감';
    }
  }
}

class ShiftSummary {
  const ShiftSummary({
    required this.completedSalesCount,
    required this.totalSales,
    required this.cashSales,
    required this.cardSales,
    required this.mobileSales,
    required this.refundCount,
    required this.refundAmount,
    required this.expectedCash,
  });

  final int completedSalesCount;

  final int totalSales;

  final int cashSales;
  final int cardSales;
  final int mobileSales;

  final int refundCount;
  final int refundAmount;

  final int expectedCash;
}

class CashierShift {
  CashierShift({
    required this.id,
    required this.cashierId,
    required this.cashierName,
    required this.openedAt,
    required this.openingCash,
    this.status = ShiftStatus.open,
    this.closedAt,
    this.actualCash,
    this.cashDifference,
    this.summary,
  });

  final int id;

  final int cashierId;
  final String cashierName;

  final DateTime openedAt;

  final int openingCash;

  ShiftStatus status;

  DateTime? closedAt;

  int? actualCash;

  int? cashDifference;

  ShiftSummary? summary;
}
