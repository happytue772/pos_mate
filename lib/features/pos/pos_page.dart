import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/pos_provider.dart';

class PosPage extends StatelessWidget {
  const PosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('POS 판매')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: pos.products.length,
              itemBuilder: (context, index) {
                final product = pos.products[index];
                final quantity = pos.quantityOf(product.id);

                return ListTile(
                  title: Text(product.name),
                  subtitle: Text(
                    '${product.category} · '
                    '${product.price}원 · '
                    '재고 ${product.stock}개',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: quantity > 0
                            ? () {
                                pos.removeFromCart(product);
                              }
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text('$quantity'),
                      IconButton(
                        onPressed: quantity < product.stock
                            ? () {
                                pos.addToCart(product);
                              }
                            : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
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
                    Text('상품 ${pos.cartItemCount}개'),
                    Text(
                      '${pos.cartTotal}원',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final success = pos.checkout();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success ? '결제가 완료되었습니다.' : '장바구니에 상품이 없습니다.',
                          ),
                        ),
                      );
                    },
                    child: const Text('결제하기'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
