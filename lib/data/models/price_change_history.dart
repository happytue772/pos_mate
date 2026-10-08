class PriceChangeHistory {
  const PriceChangeHistory({
    required this.id,
    required this.productId,
    required this.productName,
    required this.beforePrice,
    required this.afterPrice,
    required this.beforeCostPrice,
    required this.afterCostPrice,
    required this.changedBy,
    required this.changedAt,
  });

  final int id;
  final int productId;
  final String productName;
  final int beforePrice;
  final int afterPrice;
  final int beforeCostPrice;
  final int afterCostPrice;
  final String changedBy;
  final DateTime changedAt;

  bool get salePriceChanged => beforePrice != afterPrice;
  bool get costPriceChanged => beforeCostPrice != afterCostPrice;
}
