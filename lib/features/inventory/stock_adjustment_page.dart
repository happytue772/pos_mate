import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/stock_adjustment_reason.dart';
import '../../providers/pos_provider.dart';

class StockAdjustmentPage extends StatefulWidget {
  const StockAdjustmentPage({super.key});

  @override
  State<StockAdjustmentPage> createState() => _StockAdjustmentPageState();
}

class _StockAdjustmentPageState extends State<StockAdjustmentPage> {
  int? _productId;

  StockAdjustmentReason _reason = StockAdjustmentReason.stocktake;

  final _actualStockController = TextEditingController();

  final _memoController = TextEditingController();

  @override
  void dispose() {
    _actualStockController.dispose();
    _memoController.dispose();

    super.dispose();
  }

  void _save() {
    final productId = _productId;

    final actualStock = int.tryParse(_actualStockController.text);

    if (productId == null || actualStock == null || actualStock < 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('상품과 실제 재고를 확인해주세요.')));

      return;
    }

    final success = context.read<PosProvider>().adjustStock(
      productId: productId,
      actualStock: actualStock,
      reason: _reason,
      memo: _memoController.text,
    );

    if (!success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('재고가 동일하거나 변경할 수 없습니다.')));

      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('재고 조정을 완료했습니다.')));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();

    final selectedProduct = _productId == null
        ? null
        : pos.products.where((product) => product.id == _productId).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('재고 조정')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<int>(
            initialValue: _productId,
            decoration: const InputDecoration(
              labelText: '상품',
              border: OutlineInputBorder(),
            ),
            items: pos.products
                .map(
                  (product) => DropdownMenuItem(
                    value: product.id,
                    child: Text(product.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _productId = value;
              });
            },
          ),

          const SizedBox(height: 16),

          if (selectedProduct != null)
            Card(
              child: ListTile(
                title: const Text('현재 전산 재고'),
                trailing: Text('${selectedProduct.stock}개'),
              ),
            ),

          const SizedBox(height: 16),

          TextField(
            controller: _actualStockController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '실제 재고',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<StockAdjustmentReason>(
            initialValue: _reason,
            decoration: const InputDecoration(
              labelText: '조정 사유',
              border: OutlineInputBorder(),
            ),
            items: StockAdjustmentReason.values.map((reason) {
              return DropdownMenuItem(value: reason, child: Text(reason.label));
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

          const SizedBox(height: 16),

          TextField(
            controller: _memoController,
            decoration: const InputDecoration(
              labelText: '메모',
              hintText: '예: 진열 중 파손',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 24),

          FilledButton(onPressed: _save, child: const Text('재고 조정 저장')),
        ],
      ),
    );
  }
}
