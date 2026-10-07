import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/sale.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pos_provider.dart';
import '../sales/receipt_page.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  PaymentMethod _paymentMethod = PaymentMethod.card;

  final TextEditingController _cashController = TextEditingController();

  int _receivedCash = 0;

  @override
  void dispose() {
    _cashController.dispose();

    super.dispose();
  }

  void _pay() {
    final pos = context.read<PosProvider>();

    final auth = context.read<AuthProvider>();

    final sale = pos.checkout(
      paymentMethod: _paymentMethod,
      cashierName: auth.currentUser?.name ?? '알 수 없음',
      receivedAmount: _paymentMethod == PaymentMethod.cash
          ? _receivedCash
          : null,
    );

    if (sale == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '결제를 처리할 수 없습니다. '
            '재고 또는 결제 금액을 확인해주세요.',
          ),
        ),
      );

      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ReceiptPage(sale: sale)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();

    final total = pos.cartTotal;

    final change = _receivedCash > total ? _receivedCash - total : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('결제')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('결제 금액', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            '$total원',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SegmentedButton<PaymentMethod>(
            segments: const [
              ButtonSegment(
                value: PaymentMethod.card,
                label: Text('카드'),
                icon: Icon(Icons.credit_card),
              ),
              ButtonSegment(
                value: PaymentMethod.cash,
                label: Text('현금'),
                icon: Icon(Icons.payments),
              ),
              ButtonSegment(
                value: PaymentMethod.mobile,
                label: Text('모바일'),
                icon: Icon(Icons.smartphone),
              ),
            ],
            selected: {_paymentMethod},
            onSelectionChanged: (selection) {
              setState(() {
                _paymentMethod = selection.first;
              });
            },
          ),
          if (_paymentMethod == PaymentMethod.cash) ...[
            const SizedBox(height: 24),
            TextField(
              controller: _cashController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '받은 금액',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _receivedCash = int.tryParse(value) ?? 0;
                });
              },
            ),
            const SizedBox(height: 12),
            Text(
              '거스름돈: $change원',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
          const SizedBox(height: 32),
          FilledButton(
            onPressed: total > 0 ? _pay : null,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('결제 완료'),
            ),
          ),
        ],
      ),
    );
  }
}
