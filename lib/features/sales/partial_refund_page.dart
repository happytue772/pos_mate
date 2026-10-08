import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/refund_transaction.dart';
import '../../data/models/sale.dart';
import '../../data/models/sale_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pos_provider.dart';

class PartialRefundPage extends StatefulWidget {
  const PartialRefundPage({super.key, required this.sale});

  final Sale sale;

  @override
  State<PartialRefundPage> createState() => _PartialRefundPageState();
}

class _PartialRefundPageState extends State<PartialRefundPage> {
  final Map<int, int> _selectedQuantities = {};

  final TextEditingController _memoController = TextEditingController();

  RefundReason _reason = RefundReason.customerChange;

  @override
  void dispose() {
    _memoController.dispose();

    super.dispose();
  }

  // =========================================================
  // 선택된 환불 수량
  // =========================================================

  int get _selectedCount {
    return _selectedQuantities.values.fold<int>(
      0,
      (sum, quantity) => sum + quantity,
    );
  }

  // =========================================================
  // 예상 환불금액
  // =========================================================

  int get _expectedRefundAmount {
    int total = 0;

    for (final item in widget.sale.items) {
      final quantity = _selectedQuantities[item.productId] ?? 0;

      if (quantity <= 0) {
        continue;
      }

      total += item.refundAmountFor(quantity);
    }

    return total;
  }

  // =========================================================
  // 수량 변경
  // =========================================================

  void _changeQuantity(SaleItem item, int delta) {
    final current = _selectedQuantities[item.productId] ?? 0;

    final next = current + delta;

    if (next < 0) {
      return;
    }

    if (next > item.remainingQuantity) {
      return;
    }

    setState(() {
      if (next == 0) {
        _selectedQuantities.remove(item.productId);
      } else {
        _selectedQuantities[item.productId] = next;
      }
    });
  }

  // =========================================================
  // 잔여 상품 전체 선택
  // =========================================================

  void _selectAll() {
    setState(() {
      _selectedQuantities.clear();

      for (final item in widget.sale.items) {
        if (item.remainingQuantity > 0) {
          _selectedQuantities[item.productId] = item.remainingQuantity;
        }
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedQuantities.clear();
    });
  }

  // =========================================================
  // 실제 환불
  // =========================================================

  Future<void> _refund() async {
    if (_selectedCount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('환불할 상품을 선택해주세요.')));

      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('환불 확인'),
          content: Text(
            '선택 상품 $_selectedCount개를 환불하시겠습니까?\n\n'
            '예상 환불금액: $_expectedRefundAmount원\n'
            '환불 사유: ${_reason.label}',
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
              child: const Text('환불 처리'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final pos = context.read<PosProvider>();

    final auth = context.read<AuthProvider>();

    final result = pos.refundSaleItems(
      saleId: widget.sale.id,
      refundQuantities: Map<int, int>.from(_selectedQuantities),
      reason: _reason,
      processedBy: auth.currentUser?.name ?? '알 수 없음',
      memo: _memoController.text,
    );

    if (!mounted) {
      return;
    }

    if (result == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('환불 처리에 실패했습니다.')));

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '환불 처리가 완료되었습니다. '
          '환불금액: $result원',
        ),
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final sale = widget.sale;

    return Scaffold(
      appBar: AppBar(title: const Text('부분 / 전체 환불')),
      body: Column(
        children: [
          // ===================================================
          // 영수증 정보
          // ===================================================

          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _InfoRow(label: '영수증', value: sale.receiptNumber),
                    _InfoRow(label: '결제금액', value: '${sale.totalAmount}원'),
                    _InfoRow(label: '기존 환불', value: '${sale.refundedAmount}원'),
                    _InfoRow(label: '현재 잔여금액', value: '${sale.netAmount}원'),
                    _InfoRow(label: '상태', value: sale.status.label),
                  ],
                ),
              ),
            ),
          ),

          // ===================================================
          // 전체 선택 / 해제
          // ===================================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectAll,
                    icon: const Icon(Icons.select_all),
                    label: const Text('잔여 상품 전체 선택'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _clearSelection,
                  child: const Text('선택 해제'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ===================================================
          // 상품별 선택
          // ===================================================
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: sale.items.length,
              itemBuilder: (context, index) {
                final item = sale.items[index];

                final selected = _selectedQuantities[item.productId] ?? 0;

                final selectedRefundAmount = item.refundAmountFor(selected);

                final canRefund = item.remainingQuantity > 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.productName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text('${item.subtotal}원'),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Text(
                          '구매 ${item.quantity}개 · '
                          '기존 환불 ${item.refundedQuantity}개 · '
                          '환불 가능 ${item.remainingQuantity}개',
                        ),

                        const SizedBox(height: 12),

                        if (!canRefund)
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '환불 완료',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          )
                        else
                          Row(
                            children: [
                              IconButton(
                                onPressed: selected > 0
                                    ? () {
                                        _changeQuantity(item, -1);
                                      }
                                    : null,
                                icon: const Icon(Icons.remove_circle_outline),
                              ),

                              SizedBox(
                                width: 38,
                                child: Text(
                                  '$selected',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              IconButton(
                                onPressed: selected < item.remainingQuantity
                                    ? () {
                                        _changeQuantity(item, 1);
                                      }
                                    : null,
                                icon: const Icon(Icons.add_circle_outline),
                              ),

                              const Spacer(),

                              Text(
                                '예상 $selectedRefundAmount원',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ===================================================
          // 환불 사유 / 메모 / 환불금액
          // ===================================================
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  DropdownButtonFormField<RefundReason>(
                    initialValue: _reason,
                    decoration: const InputDecoration(
                      labelText: '환불 사유',
                      border: OutlineInputBorder(),
                    ),
                    items: RefundReason.values.map((reason) {
                      return DropdownMenuItem<RefundReason>(
                        value: reason,
                        child: Text(reason.label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _reason = value;
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: _memoController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: '환불 메모',
                      hintText: '선택 사항',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '예상 환불금액',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '$_expectedRefundAmount원',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _selectedCount > 0 ? _refund : null,
                      icon: const Icon(Icons.assignment_return_outlined),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        child: Text('선택 상품 환불 ($_selectedCount개)'),
                      ),
                    ),
                  ),
                ],
              ),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
