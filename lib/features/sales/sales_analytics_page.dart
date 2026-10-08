import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/product.dart';
import '../../data/models/sale.dart';
import '../../providers/pos_provider.dart';

enum AnalysisPeriod { today, all }

extension AnalysisPeriodLabel on AnalysisPeriod {
  String get label {
    switch (this) {
      case AnalysisPeriod.today:
        return '오늘';

      case AnalysisPeriod.all:
        return '전체';
    }
  }
}

class SalesAnalyticsPage extends StatefulWidget {
  const SalesAnalyticsPage({super.key});

  @override
  State<SalesAnalyticsPage> createState() => _SalesAnalyticsPageState();
}

class _SalesAnalyticsPageState extends State<SalesAnalyticsPage> {
  AnalysisPeriod _period = AnalysisPeriod.today;

  bool _isToday(DateTime value) {
    final now = DateTime.now();

    return value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
  }

  String _categoryLabel(PosProvider pos, int productId) {
    for (final product in pos.products) {
      if (product.id == productId) {
        return product.category.label;
      }
    }

    return '기타';
  }

  String _hourLabel(int hour) {
    final value = hour.toString().padLeft(2, '0');

    return '$value시';
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();

    final sales = pos.sales.where((sale) {
      switch (_period) {
        case AnalysisPeriod.today:
          return _isToday(sale.soldAt);

        case AnalysisPeriod.all:
          return true;
      }
    }).toList();

    // =========================================================
    // 핵심 매출 지표
    // =========================================================

    final grossSales = sales.fold<int>(
      0,
      (sum, sale) => sum + sale.totalAmount,
    );

    final refundAmount = sales.fold<int>(
      0,
      (sum, sale) => sum + sale.refundedAmount,
    );

    final netSales = sales.fold<int>(0, (sum, sale) => sum + sale.netAmount);

    final transactionCount = sales.where((sale) => sale.netAmount > 0).length;

    final refundTransactionCount = sales
        .where((sale) => sale.refundedAmount > 0)
        .length;

    final averageOrderValue = transactionCount <= 0
        ? 0
        : netSales ~/ transactionCount;

    // =========================================================
    // 원가 / 이익 / 마진
    // =========================================================

    final totalCost = sales.fold<int>(0, (saleSum, sale) {
      final saleCost = sale.items.fold<int>(0, (itemSum, item) {
        return itemSum + item.netCostAmount;
      });

      return saleSum + saleCost;
    });

    final grossProfit = netSales - totalCost;

    final marginRate = netSales <= 0 ? 0.0 : grossProfit / netSales * 100;

    // =========================================================
    // 할인 금액
    // =========================================================

    final discountAmount = sales.fold<int>(0, (saleSum, sale) {
      return saleSum +
          sale.items.fold<int>(0, (itemSum, item) {
            return itemSum + item.discountAmount;
          });
    });

    // =========================================================
    // 결제수단별
    // =========================================================

    final paymentTotals = <PaymentMethod, int>{
      for (final method in PaymentMethod.values) method: 0,
    };

    // =========================================================
    // 카테고리별
    // =========================================================

    final categoryTotals = <String, int>{};

    final categoryProfits = <String, int>{};

    // =========================================================
    // 상품별
    // =========================================================

    final productRevenue = <String, int>{};

    final productQuantity = <String, int>{};

    final productProfit = <String, int>{};

    // =========================================================
    // 시간대별
    // =========================================================

    final hourlyTotals = <int, int>{};

    // =========================================================
    // 직원별
    // =========================================================

    final cashierTotals = <String, int>{};

    final cashierCounts = <String, int>{};

    for (final sale in sales) {
      // 결제수단
      paymentTotals[sale.paymentMethod] =
          (paymentTotals[sale.paymentMethod] ?? 0) + sale.netAmount;

      // 시간대
      hourlyTotals[sale.soldAt.hour] =
          (hourlyTotals[sale.soldAt.hour] ?? 0) + sale.netAmount;

      // 직원
      cashierTotals[sale.cashierName] =
          (cashierTotals[sale.cashierName] ?? 0) + sale.netAmount;

      if (sale.netAmount > 0) {
        cashierCounts[sale.cashierName] =
            (cashierCounts[sale.cashierName] ?? 0) + 1;
      }

      // 상품별 / 카테고리별
      for (final item in sale.items) {
        final category = _categoryLabel(pos, item.productId);

        categoryTotals[category] =
            (categoryTotals[category] ?? 0) + item.netAmount;

        categoryProfits[category] =
            (categoryProfits[category] ?? 0) + item.grossProfit;

        productRevenue[item.productName] =
            (productRevenue[item.productName] ?? 0) + item.netAmount;

        productQuantity[item.productName] =
            (productQuantity[item.productName] ?? 0) + item.remainingQuantity;

        productProfit[item.productName] =
            (productProfit[item.productName] ?? 0) + item.grossProfit;
      }
    }

    final categoryEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topProducts = productRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final hourlyEntries = hourlyTotals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final cashierEntries = cashierTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('매출 분석')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // =====================================================
          // 기간 선택
          // =====================================================

          SegmentedButton<AnalysisPeriod>(
            segments: AnalysisPeriod.values.map((period) {
              return ButtonSegment<AnalysisPeriod>(
                value: period,
                label: Text(period.label),
              );
            }).toList(),
            selected: {_period},
            onSelectionChanged: (value) {
              setState(() {
                _period = value.first;
              });
            },
          ),

          const SizedBox(height: 20),

          // =====================================================
          // 기본 매출
          // =====================================================
          const _SectionTitle(title: '매출 요약'),

          _MetricCard(
            title: '총 결제금액',
            value: '$grossSales원',
            icon: Icons.receipt_long_outlined,
          ),

          _MetricCard(
            title: '환불 금액',
            value: '$refundAmount원',
            icon: Icons.undo_outlined,
          ),

          _MetricCard(
            title: '순매출',
            value: '$netSales원',
            icon: Icons.payments_outlined,
          ),

          _MetricCard(
            title: '판매 건수',
            value: '$transactionCount건',
            icon: Icons.shopping_cart_outlined,
          ),

          _MetricCard(
            title: '환불 발생 건수',
            value: '$refundTransactionCount건',
            icon: Icons.assignment_return_outlined,
          ),

          _MetricCard(
            title: '객단가',
            value: '$averageOrderValue원',
            icon: Icons.person_outline,
          ),

          _MetricCard(
            title: '행사 / 할인 금액',
            value: '$discountAmount원',
            icon: Icons.local_offer_outlined,
          ),

          const SizedBox(height: 24),

          // =====================================================
          // 손익
          // =====================================================
          const _SectionTitle(title: '손익 분석'),

          _MetricCard(
            title: '판매 원가',
            value: '$totalCost원',
            icon: Icons.inventory_outlined,
          ),

          _MetricCard(
            title: '매출이익',
            value: '$grossProfit원',
            icon: Icons.trending_up,
          ),

          _MetricCard(
            title: '마진율',
            value: '${marginRate.toStringAsFixed(1)}%',
            icon: Icons.percent,
          ),

          const SizedBox(height: 24),

          // =====================================================
          // 결제수단
          // =====================================================
          const _SectionTitle(title: '결제수단별 매출'),

          ...PaymentMethod.values.map((method) {
            return _ProgressRow(
              label: method.label,
              value: paymentTotals[method] ?? 0,
              total: netSales,
            );
          }),

          const SizedBox(height: 24),

          // =====================================================
          // 카테고리
          // =====================================================
          const _SectionTitle(title: '카테고리별 매출'),

          if (categoryEntries.isEmpty)
            const _EmptyText(text: '카테고리 매출 데이터가 없습니다.')
          else
            ...categoryEntries.map((entry) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _ProgressRow(
                        label: entry.key,
                        value: entry.value,
                        total: netSales,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('카테고리 이익'),
                          Text(
                            '${categoryProfits[entry.key] ?? 0}원',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 24),

          // =====================================================
          // 상품 TOP
          // =====================================================
          const _SectionTitle(title: 'TOP 판매 상품'),

          if (topProducts.isEmpty)
            const _EmptyText(text: '판매 상품 데이터가 없습니다.')
          else
            ...topProducts.take(5).toList().asMap().entries.map((entry) {
              final rank = entry.key + 1;

              final product = entry.value;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Text('$rank')),
                  title: Text(product.key),
                  subtitle: Text(
                    '판매 수량 '
                    '${productQuantity[product.key] ?? 0}개\n'
                    '매출이익 '
                    '${productProfit[product.key] ?? 0}원',
                  ),
                  isThreeLine: true,
                  trailing: Text(
                    '${product.value}원',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }),

          const SizedBox(height: 24),

          // =====================================================
          // 시간대
          // =====================================================
          const _SectionTitle(title: '시간대별 매출'),

          if (hourlyEntries.isEmpty)
            const _EmptyText(text: '시간대별 매출 데이터가 없습니다.')
          else
            ...hourlyEntries.map((entry) {
              return _ProgressRow(
                label: _hourLabel(entry.key),
                value: entry.value,
                total: netSales,
              );
            }),

          const SizedBox(height: 24),

          // =====================================================
          // 직원별
          // =====================================================
          const _SectionTitle(title: '직원별 매출'),

          if (cashierEntries.isEmpty)
            const _EmptyText(text: '직원별 매출 데이터가 없습니다.')
          else
            ...cashierEntries.map((entry) {
              final count = cashierCounts[entry.key] ?? 0;

              final average = count <= 0 ? 0 : entry.value ~/ count;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: Text(entry.key),
                  subtitle: Text(
                    '판매 $count건 · '
                    '객단가 $average원',
                  ),
                  trailing: Text(
                    '${entry.value}원',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }),

          const SizedBox(height: 24),

          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('현재 분석 방식'),
              subtitle: Text(
                '현재는 앱 메모리에 저장된 판매 데이터를 '
                '기준으로 계산합니다. '
                'SQLite 적용 후 일·주·월·기간별 분석으로 '
                '확장할 예정입니다.',
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;

  final String value;

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.total,
  });

  final String label;

  final int value;

  final int total;

  @override
  Widget build(BuildContext context) {
    final rawProgress = total <= 0 ? 0.0 : value / total;

    final progress = rawProgress.clamp(0.0, 1.0).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text(
                '$value원',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 5),

          LinearProgressIndicator(value: progress),
        ],
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text),
    );
  }
}
