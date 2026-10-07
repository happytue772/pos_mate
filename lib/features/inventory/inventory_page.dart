import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/pos_provider.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('재고 관리')),
      body: ListView.builder(
        itemCount: pos.products.length,
        itemBuilder: (context, index) {
          final product = pos.products[index];

          return ListTile(
            leading: Icon(
              product.isLowStock
                  ? Icons.warning_amber
                  : Icons.inventory_2_outlined,
            ),
            title: Text(product.name),
            subtitle: Text(
              '${product.category} · '
              '최소재고 ${product.minimumStock}개',
            ),
            trailing: Text(
              '${product.stock}개',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: product.isLowStock ? Colors.red : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
