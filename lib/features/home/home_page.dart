import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/pos_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();

    final lowStockCount = pos.products
        .where((product) => product.isLowStock)
        .length;

    final totalStock = pos.products.fold<int>(
      0,
      (sum, product) => sum + product.stock,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('POS Mate')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '오늘의 현황',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
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
            title: '완료 판매',
            value: '${pos.completedSales}건',
            icon: Icons.receipt_long_outlined,
          ),
          _InfoCard(
            title: '판매 금액',
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
      margin: const EdgeInsets.only(bottom: 12),
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
