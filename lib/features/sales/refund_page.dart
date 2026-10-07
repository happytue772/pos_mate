import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/sale.dart';
import '../../providers/pos_provider.dart';

class RefundPage extends StatelessWidget {
  const RefundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('환불 관리')),
      body: pos.sales.isEmpty
          ? const Center(child: Text('판매 내역이 없습니다.'))
          : ListView.builder(
              itemCount: pos.sales.length,
              itemBuilder: (context, index) {
                final sale = pos.sales[index];

                final refundable = sale.status == SaleStatus.completed;

                return ListTile(
                  title: Text(sale.receiptNumber),
                  subtitle: Text(
                    '${sale.totalAmount}원 · '
                    '${sale.status.label}',
                  ),
                  trailing: refundable
                      ? FilledButton(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('환불 확인'),
                                  content: Text(
                                    '${sale.receiptNumber}\n'
                                    '${sale.totalAmount}원을 '
                                    '환불하시겠습니까?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context, false);
                                      },
                                      child: const Text('취소'),
                                    ),
                                    FilledButton(
                                      onPressed: () {
                                        Navigator.pop(context, true);
                                      },
                                      child: const Text('환불'),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirmed != true || !context.mounted) {
                              return;
                            }

                            final success = context
                                .read<PosProvider>()
                                .refundSale(sale.id);

                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('환불이 완료되었습니다.')),
                              );
                            }
                          },
                          child: const Text('환불'),
                        )
                      : const Text('환불 완료'),
                );
              },
            ),
    );
  }
}
