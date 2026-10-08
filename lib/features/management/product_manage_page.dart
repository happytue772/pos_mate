import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/pos_palette.dart';
import '../../data/models/product.dart';
import '../../providers/pos_provider.dart';
import 'product_form_page.dart';

class ProductManagePage extends StatefulWidget {
  const ProductManagePage({super.key});

  @override
  State<ProductManagePage> createState() => _ProductManagePageState();
}

class _ProductManagePageState extends State<ProductManagePage> {
  String _query = '';
  ProductCategory? _category;

  List<Product> _filtered(List<Product> products) {
    final keyword = _query.trim().toLowerCase();

    return products.where((product) {
      final matchesQuery =
          keyword.isEmpty ||
          product.name.toLowerCase().contains(keyword) ||
          product.barcode.toLowerCase().contains(keyword) ||
          product.subCategory.toLowerCase().contains(keyword);

      final matchesCategory =
          _category == null || product.category == _category;

      return matchesQuery && matchesCategory;
    }).toList();
  }

  Future<void> _delete(BuildContext context, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('상품 삭제'),
          content: Text(
            '${product.name} 상품을 삭제하시겠습니까?\n'
            '판매 이력이 있는 상품은 삭제할 수 없습니다.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: FilledButton.styleFrom(backgroundColor: PosPalette.danger),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final success = context.read<PosProvider>().deleteProduct(product.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '${product.name} 상품을 삭제했습니다.'
              : '판매 이력 또는 장바구니에 사용 중인 상품은 삭제할 수 없습니다.',
        ),
      ),
    );
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
    final filtered = _filtered(products);

    final lowStock = products.where((product) => product.isLowStock).length;

    final adultProducts = products
        .where((product) => product.adultProduct)
        .length;

    return Scaffold(
      backgroundColor: PosPalette.background,
      appBar: AppBar(
        backgroundColor: PosPalette.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          '상품 관리',
          style: TextStyle(
            color: PosPalette.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: '상품 등록',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductFormPage(),
                ),
              );
            },
            icon: const Icon(Icons.add_circle_outline),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProductFormPage()),
          );
        },
        backgroundColor: PosPalette.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          '상품 등록',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        children: [
          Row(
            children: [
              Expanded(
                child: _ManageSummary(
                  label: '전체 상품',
                  value: '${products.length}종',
                  icon: Icons.inventory_2_outlined,
                  background: PosPalette.softBlue,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _ManageSummary(
                  label: '저재고',
                  value: '$lowStock건',
                  icon: Icons.warning_amber_rounded,
                  background: PosPalette.softOrange,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _ManageSummary(
                  label: '성인 상품',
                  value: '$adultProducts종',
                  icon: Icons.no_adult_content,
                  background: PosPalette.softRed,
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
            height: 39,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ChoiceChip(
                  label: const Text('전체'),
                  selected: _category == null,
                  showCheckmark: false,
                  side: BorderSide.none,
                  selectedColor: PosPalette.primary,
                  backgroundColor: PosPalette.surface,
                  labelStyle: TextStyle(
                    color: _category == null
                        ? Colors.white
                        : PosPalette.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (value) {
                    setState(() {
                      _category = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ...ProductCategory.values.map((category) {
                  final selected = _category == category;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category.label),
                      selected: selected,
                      showCheckmark: false,
                      side: BorderSide.none,
                      selectedColor: PosPalette.primary,
                      backgroundColor: PosPalette.surface,
                      labelStyle: TextStyle(
                        color: selected
                            ? Colors.white
                            : PosPalette.textSecondary,
                        fontWeight: FontWeight.w600,
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
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '상품 목록',
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
            const _EmptyProducts()
          else
            ...filtered.map(
              (product) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ManageProductCard(
                  product: product,
                  onEdit: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductFormPage(product: product),
                      ),
                    );
                  },
                  onDelete: () {
                    _delete(context, product);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ManageSummary extends StatelessWidget {
  const _ManageSummary({
    required this.label,
    required this.value,
    required this.icon,
    required this.background,
  });

  final String label;
  final String value;
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
          Text(
            value,
            style: const TextStyle(
              color: PosPalette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManageProductCard extends StatelessWidget {
  const _ManageProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PosPalette.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              color: product.isLowStock
                  ? PosPalette.softRed
                  : PosPalette.softBlue,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              product.adultProduct
                  ? Icons.no_adult_content
                  : Icons.inventory_2_outlined,
              color: product.isLowStock || product.adultProduct
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
                const SizedBox(height: 7),
                Text(
                  '판매 ${product.price}원 · 원가 ${product.costPrice}원 · 재고 ${product.stock}개',
                  style: const TextStyle(
                    color: PosPalette.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: '상품 메뉴',
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined),
                      SizedBox(width: 10),
                      Text('수정'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: PosPalette.danger),
                      SizedBox(width: 10),
                      Text('삭제', style: TextStyle(color: PosPalette.danger)),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts();

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
              '조건에 맞는 상품이 없습니다.',
              style: TextStyle(color: PosPalette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
