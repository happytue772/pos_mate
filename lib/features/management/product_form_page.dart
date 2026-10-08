import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _barcodeController;
  late final TextEditingController _nameController;
  late final TextEditingController _subCategoryController;
  late final TextEditingController _priceController;
  late final TextEditingController _costPriceController;
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

    _costPriceController = TextEditingController(
      text: product?.costPrice.toString() ?? '0',
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
    _costPriceController.dispose();
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

  String? _nonNegativeNumberValidator(String? value) {
    final number = int.tryParse(value ?? '');

    if (number == null || number < 0) {
      return '0 이상의 숫자를 입력해주세요.';
    }

    return null;
  }

  String? _priceValidator(String? value) {
    final number = int.tryParse(value ?? '');

    if (number == null || number <= 0) {
      return '1원 이상의 판매 가격을 입력해주세요.';
    }

    return null;
  }

  int get _previewPrice {
    return int.tryParse(_priceController.text) ?? 0;
  }

  int get _previewCostPrice {
    return int.tryParse(_costPriceController.text) ?? 0;
  }

  int get _previewMargin {
    return _previewPrice - _previewCostPrice;
  }

  double get _previewMarginRate {
    if (_previewPrice <= 0) {
      return 0;
    }

    return _previewMargin / _previewPrice * 100;
  }

  Future<void> _selectExpirationDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 3650)),
    );

    if (!mounted || selected == null) {
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

    final name = _nameController.text.trim();

    final subCategory = _subCategoryController.text.trim();

    final price = int.parse(_priceController.text);

    final costPrice = int.parse(_costPriceController.text);

    final stock = int.parse(_stockController.text);

    final minimumStock = int.parse(_minimumStockController.text);

    if (pos.barcodeExists(barcode, exceptProductId: widget.product?.id)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미 등록된 바코드 또는 상품 코드입니다.')));

      return;
    }

    if (!isEdit) {
      pos.addProduct(
        barcode: barcode,
        name: name,
        category: _category,
        subCategory: subCategory,
        price: price,
        costPrice: costPrice,
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
        costPrice: costPrice,
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
            const Text(
              '기본 정보',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            // -------------------------------------------------
            // 바코드 / 상품 코드
            // 한글, 영어, 숫자 모두 허용
            // -------------------------------------------------
            TextFormField(
              controller: _barcodeController,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '바코드 / 상품 코드',
                hintText: '예: 8801234567890 / ITEM-001',
                border: OutlineInputBorder(),
              ),
              validator: _requiredValidator,
            ),

            const SizedBox(height: 12),

            // -------------------------------------------------
            // 상품명
            // 한글 + 영어 + 숫자 + 공백 허용
            // -------------------------------------------------
            TextFormField(
              controller: _nameController,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '상품명',
                hintText: '예: 코카콜라 제로 500ml',
                border: OutlineInputBorder(),
              ),
              validator: _requiredValidator,
            ),

            const SizedBox(height: 12),

            // -------------------------------------------------
            // 대분류
            // -------------------------------------------------
            DropdownButtonFormField<ProductCategory>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: '대분류',
                border: OutlineInputBorder(),
              ),
              items: ProductCategory.values.map((category) {
                return DropdownMenuItem<ProductCategory>(
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

            // -------------------------------------------------
            // 소분류
            // 한글/영문 자유 입력
            // -------------------------------------------------
            TextFormField(
              controller: _subCategoryController,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '소분류',
                hintText: '예: 탄산음료 / 컵라면 / 도시락 / Coffee',
                border: OutlineInputBorder(),
              ),
              validator: _requiredValidator,
            ),

            const SizedBox(height: 24),

            const Text(
              '가격 / 수익',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            // -------------------------------------------------
            // 판매 가격
            // -------------------------------------------------
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '판매 가격',
                suffixText: '원',
                border: OutlineInputBorder(),
              ),
              validator: _priceValidator,
              onChanged: (_) {
                setState(() {});
              },
            ),

            const SizedBox(height: 12),

            // -------------------------------------------------
            // 상품 원가
            // -------------------------------------------------
            TextFormField(
              controller: _costPriceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '상품 원가',
                suffixText: '원',
                helperText: '매출이익 및 마진 분석에 사용됩니다.',
                border: OutlineInputBorder(),
              ),
              validator: _nonNegativeNumberValidator,
              onChanged: (_) {
                setState(() {});
              },
            ),

            const SizedBox(height: 12),

            // -------------------------------------------------
            // 예상 마진 미리보기
            // -------------------------------------------------
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '예상 단품 수익',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [const Text('판매가'), Text('$_previewPrice원')],
                    ),

                    const SizedBox(height: 6),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [const Text('원가'), Text('$_previewCostPrice원')],
                    ),

                    const Divider(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('단품 마진'),
                        Text(
                          '$_previewMargin원',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('마진율'),
                        Text(
                          '${_previewMarginRate.toStringAsFixed(1)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              '재고',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            // -------------------------------------------------
            // 초기 재고
            // -------------------------------------------------
            TextFormField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              readOnly: isEdit,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: isEdit ? '현재 재고' : '초기 재고',
                suffixText: '개',
                helperText: isEdit
                    ? '기존 상품의 재고는 입고 또는 재고 조정 메뉴에서 변경합니다.'
                    : '신규 상품의 초기 재고를 입력합니다.',
                border: const OutlineInputBorder(),
              ),
              validator: _nonNegativeNumberValidator,
            ),

            const SizedBox(height: 12),

            // -------------------------------------------------
            // 최소 재고
            // -------------------------------------------------
            TextFormField(
              controller: _minimumStockController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: '최소 재고',
                suffixText: '개',
                helperText: '현재 재고가 이 수량 이하가 되면 재고 부족으로 표시합니다.',
                border: OutlineInputBorder(),
              ),
              validator: _nonNegativeNumberValidator,
            ),

            const SizedBox(height: 24),

            const Text(
              '판매 / 관리 옵션',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 4),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('성인 상품'),
              subtitle: const Text('주류 / 담배 등 판매 전 성인 확인이 필요한 상품'),
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
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('유통기한'),
              subtitle: Text(
                _expirationDate == null
                    ? '유통기한 관리 안 함'
                    : _formatDate(_expirationDate!),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectExpirationDate,
            ),

            if (_expirationDate != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _expirationDate = null;
                    });
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('유통기한 제거'),
                ),
              ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(isEdit ? '상품 수정 저장' : '상품 등록'),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
