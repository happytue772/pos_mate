import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/pos_provider.dart';
import '../../providers/shift_provider.dart';

class ShiftClosePage extends StatefulWidget {
  const ShiftClosePage({super.key});

  @override
  State<ShiftClosePage> createState() => _ShiftClosePageState();
}

class _ShiftClosePageState extends State<ShiftClosePage> {
  final TextEditingController _actualCashController = TextEditingController();

  @override
  void dispose() {
    _actualCashController.dispose();
    super.dispose();
  }

  void _closeShift() {
    final pos = context.read<PosProvider>();

    if (pos.cart.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('장바구니를 비운 후 근무를 마감해주세요.')));
      return;
    }

    final actualCash = int.tryParse(_actualCashController.text);

    if (actualCash == null || actualCash < 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('실제 금고 현금을 입력해주세요.')));
      return;
    }

    final closedShift = context.read<ShiftProvider>().closeShift(
      actualCash: actualCash,
      sales: pos.sales,
    );

    if (closedShift == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('근무 마감에 실패했습니다.')));
      return;
    }

    final difference = closedShift.cashDifference ?? 0;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('근무 마감 완료'),
          content: Text('현금 차액: $difference원'),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();

    final shiftProvider = context.watch<ShiftProvider>();

    final shift = shiftProvider.activeShift;

    final summary = shiftProvider.calculateCurrentSummary(pos.sales);

    if (shift == null || summary == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('근무 마감')),
        body: const Center(child: Text('진행 중인 근무가 없습니다.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('근무 마감')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('담당자: ${shift.cashierName}'),
          const SizedBox(height: 16),
          _SettlementRow(label: '시재금', value: shift.openingCash),
          _SettlementRow(
            label: '판매 건수',
            value: summary.completedSalesCount,
            suffix: '건',
          ),
          _SettlementRow(label: '현금 매출', value: summary.cashSales),
          _SettlementRow(label: '카드 매출', value: summary.cardSales),
          _SettlementRow(label: '모바일 매출', value: summary.mobileSales),
          _SettlementRow(label: '총 매출', value: summary.totalSales),
          _SettlementRow(label: '환불 금액', value: summary.refundAmount),
          const Divider(height: 32),
          _SettlementRow(label: '예상 금고 현금', value: summary.expectedCash),
          const SizedBox(height: 20),
          TextField(
            controller: _actualCashController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '실제 금고 현금',
              suffixText: '원',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _closeShift, child: const Text('근무 마감')),
        ],
      ),
    );
  }
}

class _SettlementRow extends StatelessWidget {
  const _SettlementRow({
    required this.label,
    required this.value,
    this.suffix = '원',
  });

  final String label;
  final int value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Text(
        '$value$suffix',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
