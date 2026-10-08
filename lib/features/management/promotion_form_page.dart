import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models/promotion.dart';
import '../../providers/pos_provider.dart';

class PromotionFormPage extends StatefulWidget {
  const PromotionFormPage({super.key, this.promotion});

  final Promotion? promotion;

  @override
  State<PromotionFormPage> createState() => _PromotionFormPageState();
}

class _PromotionFormPageState extends State<PromotionFormPage> {
  final _formKey = GlobalKey<FormState>();

  int? _productId;

  PromotionType _type = PromotionType.onePlusOne;

  DateTime _startDate = DateTime.now();

  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  bool _enabled = true;

  final TextEditingController _percentController = TextEditingController();

  final TextEditingController _specialPriceController = TextEditingController();

  bool get isEdit => widget.promotion != null;

  @override
  void initState() {
    super.initState();

    final promotion = widget.promotion;

    if (promotion != null) {
      _productId = promotion.productId;

      _type = promotion.type;

      _startDate = promotion.startDate;

      _endDate = promotion.endDate;

      _enabled = promotion.enabled;

      if (promotion.percent != null) {
        _percentController.text = promotion.percent.toString();
      }

      if (promotion.specialPrice != null) {
        _specialPriceController.text = promotion.specialPrice.toString();
      }
    }
  }

  @override
  void dispose() {
    _percentController.dispose();
    _specialPriceController.dispose();

    super.dispose();
  }

  String _formatDate(DateTime date) {
    String two(int value) {
      return value.toString().padLeft(2, '0');
    }

    return '${date.year}-'
        '${two(date.month)}-'
        '${two(date.day)}';
  }

  Future<void> _selectStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _startDate = selected;

      if (_endDate.isBefore(_startDate)) {
        _endDate = _startDate;
      }
    });
  }

  Future<void> _selectEndDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2035),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _endDate = selected;
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_productId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('행사를 적용할 상품을 선택해주세요.')));

      return;
    }

    int? percent;

    int? specialPrice;

    if (_type == PromotionType.percentDiscount) {
      percent = int.tryParse(_percentController.text);
    }

    if (_type == PromotionType.specialPrice) {
      specialPrice = int.tryParse(_specialPriceController.text);
    }

    final pos = context.read<PosProvider>();

    bool success;

    if (!isEdit) {
      success = pos.addPromotion(
        productId: _productId!,
        type: _type,
        startDate: _startDate,
        endDate: _endDate,
        percent: percent,
        specialPrice: specialPrice,
        enabled: _enabled,
      );
    } else {
      final current = widget.promotion!;

      final updated = Promotion(
        id: current.id,
        productId: _productId!,
        type: _type,
        startDate: _startDate,
        endDate: _endDate,
        percent: _type == PromotionType.percentDiscount ? percent : null,
        specialPrice: _type == PromotionType.specialPrice ? specialPrice : null,
        enabled: _enabled,
      );

      success = pos.updatePromotion(updated);
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '행사를 저장할 수 없습니다. '
            '같은 상품의 행사 기간이 겹치거나 '
            '입력값이 올바르지 않은지 확인해주세요.',
          ),
        ),
      );

      return;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? '행사 수정' : '행사 등록')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<int>(
              initialValue: _productId,
              decoration: const InputDecoration(
                labelText: '상품',
                border: OutlineInputBorder(),
              ),
              items: pos.products.map((product) {
                return DropdownMenuItem<int>(
                  value: product.id,
                  child: Text(product.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _productId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return '상품을 선택해주세요.';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<PromotionType>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: '행사 종류',
                border: OutlineInputBorder(),
              ),
              items: PromotionType.values.map((type) {
                return DropdownMenuItem<PromotionType>(
                  value: type,
                  child: Text(type.label),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _type = value;
                });
              },
            ),

            if (_type == PromotionType.percentDiscount) ...[
              const SizedBox(height: 16),

              TextFormField(
                controller: _percentController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: '할인율',
                  suffixText: '%',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final percent = int.tryParse(value ?? '');

                  if (percent == null || percent <= 0 || percent >= 100) {
                    return '1~99 사이의 할인율을 입력해주세요.';
                  }

                  return null;
                },
              ),
            ],

            if (_type == PromotionType.specialPrice) ...[
              const SizedBox(height: 16),

              TextFormField(
                controller: _specialPriceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: '특가',
                  suffixText: '원',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final price = int.tryParse(value ?? '');

                  if (price == null || price <= 0) {
                    return '1원 이상의 특가를 입력해주세요.';
                  }

                  return null;
                },
              ),
            ],

            const SizedBox(height: 20),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: const Text('시작일'),
                    trailing: Text(_formatDate(_startDate)),
                    onTap: _selectStartDate,
                  ),

                  const Divider(height: 1),

                  ListTile(
                    leading: const Icon(Icons.event_outlined),
                    title: const Text('종료일'),
                    trailing: Text(_formatDate(_endDate)),
                    onTap: _selectEndDate,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('행사 활성화'),
              subtitle: const Text('OFF 상태에서는 기간 내라도 POS에 적용되지 않습니다.'),
              value: _enabled,
              onChanged: (value) {
                setState(() {
                  _enabled = value;
                });
              },
            ),

            const SizedBox(height: 24),

            FilledButton(
              onPressed: _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(isEdit ? '행사 수정 저장' : '행사 등록'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
