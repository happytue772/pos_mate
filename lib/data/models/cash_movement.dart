enum CashMovementType { deposit, withdrawal }

extension CashMovementTypeLabel on CashMovementType {
  String get label {
    switch (this) {
      case CashMovementType.deposit:
        return '현금 입금';

      case CashMovementType.withdrawal:
        return '현금 출금';
    }
  }
}

class CashMovement {
  const CashMovement({
    required this.id,
    required this.shiftId,
    required this.type,
    required this.amount,
    required this.reason,
    required this.cashierName,
    required this.createdAt,
  });

  final int id;

  final int shiftId;

  final CashMovementType type;

  final int amount;

  final String reason;

  final String cashierName;

  final DateTime createdAt;
}
