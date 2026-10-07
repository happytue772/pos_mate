import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/stock_movement.dart';
import '../../providers/pos_provider.dart';

class StockHistoryPage extends StatelessWidget {
  const StockHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('재고 이력')),
      body: pos.stockMovements.isEmpty
          ? const Center(child: Text('재고 변동 이력이 없습니다.'))
          : ListView.builder(
              itemCount: pos.stockMovements.length,
              itemBuilder: (context, index) {
                final movement = pos.stockMovements[index];

                return ListTile(
                  title: Text(movement.productName),
                  subtitle: Text(
                    '${movement.type.label} · '
                    '${movement.beforeStock} → '
                    '${movement.afterStock}',
                  ),
                  trailing: Text('${movement.quantity}개'),
                );
              },
            ),
    );
  }
}
