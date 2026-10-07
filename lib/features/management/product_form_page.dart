import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/product.dart';
import '../../providers/pos_provider.dart';

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key, this.product});

  final Product? product;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _barcodeController;

  late final TextEditingController _nameController;

  late final TextEditingController _categoryController;

  late final TextEditingController _priceController;

  late final TextEditingController _stockController;

  late final TextEditingController _minimumStockController;

  bool _adultProduct = false;

  bool get isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();

    final product = widget.product;

    _barcodeController = TextEditingController(text: product?.barcode ?? '');

    _nameController = TextEditingController(text: product?.name ?? '');

    _categoryController = TextEditingController(text: product?.category ?? '');

    _priceController = TextEditingController(
      text: product?.price.toString() ?? '',
    );

    _stockController = TextEditingController(
      text: product?.stock.toString() ?? '0',
    );

    _minimumStockController = TextEditingController(
      text: product?.minimumStock.toString() ?? '0',
    );

    _adultProduct = product?.adultProduct ?? false;
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _minimumStockController.dispose();

    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '필수 입력 항목입니다.';
    }

    return null;
  }

  String? _numberValidator(String? value) {
    final number = int.tryParse(value ?? '');

    if (number == null || number < 0) {
      return '0 이상의 숫자를 입력해주세요.';
    }

    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final pos = context.read<PosProvider>();

    final barcode = _barcodeController.text.trim();

    if (pos.barcodeExists(barcode, exceptProductId: widget.product?.id)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('이미 등록된 바코드입니다.')));

      return;
    }

    final name = _nameController.text.trim();

    final category = _categoryController.text.trim();

    final price = int.parse(_priceController.text);

    final stock = int.parse(_stockController.text);

    final minimumStock = int.parse(_minimumStockController.text);

    if (!isEdit) {
      pos.addProduct(
        barcode: barcode,
        name: name,
        category: category,
        price: price,
        stock: stock,
        minimumStock: minimumStock,
        adultProduct: _adultProduct,
      );
    } else {
      final updated = widget.product!.copyWith(
        barcode: barcode,
        name: name,
        category: category,
        price: price,
        minimumStock: minimumStock,
        adultProduct: _adultProduct,
      );

      pos.updateProduct(updated);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? '상품 수정' : '상품 등록')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _barcodeController,
              decoration: const InputDecoration(
                labelText: '바코드',
                border: OutlineInputBorder(),
              ),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '상품명',
                border: OutlineInputBorder(),
              ),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: '카테고리',
                border: OutlineInputBorder(),
              ),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '가격',
                border: OutlineInputBorder(),
              ),
              validator: _numberValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              readOnly: isEdit,
              decoration: InputDecoration(
                labelText: isEdit ? '현재 재고 - 입고 메뉴에서 변경' : '초기 재고',
                border: const OutlineInputBorder(),
              ),
              validator: _numberValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _minimumStockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '최소 재고',
                border: OutlineInputBorder(),
              ),
              validator: _numberValidator,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('성인 상품'),
              value: _adultProduct,
              onChanged: (value) {
                setState(() {
                  _adultProduct = value;
                });
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              child: Text(isEdit ? '수정 저장' : '상품 등록'),
            ),
          ],
        ),
      ),
    );
  }
}
