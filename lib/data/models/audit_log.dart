enum AuditAction {
  productCreate,
  productUpdate,
  productDelete,
  promotionCreate,
  promotionUpdate,
  promotionDelete,
  stockIn,
  stockAdjust,
  stockDispose,
  refund,
  cashDeposit,
  cashWithdrawal,
  shiftOpen,
  shiftClose,
}

extension AuditActionLabel on AuditAction {
  String get label {
    switch (this) {
      case AuditAction.productCreate:
        return '상품 등록';
      case AuditAction.productUpdate:
        return '상품 수정';
      case AuditAction.productDelete:
        return '상품 삭제';
      case AuditAction.promotionCreate:
        return '행사 등록';
      case AuditAction.promotionUpdate:
        return '행사 수정';
      case AuditAction.promotionDelete:
        return '행사 삭제';
      case AuditAction.stockIn:
        return '상품 입고';
      case AuditAction.stockAdjust:
        return '재고 조정';
      case AuditAction.stockDispose:
        return '상품 폐기';
      case AuditAction.refund:
        return '환불 처리';
      case AuditAction.cashDeposit:
        return '현금 입금';
      case AuditAction.cashWithdrawal:
        return '현금 출금';
      case AuditAction.shiftOpen:
        return '근무 시작';
      case AuditAction.shiftClose:
        return '근무 마감';
    }
  }
}

class AuditLog {
  const AuditLog({
    this.id,
    required this.actorName,
    required this.actorRole,
    required this.action,
    required this.targetType,
    required this.detail,
    required this.createdAt,
    this.targetId,
    this.targetName,
  });

  final int? id;
  final String actorName;
  final String actorRole;
  final AuditAction action;
  final String targetType;
  final String? targetId;
  final String? targetName;
  final String detail;
  final DateTime createdAt;
}
