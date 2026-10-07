import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/shift_provider.dart';

class SettlementHistoryPage extends StatelessWidget {
  const SettlementHistoryPage({super.key});

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }

    String two(int value) {
      return value.toString().padLeft(2, '0');
    }

    return '${date.year}-'
        '${two(date.month)}-'
        '${two(date.day)} '
        '${two(date.hour)}:'
        '${two(date.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final shifts = context.watch<ShiftProvider>().shiftHistory;

    return Scaffold(
      appBar: AppBar(title: const Text('근무 / 정산 이력')),
      body: shifts.isEmpty
          ? const Center(child: Text('마감된 근무 기록이 없습니다.'))
          : ListView.builder(
              itemCount: shifts.length,
              itemBuilder: (context, index) {
                final shift = shifts[index];
                final summary = shift.summary;

                return ExpansionTile(
                  title: Text(
                    '${shift.cashierName} · '
                    '${summary?.totalSales ?? 0}원',
                  ),
                  subtitle: Text(
                    '${_formatDate(shift.openedAt)}'
                    ' ~ '
                    '${_formatDate(shift.closedAt)}',
                  ),
                  children: [
                    _InfoRow(label: '시재금', value: shift.openingCash),
                    _InfoRow(label: '현금 매출', value: summary?.cashSales ?? 0),
                    _InfoRow(label: '카드 매출', value: summary?.cardSales ?? 0),
                    _InfoRow(label: '모바일 매출', value: summary?.mobileSales ?? 0),
                    _InfoRow(label: '총 매출', value: summary?.totalSales ?? 0),
                    _InfoRow(label: '환불 금액', value: summary?.refundAmount ?? 0),
                    _InfoRow(label: '예상 현금', value: summary?.expectedCash ?? 0),
                    _InfoRow(label: '실제 현금', value: shift.actualCash ?? 0),
                    _InfoRow(label: '현금 차액', value: shift.cashDifference ?? 0),
                  ],
                );
              },
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(label), trailing: Text('$value원'));
  }
}
