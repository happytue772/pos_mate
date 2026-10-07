import 'promotion.dart';

class SaleItem {
  SaleItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.promotionType,
    this.promotionPercent,
    this.promotionSpecialPrice,
    this.refundedQuantity = 0,
  });

  final int productId;
  final String productName;

  final int unitPrice;
  final int quantity;

  final PromotionType? promotionType;

  final int? promotionPercent;
  final int? promotionSpecialPrice;

  int refundedQuantity;

  int calculateAmountForQuantity(int quantity) {
    if (quantity <= 0) {
      return 0;
    }

    final promotion = promotionType;

    if (promotion == null) {
      return unitPrice * quantity;
    }

    switch (promotion) {
      case PromotionType.onePlusOne:
        final paidQuantity = (quantity + 1) ~/ 2;

        return unitPrice * paidQuantity;

      case PromotionType.twoPlusOne:
        final freeQuantity = quantity ~/ 3;

        final paidQuantity = quantity - freeQuantity;

        return unitPrice * paidQuantity;

      case PromotionType.percentDiscount:
        final percent = promotionPercent ?? 0;

        final discountedPrice = unitPrice * (100 - percent) ~/ 100;

        return discountedPrice * quantity;

      case PromotionType.specialPrice:
        final price = promotionSpecialPrice ?? unitPrice;

        return price * quantity;
    }
  }

  int get originalSubtotal {
    return unitPrice * quantity;
  }

  int get subtotal {
    return calculateAmountForQuantity(quantity);
  }

  int get discountAmount {
    return originalSubtotal - subtotal;
  }

  int get remainingQuantity {
    return quantity - refundedQuantity;
  }

  int get netAmount {
    return calculateAmountForQuantity(remainingQuantity);
  }

  int get refundedAmount {
    return subtotal - netAmount;
  }

  int refundAmountFor(int quantity) {
    if (quantity <= 0 || quantity > remainingQuantity) {
      return 0;
    }

    final before = calculateAmountForQuantity(remainingQuantity);

    final after = calculateAmountForQuantity(remainingQuantity - quantity);

    return before - after;
  }
}
