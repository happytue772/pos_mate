import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/pos_provider.dart';

class StockInPage extends StatefulWidget {
  const StockInPage({super.key});

  @override
  State<StockInPage> createState() => _StockInPageState();
}

class _StockInPageState extends State<StockInPage> {
  int? _selectedProductId;

  final TextEditingController _quantityController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();

    super.dispose();
  }

  void _save() {
    final quantity = int.tryParse(_quantityController.text);

    if (_selectedProductId == null || quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('상품과 입고 수량을 확인해주세요.')));

      return;
    }

    context.read<PosProvider>().restockProduct(_selectedProductId!, quantity);

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('입고 처리가 완료되었습니다.')));

    _quantityController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('입고 관리')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InputDecorator(
            decoration: const InputDecoration(
              labelText: '상품 선택',
              border: OutlineInputBorder(),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedProductId,
                isExpanded: true,
                hint: const Text('상품 선택'),
                items: pos.products.map((product) {
                  return DropdownMenuItem<int>(
                    value: product.id,
                    child: Text(
                      '${product.name} '
                      '(현재 ${product.stock}개)',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProductId = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '입고 수량',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: const Text('입고 처리')),
        ],
      ),
    );
  }
}
