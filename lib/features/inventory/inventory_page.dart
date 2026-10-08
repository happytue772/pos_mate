import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/pos_palette.dart';
import '../../data/models/product.dart';
import '../../providers/pos_provider.dart';

enum _InventoryFilter { all, lowStock, expiration }

extension _InventoryFilterLabel on _InventoryFilter {
  String get label {
    switch (this) {
      case _InventoryFilter.all:
        return '전체';
      case _InventoryFilter.lowStock:
        return '재고 부족';
      case _InventoryFilter.expiration:
        return '유통기한';
    }
  }
}

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  String _query = '';
  ProductCategory? _category;
  _InventoryFilter _filter = _InventoryFilter.all;

  bool _expirationAttention(Product product) {
    return product.expirationStatus == ExpirationStatus.soon ||
        product.expirationStatus == ExpirationStatus.today ||
        product.expirationStatus == ExpirationStatus.expired;
  }

  List<Product> _filtered(List<Product> source) {
    final keyword = _query.trim().toLowerCase();

    return source.where((product) {
      final matchesQuery =
          keyword.isEmpty ||
          product.name.toLowerCase().contains(keyword) ||
          product.barcode.toLowerCase().contains(keyword) ||
          product.subCategory.toLowerCase().contains(keyword);

      final matchesCategory =
          _category == null || product.category == _category;

      final matchesFilter = switch (_filter) {
        _InventoryFilter.all => true,
        _InventoryFilter.lowStock => product.isLowStock,
        _InventoryFilter.expiration => _expirationAttention(product),
      };

      return matchesQuery && matchesCategory && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();

    if (pos.isLoading) {
      return const Scaffold(
        backgroundColor: PosPalette.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final products = pos.products;

    final lowStockCount = products
        .where((product) => product.isLowStock)
        .length;

    final expirationCount = products.where(_expirationAttention).length;

    final totalStock = products.fold<int>(
      0,
      (sum, product) => sum + product.stock,
    );

    final filtered = _filtered(products);

    return Scaffold(
      backgroundColor: PosPalette.background,
      appBar: AppBar(
        backgroundColor: PosPalette.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          '재고',
          style: TextStyle(
            color: PosPalette.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: '상품',
                  value: '${products.length}',
                  unit: '종',
                  icon: Icons.inventory_2_outlined,
                  background: PosPalette.softBlue,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _SummaryCard(
                  label: '총 재고',
                  value: '$totalStock',
                  unit: '개',
                  icon: Icons.warehouse_outlined,
                  background: PosPalette.softGreen,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _SummaryCard(
                  label: '주의',
                  value: '${lowStockCount + expirationCount}',
                  unit: '건',
                  icon: Icons.warning_amber_rounded,
                  background: PosPalette.softOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              hintText: '상품명 · 바코드 · 소분류 검색',
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: PosPalette.surface,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(18)),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(18)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: PosPalette.primary, width: 1.4),
                borderRadius: BorderRadius.all(Radius.circular(18)),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _query = value;
              });
            },
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._InventoryFilter.values.map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter.label),
                      selected: _filter == filter,
                      showCheckmark: false,
                      side: BorderSide.none,
                      selectedColor: PosPalette.primary,
                      backgroundColor: PosPalette.surface,
                      labelStyle: TextStyle(
                        color: _filter == filter
                            ? Colors.white
                            : PosPalette.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _filter = filter;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ChoiceChip(
                  label: const Text('전체 분류'),
                  selected: _category == null,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  side: BorderSide.none,
                  selectedColor: PosPalette.textPrimary,
                  backgroundColor: PosPalette.surface,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: _category == null
                        ? Colors.white
                        : PosPalette.textSecondary,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _category = null;
                    });
                  },
                ),
                const SizedBox(width: 7),
                ...ProductCategory.values.map((category) {
                  final selected = _category == category;

                  return Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      label: Text(category.label),
                      selected: selected,
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      side: BorderSide.none,
                      selectedColor: PosPalette.textPrimary,
                      backgroundColor: PosPalette.surface,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: selected
                            ? Colors.white
                            : PosPalette.textSecondary,
                      ),
                      onSelected: (value) {
                        setState(() {
                          _category = category;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '재고 목록',
                  style: TextStyle(
                    color: PosPalette.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${filtered.length}개',
                style: const TextStyle(
                  color: PosPalette.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (filtered.isEmpty)
            const _EmptyInventory()
          else
            ...filtered.map(
              (product) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _InventoryCard(product: product),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.background,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: PosPalette.surface,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: PosPalette.textPrimary),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: PosPalette.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: PosPalette.textPrimary),
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    fontSize: 12,
                    color: PosPalette.textSecondary,
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

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final expired = product.expirationStatus == ExpirationStatus.expired;

    final attention =
        product.expirationStatus == ExpirationStatus.soon ||
        product.expirationStatus == ExpirationStatus.today ||
        expired;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PosPalette.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: product.isLowStock
                  ? PosPalette.softRed
                  : PosPalette.softBlue,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: product.isLowStock
                  ? PosPalette.danger
                  : PosPalette.primary,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: PosPalette.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.category.label} · ${product.subCategory}',
                  style: const TextStyle(
                    color: PosPalette.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    if (product.isLowStock)
                      const _Badge(
                        text: '재고 부족',
                        background: PosPalette.softRed,
                        foreground: PosPalette.danger,
                      ),
                    if (attention)
                      _Badge(
                        text: product.expirationLabel,
                        background: expired
                            ? PosPalette.softRed
                            : PosPalette.softOrange,
                        foreground: expired
                            ? PosPalette.danger
                            : PosPalette.warning,
                      ),
                    if (product.adultProduct)
                      const _Badge(
                        text: '성인 상품',
                        background: PosPalette.softOrange,
                        foreground: PosPalette.warning,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${product.stock}',
                style: TextStyle(
                  color: product.isLowStock
                      ? PosPalette.danger
                      : PosPalette.textPrimary,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                '현재 재고',
                style: TextStyle(color: PosPalette.textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 8),
              Text(
                '최소 ${product.minimumStock}',
                style: const TextStyle(
                  color: PosPalette.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 50),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: PosPalette.textTertiary,
            ),
            SizedBox(height: 12),
            Text(
              '조건에 맞는 재고가 없습니다.',
              style: TextStyle(color: PosPalette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
