import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/pos_provider.dart';
import 'product_form_page.dart';

class ProductManagePage extends StatelessWidget {
  const ProductManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('상품 관리')),
      body: ListView.builder(
        itemCount: pos.products.length,
        itemBuilder: (context, index) {
          final product = pos.products[index];

          return ListTile(
            title: Text(product.name),
            subtitle: Text(
              '${product.category} · '
              '${product.price}원 · '
              '재고 ${product.stock}개',
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductFormPage(product: product),
                ),
              );
            },
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('상품 삭제'),
                      content: Text('${product.name} 상품을 삭제하시겠습니까?'),
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
                          child: const Text('삭제'),
                        ),
                      ],
                    );
                  },
                );

                if (confirmed != true || !context.mounted) {
                  return;
                }

                final success = context.read<PosProvider>().deleteProduct(
                  product.id,
                );

                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('장바구니에 담긴 상품은 삭제할 수 없습니다.')),
                  );
                }
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductFormPage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('상품 등록'),
      ),
    );
  }
}
