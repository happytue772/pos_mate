import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/pos_palette.dart';
import '../../data/models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pos_provider.dart';
import '../../providers/shift_provider.dart';
import '../inventory/expiration_management_page.dart';
import '../inventory/inventory_page.dart';
import '../sales/sales_analytics_page.dart';
import '../shift/cash_movement_page.dart';
import '../shift/shift_close_page.dart';
import '../shift/shift_open_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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

  String _time(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(value.hour)}:${two(value.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pos = context.watch<PosProvider>();
    final shift = context.watch<ShiftProvider>();

    if (pos.isLoading || shift.isLoading) {
      return const Scaffold(
        backgroundColor: PosPalette.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    final todaySales = pos.sales
        .where((sale) => _sameDay(sale.soldAt, now))
        .toList();

    final yesterdaySales = pos.sales
        .where((sale) => _sameDay(sale.soldAt, yesterday))
        .toList();

    final todayNet = todaySales.fold<int>(
      0,
      (sum, sale) => sum + sale.netAmount,
    );

    final yesterdayNet = yesterdaySales.fold<int>(
      0,
      (sum, sale) => sum + sale.netAmount,
    );

    final todayCount = todaySales.where((sale) => sale.netAmount > 0).length;

    final todayRefundCount = pos.refundTransactions
        .where((refund) => _sameDay(refund.createdAt, now))
        .length;

    double? changeRate;

    if (yesterdayNet > 0) {
      changeRate = (todayNet - yesterdayNet) / yesterdayNet * 100;
    }

    final lowStock =
        pos.products.where((product) => product.isLowStock).toList()
          ..sort((a, b) => a.stock.compareTo(b.stock));

    final expiration =
        pos.products
            .where(
              (product) =>
                  product.expirationStatus == ExpirationStatus.soon ||
                  product.expirationStatus == ExpirationStatus.today ||
                  product.expirationStatus == ExpirationStatus.expired,
            )
            .toList()
          ..sort((a, b) {
            final aDate = a.expirationDate;
            final bDate = b.expirationDate;

            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            return aDate.compareTo(bDate);
          });

    final activeShift = shift.activeShift;

    return Scaffold(
      backgroundColor: PosPalette.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${auth.currentUser?.name ?? '사용자'}님',
                        style: const TextStyle(
                          color: PosPalette.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '오늘 매장 상태를 확인해보세요.',
                        style: TextStyle(color: PosPalette.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: PosPalette.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.storefront_outlined,
                    color: PosPalette.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _SalesCard(
              value: _money(todayNet),
              saleCount: todayCount,
              refundCount: todayRefundCount,
              changeRate: changeRate,
              onTap: auth.currentUser?.isAdmin == true
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SalesAnalyticsPage(),
                        ),
                      );
                    }
                  : null,
            ),
            const SizedBox(height: 20),
            const _SectionTitle('근무 상태'),
            _ShiftCard(
              activeShift: activeShift,
              startTime: activeShift == null
                  ? null
                  : _time(activeShift.openedAt),
              onOpen: activeShift == null
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ShiftOpenPage(),
                        ),
                      );
                    }
                  : null,
              onCash: activeShift == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CashMovementPage(),
                        ),
                      );
                    },
              onClose: activeShift == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ShiftClosePage(),
                        ),
                      );
                    },
            ),
            const SizedBox(height: 20),
            const _SectionTitle('확인이 필요해요'),
            _AlertCard(
              icon: Icons.inventory_2_outlined,
              iconBackground: PosPalette.softOrange,
              iconColor: PosPalette.warning,
              title: '재고 부족',
              subtitle: lowStock.isEmpty
                  ? '부족한 상품이 없어요.'
                  : '${lowStock.first.name}'
                        '${lowStock.length > 1 ? ' 외 ${lowStock.length - 1}건' : ''}',
              count: lowStock.length,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InventoryPage()),
                );
              },
            ),
            const SizedBox(height: 10),
            _AlertCard(
              icon: Icons.event_busy_outlined,
              iconBackground: PosPalette.softRed,
              iconColor: PosPalette.danger,
              title: '유통기한 임박 / 만료',
              subtitle: expiration.isEmpty
                  ? '확인이 필요한 상품이 없어요.'
                  : '${expiration.first.name} · '
                        '${expiration.first.expirationLabel}',
              count: expiration.length,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ExpirationManagementPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const _SectionTitle('빠른 요약'),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: '오늘 판매',
                    value: '$todayCount건',
                    icon: Icons.shopping_bag_outlined,
                    background: PosPalette.softBlue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    label: '오늘 환불',
                    value: '$todayRefundCount건',
                    icon: Icons.assignment_return_outlined,
                    background: PosPalette.softRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: '저재고',
                    value: '${lowStock.length}건',
                    icon: Icons.warning_amber_rounded,
                    background: PosPalette.softOrange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    label: '유통기한',
                    value: '${expiration.length}건',
                    icon: Icons.schedule_outlined,
                    background: PosPalette.softGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesCard extends StatelessWidget {
  const _SalesCard({
    required this.value,
    required this.saleCount,
    required this.refundCount,
    required this.changeRate,
    required this.onTap,
  });

  final String value;
  final int saleCount;
  final int refundCount;
  final double? changeRate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final comparison = changeRate == null
        ? '어제 비교 데이터가 없어요'
        : '어제보다 ${changeRate! >= 0 ? '+' : ''}'
              '${changeRate!.toStringAsFixed(1)}%';

    return Material(
      color: PosPalette.primary,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '오늘 순매출',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    const Icon(Icons.chevron_right, color: Colors.white70),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 31,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                comparison,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Text(
                '판매 $saleCount건   ·   환불 $refundCount건',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShiftCard extends StatelessWidget {
  const _ShiftCard({
    required this.activeShift,
    required this.startTime,
    required this.onOpen,
    required this.onCash,
    required this.onClose,
  });

  final dynamic activeShift;
  final String? startTime;
  final VoidCallback? onOpen;
  final VoidCallback? onCash;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final opened = activeShift != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PosPalette.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: opened ? PosPalette.softGreen : PosPalette.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  opened
                      ? Icons.play_circle_outline
                      : Icons.pause_circle_outline,
                  color: opened ? PosPalette.success : PosPalette.textTertiary,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opened ? '근무 중' : '근무 시작 전',
                      style: const TextStyle(
                        color: PosPalette.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      opened
                          ? '${activeShift.cashierName} · $startTime 시작'
                          : '판매 전에 근무를 시작해주세요.',
                      style: const TextStyle(
                        color: PosPalette.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!opened)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onOpen,
                style: FilledButton.styleFrom(
                  backgroundColor: PosPalette.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('근무 시작'),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCash,
                    child: const Text('현금 입출금'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onClose,
                    style: FilledButton.styleFrom(
                      backgroundColor: PosPalette.textPrimary,
                    ),
                    child: const Text('근무 마감'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PosPalette.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: PosPalette.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PosPalette.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$count건',
                style: TextStyle(
                  color: count > 0 ? iconColor : PosPalette.textTertiary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: PosPalette.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
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
          const SizedBox(height: 13),
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
              fontSize: 18,
              fontWeight: FontWeight.w800,
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
