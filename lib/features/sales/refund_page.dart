import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/sale.dart';
import '../../providers/pos_provider.dart';
import 'partial_refund_page.dart';
import 'refund_history_page.dart';

class RefundPage extends StatelessWidget {
  const RefundPage({super.key});

  String _dateTime(DateTime value) {
    String two(int number) {
      return number.toString().padLeft(2, '0');
    }

    return '${value.year}-'
        '${two(value.month)}-'
        '${two(value.day)} '
        '${two(value.hour)}:'
        '${two(value.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();

    final sales = pos.sales;

    return Scaffold(
      appBar: AppBar(
        title: const Text('환불 관리'),
        actions: [
          IconButton(
            tooltip: '환불 이력',
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RefundHistoryPage()),
              );
            },
          ),
        ],
      ),
      body: sales.isEmpty
          ? const Center(child: Text('판매 내역이 없습니다.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: sales.length,
              itemBuilder: (context, index) {
                final sale = sales[index];

                final fullyRefunded = sale.status == SaleStatus.refunded;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(
                      fullyRefunded
                          ? Icons.check_circle_outline
                          : Icons.receipt_long_outlined,
                    ),
                    title: Text(sale.receiptNumber),
                    subtitle: Text(
                      '${_dateTime(sale.soldAt)}\n'
                      '결제 ${sale.totalAmount}원 · '
                      '환불 ${sale.refundedAmount}원 · '
                      '잔여 ${sale.netAmount}원\n'
                      '${sale.paymentMethod.label} · '
                      '${sale.status.label}',
                    ),
                    isThreeLine: true,
                    trailing: fullyRefunded
                        ? const Text(
                            '환불 완료',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )
                        : FilledButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PartialRefundPage(sale: sale),
                                ),
                              );
                            },
                            child: const Text('환불'),
                          ),
                    onTap: fullyRefunded
                        ? null
                        : () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PartialRefundPage(sale: sale),
                              ),
                            );
                          },
                  ),
                );
              },
            ),
    );
  }
}
