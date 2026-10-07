import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/sale.dart';
import '../../providers/pos_provider.dart';

class PartialRefundPage extends StatefulWidget {
  const PartialRefundPage({super.key, required this.sale});

  final Sale sale;

  @override
  State<PartialRefundPage> createState() => _PartialRefundPageState();
}

class _PartialRefundPageState extends State<PartialRefundPage> {
  final Map<int, int> _selectedQuantities = {};

  int selectedQuantity(int productId) {
    return _selectedQuantities[productId] ?? 0;
  }

  int get expectedRefundAmount {
    int total = 0;

    for (final item in widget.sale.items) {
      final quantity = selectedQuantity(item.productId);

      total += item.refundAmountFor(quantity);
    }

    return total;
  }

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

  void _refund() {
    final result = context.read<PosProvider>().refundSaleItems(
      saleId: widget.sale.id,
      refundQuantities: _selectedQuantities,
    );

    if (result == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('환불할 상품을 선택해주세요.')));

      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('환불 처리 완료: $result원')));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final sale = widget.sale;

    return Scaffold(
      appBar: AppBar(title: Text('환불 ${sale.receiptNumber}')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: sale.items.length,
              itemBuilder: (context, index) {
                final item = sale.items[index];

                final selected = selectedQuantity(item.productId);

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(item.productName),
                    subtitle: Text(
                      '구매 ${item.quantity}개 · '
                      '기환불 ${item.refundedQuantity}개\n'
                      '환불 가능 ${item.remainingQuantity}개',
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: selected > 0
                              ? () {
                                  setState(() {
                                    _selectedQuantities[item.productId] =
                                        selected - 1;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.remove),
                        ),
                        Text('$selected'),
                        IconButton(
                          onPressed: selected < item.remainingQuantity
                              ? () {
                                  setState(() {
                                    _selectedQuantities[item.productId] =
                                        selected + 1;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('예상 환불금'),
                    Text(
                      '$expectedRefundAmount원',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _selectAll,
                        child: const Text('전체 선택'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _refund,
                        child: const Text('선택 상품 환불'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
