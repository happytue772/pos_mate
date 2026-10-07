import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/pos_provider.dart';

class HeldOrdersPage extends StatelessWidget {
  const HeldOrdersPage({super.key});

  String formatTime(DateTime value) {
    String two(int value) {
      return value.toString().padLeft(2, '0');
    }

    return '${two(value.hour)}:'
        '${two(value.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();

    final carts = pos.heldCarts;

    return Scaffold(
      appBar: AppBar(title: const Text('보류 주문')),
      body: carts.isEmpty
          ? const Center(child: Text('보류된 주문이 없습니다.'))
          : ListView.builder(
              itemCount: carts.length,
              itemBuilder: (context, index) {
                final cart = carts[index];

                return ListTile(
                  leading: const Icon(Icons.pause_circle_outline),
                  title: Text('보류 주문 #${cart.id}'),
                  subtitle: Text(
                    '${formatTime(cart.createdAt)} · '
                    '${cart.cashierName}\n'
                    '${cart.totalAmount}원',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'restore') {
                        final success = pos.restoreHeldCart(cart.id);

                        if (success) {
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('현재 장바구니를 비우거나 재고를 확인해주세요.'),
                            ),
                          );
                        }
                      }

                      if (value == 'delete') {
                        pos.deleteHeldCart(cart.id);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'restore', child: Text('복원')),
                      PopupMenuItem(value: 'delete', child: Text('삭제')),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
