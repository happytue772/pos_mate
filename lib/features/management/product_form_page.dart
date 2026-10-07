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
  late final TextEditingController _subCategoryController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _minimumStockController;

  late ProductCategory _category;

  bool _adultProduct = false;

  DateTime? _expirationDate;

  bool get isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();

    final product = widget.product;

    _barcodeController = TextEditingController(text: product?.barcode ?? '');

    _nameController = TextEditingController(text: product?.name ?? '');

    _subCategoryController = TextEditingController(
      text: product?.subCategory ?? '',
    );

    _priceController = TextEditingController(
      text: product?.price.toString() ?? '',
    );

    _stockController = TextEditingController(
      text: product?.stock.toString() ?? '0',
    );

    _minimumStockController = TextEditingController(
      text: product?.minimumStock.toString() ?? '0',
    );

    _category = product?.category ?? ProductCategory.beverage;

    _adultProduct = product?.adultProduct ?? false;

    _expirationDate = product?.expirationDate;
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _subCategoryController.dispose();
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

  Future<void> _selectExpirationDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 3650)),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _expirationDate = selected;
    });
  }

  String _formatDate(DateTime date) {
    String two(int value) {
      return value.toString().padLeft(2, '0');
    }

    return '${date.year}-'
        '${two(date.month)}-'
        '${two(date.day)}';
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

    final subCategory = _subCategoryController.text.trim();

    final price = int.parse(_priceController.text);

    final stock = int.parse(_stockController.text);

    final minimumStock = int.parse(_minimumStockController.text);

    if (!isEdit) {
      pos.addProduct(
        barcode: barcode,
        name: name,
        category: _category,
        subCategory: subCategory,
        price: price,
        stock: stock,
        minimumStock: minimumStock,
        adultProduct: _adultProduct,
        expirationDate: _expirationDate,
      );
    } else {
      final updated = widget.product!.copyWith(
        barcode: barcode,
        name: name,
        category: _category,
        subCategory: subCategory,
        price: price,
        minimumStock: minimumStock,
        adultProduct: _adultProduct,
        expirationDate: _expirationDate,
        clearExpirationDate: _expirationDate == null,
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

            DropdownButtonFormField<ProductCategory>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: '대분류',
                border: OutlineInputBorder(),
              ),
              items: ProductCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.label),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _category = value;
                });
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _subCategoryController,
              decoration: const InputDecoration(
                labelText: '중분류',
                hintText: '예: 탄산음료 / 컵라면 / 도시락',
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

            const SizedBox(height: 12),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('성인 상품'),
              subtitle: const Text('주류 / 담배 등 판매 전 성인 확인 필요'),
              value: _adultProduct,
              onChanged: (value) {
                setState(() {
                  _adultProduct = value;
                });
              },
            ),

            const Divider(),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('유통기한'),
              subtitle: Text(
                _expirationDate == null
                    ? '유통기한 관리 안 함'
                    : _formatDate(_expirationDate!),
              ),
              trailing: const Icon(Icons.calendar_month),
              onTap: _selectExpirationDate,
            ),

            if (_expirationDate != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _expirationDate = null;
                  });
                },
                child: const Text('유통기한 제거'),
              ),

            const SizedBox(height: 20),

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
