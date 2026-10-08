enum PromotionType { onePlusOne, twoPlusOne, percentDiscount, specialPrice }

extension PromotionTypeLabel on PromotionType {
  String get label {
    switch (this) {
      case PromotionType.onePlusOne:
        return '1+1';

      case PromotionType.twoPlusOne:
        return '2+1';

      case PromotionType.percentDiscount:
        return '% 할인';

      case PromotionType.specialPrice:
        return '특가';
    }
  }
}

class Promotion {
  const Promotion({
    required this.id,
    required this.productId,
    required this.type,
    required this.startDate,
    required this.endDate,
    this.percent,
    this.specialPrice,
    this.enabled = true,
  });

  final int id;

  final int productId;

  final PromotionType type;

  final DateTime startDate;

  final DateTime endDate;

  final int? percent;

  final int? specialPrice;

  final bool enabled;

  bool get isActive {
    if (!enabled) {
      return false;
    }

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final start = DateTime(startDate.year, startDate.month, startDate.day);

    final end = DateTime(endDate.year, endDate.month, endDate.day);

    return !today.isBefore(start) && !today.isAfter(end);
  }

  Promotion copyWith({
    int? id,
    int? productId,
    PromotionType? type,
    DateTime? startDate,
    DateTime? endDate,
    int? percent,
    int? specialPrice,
    bool? enabled,
    bool clearPercent = false,
    bool clearSpecialPrice = false,
  }) {
    return Promotion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      percent: clearPercent ? null : percent ?? this.percent,
      specialPrice: clearSpecialPrice
          ? null
          : specialPrice ?? this.specialPrice,
      enabled: enabled ?? this.enabled,
    );
  }
}
