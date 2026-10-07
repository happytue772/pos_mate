import 'package:flutter/material.dart';

import '../../data/models/sale.dart';

class ReceiptPage extends StatelessWidget {
  const ReceiptPage({super.key, required this.sale});

  final Sale sale;

  String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');

    return '${date.year}-'
        '${two(date.month)}-'
        '${two(date.day)} '
        '${two(date.hour)}:'
        '${two(date.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('영수증')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            sale.receiptNumber,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(_formatDate(sale.soldAt)),
          Text('담당: ${sale.cashierName}'),
          Text('결제: ${sale.paymentMethod.label}'),
          const Divider(height: 32),
          ...sale.items.map((item) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.productName),
              subtitle: Text(
                '${item.unitPrice}원 × '
                '${item.quantity}',
              ),
              trailing: Text('${item.subtotal}원'),
            );
          }),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '총 결제금액',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${sale.totalAmount}원',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (sale.paymentMethod == PaymentMethod.cash) ...[
            const SizedBox(height: 12),
            Text(
              '받은 금액: '
              '${sale.receivedAmount ?? 0}원',
            ),
            Text(
              '거스름돈: '
              '${sale.changeAmount ?? 0}원',
            ),
          ],
          const SizedBox(height: 16),
          Text('상태: ${sale.status.label}'),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
