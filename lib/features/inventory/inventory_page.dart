import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/product.dart';
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

          final hasWarning =
              product.isLowStock ||
              product.expirationStatus == ExpirationStatus.soon ||
              product.expirationStatus == ExpirationStatus.today ||
              product.expirationStatus == ExpirationStatus.expired;

          return ListTile(
            leading: Icon(
              hasWarning ? Icons.warning_amber : Icons.inventory_2_outlined,
            ),
            title: Text(product.name),
            subtitle: Text(
              '${product.category.label} / '
              '${product.subCategory}\n'
              '${product.expirationLabel}',
            ),
            isThreeLine: true,
            trailing: Text(
              '${product.stock}개',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }
}
