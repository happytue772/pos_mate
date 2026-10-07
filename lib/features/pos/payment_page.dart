import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/sale.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pos_provider.dart';
import '../../providers/shift_provider.dart';
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

  Future<void> _pay() async {
    final pos = context.read<PosProvider>();
    final auth = context.read<AuthProvider>();
    final shiftProvider = context.read<ShiftProvider>();

    final shift = shiftProvider.activeShift;

    // 근무 시작 여부 확인
    if (shift == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('근무를 시작한 후 결제할 수 있습니다.')));

      return;
    }

    // 현금 결제 금액 확인
    if (_paymentMethod == PaymentMethod.cash && _receivedCash < pos.cartTotal) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('받은 현금이 결제 금액보다 부족합니다.')));

      return;
    }

    // 성인 상품 확인
    if (pos.cartContainsAdultProduct) {
      final verified = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            icon: const Icon(Icons.person_search_outlined, size: 40),
            title: const Text('성인 상품 확인'),
            content: const Text(
              '장바구니에 주류 또는 담배 등 '
              '성인 확인이 필요한 상품이 포함되어 있습니다.\n\n'
              '고객의 성인 여부를 확인했습니까?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('성인 확인 완료'),
              ),
            ],
          );
        },
      );

      if (!mounted) {
        return;
      }

      if (verified != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('성인 확인이 완료되지 않아 결제를 취소했습니다.')),
        );

        return;
      }
    }

    // 실제 결제 처리
    final sale = pos.checkout(
      shiftId: shift.id,
      paymentMethod: _paymentMethod,
      cashierName: auth.currentUser?.name ?? '알 수 없음',
      receivedAmount: _paymentMethod == PaymentMethod.cash
          ? _receivedCash
          : null,
    );

    if (sale == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('결제를 처리할 수 없습니다. 재고 또는 결제 금액을 확인해주세요.')),
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

    final change = _receivedCash >= total ? _receivedCash - total : 0;

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

          const SizedBox(height: 12),

          if (pos.cartContainsAdultProduct)
            Card(
              child: ListTile(
                leading: const Icon(Icons.warning_amber),
                title: const Text('성인 확인 상품 포함'),
                subtitle: const Text('결제 시 고객의 성인 여부를 확인해야 합니다.'),
              ),
            ),

          const SizedBox(height: 12),

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
                suffixText: '원',
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
