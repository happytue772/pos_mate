import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/product.dart';
import '../../data/models/sale.dart';
import '../../providers/pos_provider.dart';

enum AnalysisPeriod { today, all }

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

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();

    final sales = pos.sales.where((sale) {
      if (_period == AnalysisPeriod.all) {
        return true;
      }

      return _isToday(sale.soldAt);
    }).toList();

    final netSales = sales.fold<int>(0, (sum, sale) => sum + sale.netAmount);

    final refundAmount = sales.fold<int>(
      0,
      (sum, sale) => sum + sale.refundedAmount,
    );

    final transactionCount = sales.where((sale) => sale.netAmount > 0).length;

    final averageOrder = transactionCount == 0
        ? 0
        : netSales ~/ transactionCount;

    final paymentTotals = <PaymentMethod, int>{
      for (final method in PaymentMethod.values) method: 0,
    };

    final categoryTotals = <String, int>{};

    final productRevenue = <String, int>{};

    final productQuantity = <String, int>{};

    final hourlyTotals = <int, int>{};

    for (final sale in sales) {
      paymentTotals[sale.paymentMethod] =
          (paymentTotals[sale.paymentMethod] ?? 0) + sale.netAmount;

      hourlyTotals[sale.soldAt.hour] =
          (hourlyTotals[sale.soldAt.hour] ?? 0) + sale.netAmount;

      for (final item in sale.items) {
        final category = _categoryLabel(pos, item.productId);

        categoryTotals[category] =
            (categoryTotals[category] ?? 0) + item.netAmount;

        productRevenue[item.productName] =
            (productRevenue[item.productName] ?? 0) + item.netAmount;

        productQuantity[item.productName] =
            (productQuantity[item.productName] ?? 0) + item.remainingQuantity;
      }
    }

    final categoryEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topProducts = productRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final hourlyEntries = hourlyTotals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Scaffold(
      appBar: AppBar(title: const Text('매출 분석')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<AnalysisPeriod>(
            segments: const [
              ButtonSegment(value: AnalysisPeriod.today, label: Text('오늘')),
              ButtonSegment(value: AnalysisPeriod.all, label: Text('전체')),
            ],
            selected: {_period},
            onSelectionChanged: (value) {
              setState(() {
                _period = value.first;
              });
            },
          ),

          const SizedBox(height: 20),

          _MetricCard(
            title: '순매출',
            value: '$netSales원',
            icon: Icons.payments_outlined,
          ),

          _MetricCard(
            title: '판매 건수',
            value: '$transactionCount건',
            icon: Icons.receipt_long_outlined,
          ),

          _MetricCard(
            title: '환불 금액',
            value: '$refundAmount원',
            icon: Icons.undo_outlined,
          ),

          _MetricCard(
            title: '객단가',
            value: '$averageOrder원',
            icon: Icons.person_outline,
          ),

          const SizedBox(height: 20),

          const _SectionTitle(title: '결제수단별 매출'),

          ...PaymentMethod.values.map((method) {
            final value = paymentTotals[method] ?? 0;

            return _ProgressRow(
              label: method.label,
              value: value,
              total: netSales,
            );
          }),

          const SizedBox(height: 24),

          const _SectionTitle(title: '카테고리별 매출'),

          if (categoryEntries.isEmpty)
            const Text('매출 데이터가 없습니다.')
          else
            ...categoryEntries.map((entry) {
              return _ProgressRow(
                label: entry.key,
                value: entry.value,
                total: netSales,
              );
            }),

          const SizedBox(height: 24),

          const _SectionTitle(title: 'TOP 판매 상품'),

          if (topProducts.isEmpty)
            const Text('판매 데이터가 없습니다.')
          else
            ...topProducts.take(5).toList().asMap().entries.map((entry) {
              final rank = entry.key + 1;

              final product = entry.value;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text('$rank')),
                title: Text(product.key),
                subtitle: Text(
                  '판매 수량 '
                  '${productQuantity[product.key] ?? 0}개',
                ),
                trailing: Text(
                  '${product.value}원',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }),

          const SizedBox(height: 24),

          const _SectionTitle(title: '시간대별 매출'),

          if (hourlyEntries.isEmpty)
            const Text('판매 데이터가 없습니다.')
          else
            ...hourlyEntries.map((entry) {
              return _ProgressRow(
                label: '${entry.key.toString().padLeft(2, '0')}시',
                value: entry.value,
                total: netSales,
              );
            }),

          const SizedBox(height: 20),

          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('현재 분석 데이터'),
              subtitle: Text(
                '현재는 앱 실행 중 메모리에 저장된 '
                '판매 데이터를 기준으로 계산합니다. '
                'SQLite 또는 Spring Boot DB 연결 후 '
                '기간별 통계로 확장할 수 있습니다.',
              ),
            ),
          ),
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
      margin: const EdgeInsets.only(bottom: 10),
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
    final progress = total <= 0 ? 0.0 : value / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
          LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
        ],
      ),
    );
  }
}
