import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/pos_palette.dart';
import '../../data/models/product.dart';
import '../../data/models/sale.dart';
import '../../providers/pos_provider.dart';

enum _PeriodPreset { today, yesterday, last7Days, thisMonth, custom }

extension _PeriodPresetLabel on _PeriodPreset {
  String get label {
    switch (this) {
      case _PeriodPreset.today:
        return '오늘';
      case _PeriodPreset.yesterday:
        return '어제';
      case _PeriodPreset.last7Days:
        return '최근 7일';
      case _PeriodPreset.thisMonth:
        return '이번 달';
      case _PeriodPreset.custom:
        return '직접 선택';
    }
  }
}

class SalesAnalyticsPage extends StatefulWidget {
  const SalesAnalyticsPage({super.key});

  @override
  State<SalesAnalyticsPage> createState() => _SalesAnalyticsPageState();
}

class _SalesAnalyticsPageState extends State<SalesAnalyticsPage> {
  _PeriodPreset _preset = _PeriodPreset.today;
  DateTimeRange? _customRange;

  DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

  DateTimeRange _currentRange() {
    final now = DateTime.now();
    final today = _day(now);

    switch (_preset) {
      case _PeriodPreset.today:
        return DateTimeRange(
          start: today,
          end: today.add(const Duration(days: 1)),
        );
      case _PeriodPreset.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return DateTimeRange(start: yesterday, end: today);
      case _PeriodPreset.last7Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today.add(const Duration(days: 1)),
        );
      case _PeriodPreset.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: today.add(const Duration(days: 1)),
        );
      case _PeriodPreset.custom:
        final range = _customRange;
        if (range == null) {
          return DateTimeRange(
            start: today,
            end: today.add(const Duration(days: 1)),
          );
        }
        return DateTimeRange(
          start: _day(range.start),
          end: _day(range.end).add(const Duration(days: 1)),
        );
    }
  }

  bool _contains(DateTime value, DateTimeRange range) {
    return !value.isBefore(range.start) && value.isBefore(range.end);
  }

  String _money(int value) {
    final sign = value < 0 ? '-' : '';
    final raw = value.abs().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < raw.length; i++) {
      final remaining = raw.length - i;
      buffer.write(raw[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }

    return '$sign${buffer.toString()}원';
  }

  String _date(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}.${two(value.month)}.${two(value.day)}';
  }

  String _rangeLabel(DateTimeRange range) {
    final last = range.end.subtract(const Duration(days: 1));
    if (_day(range.start) == _day(last)) {
      return _date(range.start);
    }
    return '${_date(range.start)} ~ ${_date(last)}';
  }

  Future<void> _pickCustom() async {
    final now = DateTime.now();

    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange:
          _customRange ?? DateTimeRange(start: _day(now), end: _day(now)),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _customRange = result;
      _preset = _PeriodPreset.custom;
    });
  }

  ProductCategory _categoryOf(PosProvider pos, int productId) {
    for (final product in pos.products) {
      if (product.id == productId) {
        return product.category;
      }
    }
    return ProductCategory.other;
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();
    final range = _currentRange();

    final sales = pos.sales
        .where(
          (sale) =>
              _contains(sale.soldAt, range) && sale.status != SaleStatus.voided,
        )
        .toList();

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

    final refundSaleCount = sales
        .where(
          (sale) =>
              sale.status == SaleStatus.partiallyRefunded ||
              sale.status == SaleStatus.refunded,
        )
        .length;

    final averageOrder = transactionCount == 0
        ? 0
        : netSales ~/ transactionCount;

    int totalCost = 0;
    int totalDiscount = 0;

    final paymentTotals = <PaymentMethod, int>{
      PaymentMethod.card: 0,
      PaymentMethod.cash: 0,
      PaymentMethod.mobile: 0,
    };

    final productRevenue = <String, int>{};
    final productQuantity = <String, int>{};
    final categoryRevenue = <ProductCategory, int>{};

    for (final sale in sales) {
      paymentTotals[sale.paymentMethod] =
          (paymentTotals[sale.paymentMethod] ?? 0) + sale.netAmount;

      for (final item in sale.items) {
        totalCost += item.netCostAmount;

        final normalRemainingAmount = item.unitPrice * item.remainingQuantity;
        final discount = normalRemainingAmount - item.netAmount;

        if (discount > 0) {
          totalDiscount += discount;
        }

        if (item.remainingQuantity <= 0) {
          continue;
        }

        productRevenue[item.productName] =
            (productRevenue[item.productName] ?? 0) + item.netAmount;

        productQuantity[item.productName] =
            (productQuantity[item.productName] ?? 0) + item.remainingQuantity;

        final category = _categoryOf(pos, item.productId);
        categoryRevenue[category] =
            (categoryRevenue[category] ?? 0) + item.netAmount;
      }
    }

    final grossProfit = netSales - totalCost;
    final marginRate = netSales == 0 ? 0.0 : grossProfit / netSales * 100;

    final products = productRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final categories = categoryRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxProduct = products.isEmpty ? 0 : products.first.value;
    final maxCategory = categories.isEmpty ? 0 : categories.first.value;

    return Scaffold(
      backgroundColor: PosPalette.background,
      appBar: AppBar(
        backgroundColor: PosPalette.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          '매출 분석',
          style: TextStyle(
            color: PosPalette.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _PeriodPreset.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final preset = _PeriodPreset.values[index];
                final selected = preset == _preset;

                return ChoiceChip(
                  label: Text(preset.label),
                  selected: selected,
                  showCheckmark: false,
                  side: BorderSide.none,
                  selectedColor: PosPalette.primary,
                  backgroundColor: PosPalette.surface,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : PosPalette.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) async {
                    if (preset == _PeriodPreset.custom) {
                      await _pickCustom();
                    } else {
                      setState(() {
                        _preset = preset;
                      });
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _rangeLabel(range),
            style: const TextStyle(
              color: PosPalette.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          _HeroCard(
            value: _money(netSales),
            subtitle: '총매출 ${_money(grossSales)} · 환불 ${_money(refundAmount)}',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: '판매 건수',
                  value: '$transactionCount건',
                  icon: Icons.receipt_long_outlined,
                  background: PosPalette.softBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  label: '객단가',
                  value: _money(averageOrder),
                  icon: Icons.person_outline,
                  background: PosPalette.softGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: '매출총이익',
                  value: _money(grossProfit),
                  icon: Icons.trending_up,
                  background: PosPalette.softBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  label: '마진율',
                  value: '${marginRate.toStringAsFixed(1)}%',
                  icon: Icons.percent,
                  background: PosPalette.softOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionTitle('결제 수단'),
          _SectionCard(
            children: PaymentMethod.values.map((method) {
              final amount = paymentTotals[method] ?? 0;
              final progress = netSales <= 0
                  ? 0.0
                  : (amount / netSales).clamp(0.0, 1.0).toDouble();

              return _ProgressRow(
                label: method.label,
                value: _money(amount),
                progress: progress,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('판매 요약'),
          _SectionCard(
            children: [
              _SimpleRow('총매출', _money(grossSales)),
              _SimpleRow('환불금액', _money(refundAmount)),
              _SimpleRow('환불 발생 판매', '$refundSaleCount건'),
              _SimpleRow('할인금액', _money(totalDiscount)),
              _SimpleRow('판매 원가', _money(totalCost)),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionTitle('카테고리 매출'),
          _SectionCard(
            children: categories.isEmpty
                ? const [_EmptyRow()]
                : categories.map((entry) {
                    final progress = maxCategory == 0
                        ? 0.0
                        : (entry.value / maxCategory)
                              .clamp(0.0, 1.0)
                              .toDouble();

                    return _ProgressRow(
                      label: entry.key.label,
                      value: _money(entry.value),
                      progress: progress,
                    );
                  }).toList(),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('상품 TOP 5'),
          _SectionCard(
            children: products.isEmpty
                ? const [_EmptyRow()]
                : products.take(5).map((entry) {
                    final qty = productQuantity[entry.key] ?? 0;
                    final progress = maxProduct == 0
                        ? 0.0
                        : (entry.value / maxProduct).clamp(0.0, 1.0).toDouble();

                    return _ProgressRow(
                      label: '${entry.key} · $qty개',
                      value: _money(entry.value),
                      progress: progress,
                    );
                  }).toList(),
          ),
          const SizedBox(height: 14),
          const Text(
            '※ 현재 기간 분석은 판매일 기준입니다. 이후 발생한 환불은 해당 판매의 순매출에도 반영됩니다.',
            style: TextStyle(
              fontSize: 12,
              color: PosPalette.textTertiary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.value, required this.subtitle});

  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: PosPalette.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '순매출',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.background,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PosPalette.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: PosPalette.textPrimary),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: const TextStyle(
              color: PosPalette.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: PosPalette.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 9),
      child: Text(
        title,
        style: const TextStyle(
          color: PosPalette.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: PosPalette.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(children: children),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.progress,
  });

  final String label;
  final String value;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: PosPalette.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: PosPalette.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: PosPalette.background,
              valueColor: const AlwaysStoppedAnimation<Color>(
                PosPalette.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleRow extends StatelessWidget {
  const _SimpleRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: PosPalette.textSecondary),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: PosPalette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Text(
        '선택한 기간에 판매 데이터가 없습니다.',
        style: TextStyle(color: PosPalette.textTertiary),
      ),
    );
  }
}
