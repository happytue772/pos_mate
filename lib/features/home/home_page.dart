import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/pos_palette.dart';
import '../../data/models/product.dart';
import '../../data/models/sale.dart';
import '../../data/models/stock_movement.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pos_provider.dart';
import '../../providers/shift_provider.dart';
import '../auth/login_page.dart';
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
    String two(int n) {
      return n.toString().padLeft(2, '0');
    }

    return '${two(value.hour)}:${two(value.minute)}';
  }

  Product? _productById(PosProvider pos, int productId) {
    for (final product in pos.products) {
      if (product.id == productId) {
        return product;
      }
    }

    return null;
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
        .where(
          (sale) =>
              _sameDay(sale.soldAt, now) && sale.status != SaleStatus.voided,
        )
        .toList();

    final yesterdaySales = pos.sales
        .where(
          (sale) =>
              _sameDay(sale.soldAt, yesterday) &&
              sale.status != SaleStatus.voided,
        )
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

    final todayVoidCount = pos.sales
        .where((sale) => sale.voidedAt != null && _sameDay(sale.voidedAt!, now))
        .length;

    double? changeRate;

    if (yesterdayNet > 0) {
      changeRate = (todayNet - yesterdayNet) / yesterdayNet * 100;
    }

    final paymentTotals = <PaymentMethod, int>{
      PaymentMethod.card: 0,
      PaymentMethod.cash: 0,
      PaymentMethod.mobile: 0,
    };

    for (final sale in todaySales) {
      paymentTotals[sale.paymentMethod] =
          (paymentTotals[sale.paymentMethod] ?? 0) + sale.netAmount;
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

            if (aDate == null && bDate == null) {
              return 0;
            }

            if (aDate == null) {
              return 1;
            }

            if (bDate == null) {
              return -1;
            }

            return aDate.compareTo(bDate);
          });

    final todayDisposals = pos.stockMovements
        .where(
          (movement) =>
              movement.type == StockMovementType.disposal &&
              _sameDay(movement.createdAt, now),
        )
        .toList();

    final disposalQuantity = todayDisposals.fold<int>(
      0,
      (sum, movement) => sum + movement.quantity,
    );

    final disposalEstimatedCost = todayDisposals.fold<int>(0, (sum, movement) {
      final product = _productById(pos, movement.productId);

      return sum + movement.quantity * (product?.costPrice ?? 0);
    });

    final inventoryValue = pos.products.fold<int>(
      0,
      (sum, product) => sum + product.stock * product.costPrice,
    );

    final productStats = <int, _ProductPerformance>{};

    for (final sale in todaySales) {
      for (final item in sale.items) {
        if (item.remainingQuantity <= 0) {
          continue;
        }

        final current = productStats[item.productId];

        productStats[item.productId] = _ProductPerformance(
          name: item.productName,
          quantity: (current?.quantity ?? 0) + item.remainingQuantity,
          amount: (current?.amount ?? 0) + item.netAmount,
        );
      }
    }

    final topProducts = productStats.values.toList()
      ..sort((a, b) => b.quantity.compareTo(a.quantity));

    final staffStats = <String, _StaffPerformance>{};

    for (final sale in todaySales) {
      if (sale.netAmount <= 0) {
        continue;
      }

      final current = staffStats[sale.cashierName];

      staffStats[sale.cashierName] = _StaffPerformance(
        name: sale.cashierName,
        salesCount: (current?.salesCount ?? 0) + 1,
        amount: (current?.amount ?? 0) + sale.netAmount,
      );
    }

    final staffPerformance = staffStats.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final activeShift = shift.activeShift;

    final isAdmin = auth.currentUser?.isAdmin == true;

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
                        '오늘 매장 운영 상태를 한눈에 확인해보세요.',
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
                const SizedBox(width: 6),
                IconButton(
                  tooltip: '로그아웃',
                  onPressed: () {
                    if (shift.activeShift != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('근무 마감 후 로그아웃할 수 있습니다.')),
                      );
                      return;
                    }

                    auth.logout();

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(
                    Icons.logout,
                    color: PosPalette.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            _SalesCard(
              value: _money(todayNet),
              saleCount: todayCount,
              refundCount: todayRefundCount,
              voidCount: todayVoidCount,
              changeRate: changeRate,
              onTap: isAdmin
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

            const _SectionTitle('오늘 운영 현황'),

            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: '판매',
                    value: '$todayCount건',
                    icon: Icons.shopping_bag_outlined,
                    background: PosPalette.softBlue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    label: '환불',
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
                    label: '거래 취소',
                    value: '$todayVoidCount건',
                    icon: Icons.cancel_outlined,
                    background: PosPalette.softOrange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    label: '오늘 폐기',
                    value: '$disposalQuantity개',
                    subtitle: isAdmin
                        ? '추정원가 ${_money(disposalEstimatedCost)}'
                        : null,
                    icon: Icons.delete_sweep_outlined,
                    background: PosPalette.softRed,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const _SectionTitle('결제 수단'),

            _PaymentCard(
              total: todayNet,
              card: paymentTotals[PaymentMethod.card] ?? 0,
              cash: paymentTotals[PaymentMethod.cash] ?? 0,
              mobile: paymentTotals[PaymentMethod.mobile] ?? 0,
              money: _money,
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

            const _SectionTitle('오늘 인기 상품'),

            _RankingCard(products: topProducts.take(3).toList(), money: _money),

            if (isAdmin) ...[
              const SizedBox(height: 20),

              const _SectionTitle('재고 가치'),

              _InventoryValueCard(
                inventoryValue: inventoryValue,
                productCount: pos.products.length,
                totalStock: pos.products.fold<int>(
                  0,
                  (sum, product) => sum + product.stock,
                ),
                money: _money,
              ),

              const SizedBox(height: 20),

              const _SectionTitle('직원별 오늘 실적'),

              _StaffPerformanceCard(
                items: staffPerformance.take(3).toList(),
                money: _money,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductPerformance {
  const _ProductPerformance({
    required this.name,
    required this.quantity,
    required this.amount,
  });

  final String name;
  final int quantity;
  final int amount;
}

class _StaffPerformance {
  const _StaffPerformance({
    required this.name,
    required this.salesCount,
    required this.amount,
  });

  final String name;
  final int salesCount;
  final int amount;
}

class _SalesCard extends StatelessWidget {
  const _SalesCard({
    required this.value,
    required this.saleCount,
    required this.refundCount,
    required this.voidCount,
    required this.changeRate,
    required this.onTap,
  });

  final String value;
  final int saleCount;
  final int refundCount;
  final int voidCount;
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
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  _HeroStat(label: '판매', value: '$saleCount건'),
                  _HeroStat(label: '환불', value: '$refundCount건'),
                  _HeroStat(label: '취소', value: '$voidCount건'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label $value',
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.total,
    required this.card,
    required this.cash,
    required this.mobile,
    required this.money,
  });

  final int total;
  final int card;
  final int cash;
  final int mobile;
  final String Function(int value) money;

  double _ratio(int value) {
    if (total <= 0) {
      return 0;
    }

    return (value / total).clamp(0.0, 1.0).toDouble();
  }

  String _percent(int value) {
    if (total <= 0) {
      return '0%';
    }

    return '${(value / total * 100).toStringAsFixed(0)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PosPalette.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          _PaymentRow(
            label: '카드',
            amount: money(card),
            percent: _percent(card),
            progress: _ratio(card),
            icon: Icons.credit_card_outlined,
          ),
          const SizedBox(height: 16),
          _PaymentRow(
            label: '현금',
            amount: money(cash),
            percent: _percent(cash),
            progress: _ratio(cash),
            icon: Icons.payments_outlined,
          ),
          const SizedBox(height: 16),
          _PaymentRow(
            label: '모바일',
            amount: money(mobile),
            percent: _percent(mobile),
            progress: _ratio(mobile),
            icon: Icons.phone_android_outlined,
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.label,
    required this.amount,
    required this.percent,
    required this.progress,
    required this.icon,
  });

  final String label;
  final String amount;
  final String percent;
  final double progress;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: PosPalette.softBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 19, color: PosPalette.primary),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: PosPalette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    amount,
                    style: const TextStyle(
                      color: PosPalette.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              percent,
              style: const TextStyle(
                color: PosPalette.primary,
                fontWeight: FontWeight.w800,
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
            valueColor: const AlwaysStoppedAnimation<Color>(PosPalette.primary),
          ),
        ),
      ],
    );
  }
}

