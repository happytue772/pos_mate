import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/pos_provider.dart';
import '../../providers/shift_provider.dart';
import '../auth/login_page.dart';
import '../shift/cash_movement_page.dart';
import '../shift/shift_close_page.dart';
import '../shift/shift_open_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();

    final auth = context.watch<AuthProvider>();

    final shift = context.watch<ShiftProvider>();
    if (shift.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final lowStockCount = pos.products
        .where((product) => product.isLowStock)
        .length;

    final totalStock = pos.products.fold<int>(
      0,
      (sum, product) => sum + product.stock,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Mate'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(child: Text(auth.currentUser?.roleLabel ?? '')),
          ),
          IconButton(
            onPressed: () {
              if (shift.hasActiveShift) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('근무 마감 후 로그아웃할 수 있습니다.')),
                );

                return;
              }

              context.read<AuthProvider>().logout();

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '근무 상태',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    shift.hasActiveShift
                        ? '${shift.activeShift!.cashierName} 근무 중'
                        : '현재 진행 중인 근무가 없습니다.',
                  ),

                  const SizedBox(height: 16),

                  if (!shift.hasActiveShift)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ShiftOpenPage(),
                            ),
                          );
                        },
                        child: const Text('근무 시작'),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CashMovementPage(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.account_balance_wallet_outlined,
                            ),
                            label: const Text('현금 입출금'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ShiftClosePage(),
                                ),
                              );
                            },
                            child: const Text('근무 마감'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            '오늘의 현황',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          _InfoCard(
            title: '등록 상품',
            value: '${pos.products.length}개',
            icon: Icons.inventory_2_outlined,
          ),

          _InfoCard(
            title: '전체 재고',
            value: '$totalStock개',
            icon: Icons.warehouse_outlined,
          ),

          _InfoCard(
            title: '재고 부족',
            value: '$lowStockCount개',
            icon: Icons.warning_amber,
          ),

          _InfoCard(
            title: '판매 건수',
            value: '${pos.completedSales}건',
            icon: Icons.receipt_long_outlined,
          ),

          _InfoCard(
            title: '순매출',
            value: '${pos.totalSalesAmount}원',
            icon: Icons.payments_outlined,
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
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
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
