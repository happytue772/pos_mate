import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models/cash_movement.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pos_provider.dart';
import '../../providers/shift_provider.dart';

class CashMovementPage extends StatefulWidget {
  const CashMovementPage({super.key});

  @override
  State<CashMovementPage> createState() => _CashMovementPageState();
}

class _CashMovementPageState extends State<CashMovementPage> {
  CashMovementType _type = CashMovementType.deposit;

  final TextEditingController _amountController = TextEditingController();

  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();

    super.dispose();
  }

  void _save() {
    final amount = int.tryParse(_amountController.text);

    final reason = _reasonController.text.trim();

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('금액을 올바르게 입력해주세요.')));

      return;
    }

    if (reason.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('입출금 사유를 입력해주세요.')));

      return;
    }

    final shiftProvider = context.read<ShiftProvider>();

    final pos = context.read<PosProvider>();

    final summary = shiftProvider.calculateCurrentSummary(pos.sales);

    if (summary == null) {
      return;
    }

    if (_type == CashMovementType.withdrawal && amount > summary.expectedCash) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '현재 예상 금고 현금 '
            '${summary.expectedCash}원보다 '
            '많이 출금할 수 없습니다.',
          ),
        ),
      );

      return;
    }

    final auth = context.read<AuthProvider>();

    final success = shiftProvider.addCashMovement(
      type: _type,
      amount: amount,
      reason: reason,
      cashierName: auth.currentUser?.name ?? '알 수 없음',
    );

    if (!success) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_type.label} '
          '$amount원이 등록되었습니다.',
        ),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final shift = context.watch<ShiftProvider>();

    final pos = context.watch<PosProvider>();

    final summary = shift.calculateCurrentSummary(pos.sales);

    if (!shift.hasActiveShift || summary == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('현금 입출금')),
        body: const Center(child: Text('진행 중인 근무가 없습니다.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('현금 입출금')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('현재 예상 금고 현금'),
              trailing: Text(
                '${summary.expectedCash}원',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          SegmentedButton<CashMovementType>(
            segments: const [
              ButtonSegment(
                value: CashMovementType.deposit,
                label: Text('현금 입금'),
                icon: Icon(Icons.add_card),
              ),
              ButtonSegment(
                value: CashMovementType.withdrawal,
                label: Text('현금 출금'),
                icon: Icon(Icons.payments_outlined),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (value) {
              setState(() {
                _type = value.first;
              });
            },
          ),

          const SizedBox(height: 20),

          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: '금액',
              suffixText: '원',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: '사유',
              hintText: '예: 추가 시재 / 택배비 지급',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 24),

          FilledButton(
            onPressed: _save,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('등록'),
            ),
          ),
        ],
      ),
    );
  }
}
