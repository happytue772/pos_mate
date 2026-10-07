import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pos_provider.dart';
import '../../providers/shift_provider.dart';
import '../shift/shift_open_page.dart';
import 'held_orders_page.dart';
import 'payment_page.dart';

class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  final TextEditingController _searchController = TextEditingController();

  String _query = '';

  ProductCategory? _selectedCategory;

  String? _selectedSubCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _categoryCount(PosProvider pos, ProductCategory category) {
    return pos.products.where((product) => product.category == category).length;
  }

  List<String> _subCategories(PosProvider pos) {
    final category = _selectedCategory;

    if (category == null) {
      return [];
    }

    final values = pos.products
        .where((product) => product.category == category)
        .map((product) => product.subCategory)
        .toSet()
        .toList();

    values.sort();

    return values;
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();
    final shiftProvider = context.watch<ShiftProvider>();
    final auth = context.watch<AuthProvider>();

    if (!shiftProvider.hasActiveShift) {
      return Scaffold(
        appBar: AppBar(title: const Text('POS 판매')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_clock_outlined, size: 64),
              const SizedBox(height: 16),
              const Text('근무를 시작해야 판매할 수 있습니다.'),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ShiftOpenPage()),
                  );
                },
                child: const Text('근무 시작'),
              ),
            ],
          ),
        ),
      );
    }

    final query = _query.trim().toLowerCase();

    final products = pos.products.where((product) {
      final matchesCategory =
          _selectedCategory == null || product.category == _selectedCategory;

      final matchesSubCategory =
          _selectedSubCategory == null ||
          product.subCategory == _selectedSubCategory;

      final matchesQuery =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.category.label.toLowerCase().contains(query) ||
          product.subCategory.toLowerCase().contains(query) ||
          product.barcode.contains(query);

      return matchesCategory && matchesSubCategory && matchesQuery;
    }).toList();

    final subCategories = _subCategories(pos);

    return Scaffold(
      appBar: AppBar(
        title: const Text('POS 판매'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HeldOrdersPage()),
              );
            },
            icon: const Icon(Icons.pause_circle_outline),
            tooltip: '보류 주문',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '상품명 / 카테고리 / 바코드 검색',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();

                          setState(() {
                            _query = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _query = value;
                });
              },
            ),
          ),

          // 대분류
          SizedBox(
            height: 52,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('전체 ${pos.products.length}'),
                    selected: _selectedCategory == null,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = null;
                        _selectedSubCategory = null;
                      });
                    },
                  ),
                ),
                ...ProductCategory.values.map((category) {
                  final count = _categoryCount(pos, category);

                  if (count == 0) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${category.label} $count'),
                      selected: _selectedCategory == category,
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = category;
                          _selectedSubCategory = null;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          // 소분류
          if (_selectedCategory != null && subCategories.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('전체'),
                        selected: _selectedSubCategory == null,
                        onSelected: (_) {
                          setState(() {
                            _selectedSubCategory = null;
                          });
                        },
                      ),
                    ),
                    ...subCategories.map((subCategory) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(subCategory),
                          selected: _selectedSubCategory == subCategory,
                          onSelected: (_) {
                            setState(() {
                              _selectedSubCategory = subCategory;
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedCategory == null
                        ? '전체 상품'
                        : _selectedSubCategory == null
                        ? _selectedCategory!.label
                        : '${_selectedCategory!.label} > $_selectedSubCategory',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text('${products.length}개 상품'),
              ],
            ),
          ),

          Expanded(
            child: products.isEmpty
                ? const Center(child: Text('조건에 맞는 상품이 없습니다.'))
                : ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];

                      final quantity = pos.quantityOf(product.id);

                      final promotion = pos.promotionLabelForProduct(product);

                      final isExpired =
                          product.expirationStatus == ExpirationStatus.expired;

                      final canAdd =
                          product.stock > 0 &&
                          quantity < product.stock &&
                          !isExpired;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Icon(
                                product.adultProduct
                                    ? Icons.verified_user_outlined
                                    : Icons.inventory_2_outlined,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (promotion != null)
                                  Chip(
                                    visualDensity: VisualDensity.compact,
                                    label: Text(promotion),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              '${product.category.label} > '
                              '${product.subCategory}\n'
                              '${product.price}원 · '
                              '재고 ${product.stock}개'
                              '${product.expirationDate != null ? '\n${product.expirationLabel}' : ''}'
                              '${isExpired ? '\n판매 불가 - 유통기한 만료' : ''}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: quantity > 0
                                      ? () {
                                          pos.removeFromCart(product);
                                        }
                                      : null,
                                  icon: const Icon(Icons.remove),
                                ),
                                SizedBox(
                                  width: 28,
                                  child: Text(
                                    '$quantity',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: canAdd
                                      ? () {
                                          pos.addToCart(product);
                                        }
                                      : null,
                                  icon: const Icon(Icons.add),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('상품 ${pos.cartItemCount}개'),
                    Text(
                      '${pos.cartTotal}원',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: pos.cart.isNotEmpty ? pos.clearCart : null,
                        child: const Text('전체 취소'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: pos.cart.isNotEmpty
                            ? () {
                                final success = pos.holdCurrentCart(
                                  cashierName:
                                      auth.currentUser?.name ?? '알 수 없음',
                                );

                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('주문을 보류했습니다.'),
                                    ),
                                  );
                                }
                              }
                            : null,
                        icon: const Icon(Icons.pause_circle_outline),
                        label: const Text('보류'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: pos.cart.isNotEmpty
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PaymentPage(),
                              ),
                            );
                          }
                        : null,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('결제하기'),
                    ),
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
