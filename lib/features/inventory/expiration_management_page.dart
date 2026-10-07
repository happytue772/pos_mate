import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/product.dart';
import '../../providers/pos_provider.dart';

class ExpirationManagementPage extends StatelessWidget {
  const ExpirationManagementPage({super.key});

  Future<void> _disposeStock(
    BuildContext context, {
    required int productId,
    required String productName,
    required int currentStock,
  }) async {
    String inputValue = '';
    String? errorText;

    final quantity = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('상품 폐기'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('현재 재고: $currentStock개'),
                  const SizedBox(height: 16),
                  TextField(
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '폐기 수량',
                      hintText: '예: 2',
                      border: const OutlineInputBorder(),
                      errorText: errorText,
                    ),
                    onChanged: (value) {
                      inputValue = value;
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () {
                    final parsedQuantity = int.tryParse(inputValue.trim());

                    if (parsedQuantity == null || parsedQuantity <= 0) {
                      setDialogState(() {
                        errorText = '1개 이상의 수량을 입력해주세요.';
                      });

                      return;
                    }

                    if (parsedQuantity > currentStock) {
                      setDialogState(() {
                        errorText = '현재 재고보다 많이 폐기할 수 없습니다.';
                      });

                      return;
                    }

                    Navigator.of(dialogContext).pop(parsedQuantity);
                  },
                  child: const Text('폐기 확인'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!context.mounted || quantity == null) {
      return;
    }

    final success = context.read<PosProvider>().disposeStock(
      productId: productId,
      quantity: quantity,
      memo: '유통기한 / 상품 폐기',
    );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? '$productName $quantity개를 폐기했습니다.' : '폐기 처리에 실패했습니다.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();

    final products =
        pos.products.where((product) => product.expirationDate != null).toList()
          ..sort((a, b) => a.expirationDate!.compareTo(b.expirationDate!));

    return Scaffold(
      appBar: AppBar(title: const Text('유통기한 / 폐기 관리')),
      body: products.isEmpty
          ? const Center(child: Text('유통기한 관리 상품이 없습니다.'))
          : ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: _ExpirationIcon(product: product),
                    title: Text(product.name),
                    subtitle: Text(
                      '${product.category.label} / '
                      '${product.subCategory}\n'
                      '${product.expirationLabel}\n'
                      '현재 재고 ${product.stock}개',
                    ),
                    isThreeLine: true,
                    trailing: OutlinedButton(
                      onPressed: product.stock > 0
                          ? () {
                              _disposeStock(
                                context,
                                productId: product.id,
                                productName: product.name,
                                currentStock: product.stock,
                              );
                            }
                          : null,
                      child: const Text('폐기'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _ExpirationIcon extends StatelessWidget {
  const _ExpirationIcon({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    switch (product.expirationStatus) {
      case ExpirationStatus.expired:
        return const Icon(Icons.error_outline);

      case ExpirationStatus.today:
        return const Icon(Icons.warning_amber);

      case ExpirationStatus.soon:
        return const Icon(Icons.schedule);

      case ExpirationStatus.normal:
        return const Icon(Icons.check_circle_outline);

      case ExpirationStatus.none:
        return const Icon(Icons.inventory_2_outlined);
    }
  }
}