class _RankingCard extends StatelessWidget {
  const _RankingCard({required this.products, required this.money});

  final List<_ProductPerformance> products;
  final String Function(int value) money;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: PosPalette.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: products.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Text(
                  '오늘 판매된 상품이 없습니다.',
                  style: TextStyle(color: PosPalette.textTertiary),
                ),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < products.length; i++)
                  _RankingRow(rank: i + 1, item: products[i], money: money),
              ],
            ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({
    required this.rank,
    required this.item,
    required this.money,
  });

  final int rank;
  final _ProductPerformance item;
  final String Function(int value) money;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: PosPalette.softBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$rank',
              style: const TextStyle(
                color: PosPalette.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PosPalette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.quantity}개 판매',
                  style: const TextStyle(
                    color: PosPalette.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            money(item.amount),
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

class _InventoryValueCard extends StatelessWidget {
  const _InventoryValueCard({
    required this.inventoryValue,
    required this.productCount,
    required this.totalStock,
    required this.money,
  });

  final int inventoryValue;
  final int productCount;
  final int totalStock;
  final String Function(int value) money;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PosPalette.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: PosPalette.softGreen,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: PosPalette.success,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '현재 보유 재고 원가',
                  style: TextStyle(
                    color: PosPalette.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  money(inventoryValue),
                  style: const TextStyle(
                    color: PosPalette.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$productCount종 · 총 $totalStock개',
                  style: const TextStyle(
                    color: PosPalette.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffPerformanceCard extends StatelessWidget {
  const _StaffPerformanceCard({required this.items, required this.money});

  final List<_StaffPerformance> items;
  final String Function(int value) money;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: PosPalette.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: items.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Text(
                  '오늘 판매 실적이 없습니다.',
                  style: TextStyle(color: PosPalette.textTertiary),
                ),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < items.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: PosPalette.softBlue,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: PosPalette.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                items[i].name,
                                style: const TextStyle(
                                  color: PosPalette.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${items[i].salesCount}건 판매',
                                style: const TextStyle(
                                  color: PosPalette.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          money(items[i].amount),
                          style: const TextStyle(
                            color: PosPalette.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
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
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color background;
  final String? subtitle;

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
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: PosPalette.textTertiary,
                fontSize: 10,
              ),
            ),
          ],
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
