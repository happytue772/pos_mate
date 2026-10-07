import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/sale.dart';
import '../../providers/pos_provider.dart';
import 'receipt_page.dart';

class SalesHistoryPage extends StatelessWidget {
  const SalesHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('판매 내역')),
      body: pos.sales.isEmpty
          ? const Center(child: Text('판매 내역이 없습니다.'))
          : ListView.builder(
              itemCount: pos.sales.length,
              itemBuilder: (context, index) {
                final sale = pos.sales[index];

                return ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: Text(sale.receiptNumber),
                  subtitle: Text(
                    '${sale.paymentMethod.label} · '
                    '${sale.cashierName} · '
                    '${sale.status.label}',
                  ),
                  trailing: Text('${sale.totalAmount}원'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReceiptPage(sale: sale),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
