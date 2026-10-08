import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/refund_transaction.dart';
import '../../providers/pos_provider.dart';

class RefundHistoryPage extends StatefulWidget {
  const RefundHistoryPage({super.key});

  @override
  State<RefundHistoryPage> createState() => _RefundHistoryPageState();
}

class _RefundHistoryPageState extends State<RefundHistoryPage> {
  String _query = '';

  RefundReason? _reasonFilter;

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

    final query = _query.trim().toLowerCase();

    final refunds = pos.refundTransactions.where((refund) {
      final matchesReason =
          _reasonFilter == null || refund.reason == _reasonFilter;

      final matchesQuery =
          query.isEmpty ||
          refund.refundNumber.toLowerCase().contains(query) ||
          refund.receiptNumber.toLowerCase().contains(query) ||
          refund.processedBy.toLowerCase().contains(query) ||
          refund.items.any(
            (item) => item.productName.toLowerCase().contains(query),
          );

      return matchesReason && matchesQuery;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('환불 이력')),
      body: Column(
        children: [
          // ===================================================
          // 검색
          // ===================================================

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              decoration: const InputDecoration(
                labelText: '환불번호 / 영수증 / 직원 / 상품 검색',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _query = value;
                });
              },
            ),
          ),

          // ===================================================
          // 환불 사유 필터
          // ===================================================
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('전체'),
                    selected: _reasonFilter == null,
                    onSelected: (_) {
                      setState(() {
                        _reasonFilter = null;
                      });
                    },
                  ),
                ),

                ...RefundReason.values.map((reason) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(reason.label),
                      selected: _reasonFilter == reason,
                      onSelected: (_) {
                        setState(() {
                          _reasonFilter = reason;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: refunds.isEmpty
                ? const Center(child: Text('조건에 맞는 환불 기록이 없습니다.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: refunds.length,
                    itemBuilder: (context, index) {
                      final refund = refunds[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ExpansionTile(
                          leading: const Icon(Icons.assignment_return_outlined),
                          title: Text(refund.refundNumber),
                          subtitle: Text(
                            '${refund.reason.label} · '
                            '${refund.totalAmount}원\n'
                            '${_dateTime(refund.createdAt)} · '
                            '${refund.processedBy}',
                          ),
                          children: [
                            const Divider(height: 1),

                            _InfoRow(
                              label: '원 영수증',
                              value: refund.receiptNumber,
                            ),

                            _InfoRow(
                              label: '환불 사유',
                              value: refund.reason.label,
                            ),

                            _InfoRow(label: '처리 직원', value: refund.processedBy),

                            _InfoRow(
                              label: '처리 시간',
                              value: _dateTime(refund.createdAt),
                            ),

                            if (refund.memo != null)
                              _InfoRow(label: '메모', value: refund.memo!),

                            const Divider(),

                            ...refund.items.map((item) {
                              return ListTile(
                                dense: true,
                                title: Text(item.productName),
                                subtitle: Text(
                                  '환불 수량 '
                                  '${item.quantity}개',
                                ),
                                trailing: Text(
                                  '${item.refundAmount}원',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }),

                            const Divider(),

                            ListTile(
                              title: const Text(
                                '총 환불금액',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              trailing: Text(
                                '${refund.totalAmount}원',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;

  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
