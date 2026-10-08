import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/pos_palette.dart';
import '../../data/models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pos_provider.dart';
import '../../providers/shift_provider.dart';
import 'held_orders_page.dart';
import 'payment_page.dart';

class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  String _query = '';
  ProductCategory? _selectedCategory;
  String? _selectedSubCategory;

  String _money(int value) {
    final negative = value < 0;
    final text = value.abs().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      final remain = text.length - i;

      buffer.write(text[i]);

      if (remain > 1 && remain % 3 == 1) {
        buffer.write(',');
      }
    }

    return '${negative ? '-' : ''}${buffer.toString()}원';
  }

  List<String> _subCategories(List<Product> products) {
    final values =
        products
            .where(
              (product) =>
                  _selectedCategory == null ||
                  product.category == _selectedCategory,
            )
            .map((product) => product.subCategory.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return values;
  }

  List<Product> _filteredProducts(List<Product> products) {
    final keyword = _query.trim().toLowerCase();

    return products.where((product) {
      final matchesCategory =
          _selectedCategory == null || product.category == _selectedCategory;

      final matchesSubCategory =
          _selectedSubCategory == null ||
          product.subCategory == _selectedSubCategory;

      final matchesKeyword =
          keyword.isEmpty ||
          product.name.toLowerCase().contains(keyword) ||
          product.barcode.toLowerCase().contains(keyword) ||
          product.subCategory.toLowerCase().contains(keyword);

      return matchesCategory && matchesSubCategory && matchesKeyword;
    }).toList();
  }

  Future<void> _clearCart(BuildContext context) async {
    final pos = context.read<PosProvider>();

    if (pos.cart.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('장바구니 비우기'),
          content: const Text('담긴 상품을 모두 취소하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('아니요'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('비우기'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      pos.clearCart();
    }
  }

  void _holdCart(BuildContext context) {
    final pos = context.read<PosProvider>();
    final auth = context.read<AuthProvider>();

    final success = pos.holdCurrentCart(
      cashierName: auth.currentUser?.name ?? '알 수 없음',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? '현재 주문을 보류했습니다.' : '보류할 상품이 없습니다.')),
    );
  }

  void _goPayment(BuildContext context) {
    final pos = context.read<PosProvider>();
    final shift = context.read<ShiftProvider>();

    if (pos.cart.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('장바구니에 상품을 담아주세요.')));
      return;
    }

    if (shift.activeShift == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('결제 전에 근무를 시작해주세요.')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PaymentPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();
    final shift = context.watch<ShiftProvider>();

    if (pos.isLoading || shift.isLoading) {
      return const Scaffold(
        backgroundColor: PosPalette.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final allProducts = pos.products;
    final products = _filteredProducts(allProducts);

    final subCategories = _subCategories(allProducts);

    if (_selectedSubCategory != null &&
        !subCategories.contains(_selectedSubCategory)) {
      _selectedSubCategory = null;
    }

    return Scaffold(
      backgroundColor: PosPalette.background,
      appBar: AppBar(
        backgroundColor: PosPalette.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'POS',
          style: TextStyle(
            color: PosPalette.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: '보류 주문',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HeldOrdersPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.pause_circle_outline),
              ),
              if (pos.heldCarts.isNotEmpty)
                Positioned(
                  right: 5,
                  top: 5,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: PosPalette.danger,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${pos.heldCarts.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Column(
              children: [
                _ShiftStatusBanner(cashierName: shift.activeShift?.cashierName),
                const SizedBox(height: 10),
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
                      borderSide: BorderSide(
                        color: PosPalette.primary,
                        width: 1.4,
                      ),
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
                      _FilterChip(
                        label: '전체',
                        selected: _selectedCategory == null,
                        onTap: () {
                          setState(() {
                            _selectedCategory = null;
                            _selectedSubCategory = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ...ProductCategory.values.map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChip(
                            label: category.label,
                            selected: _selectedCategory == category,
                            onTap: () {
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
                if (subCategories.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _SmallFilterChip(
                          label: '소분류 전체',
                          selected: _selectedSubCategory == null,
                          onTap: () {
                            setState(() {
                              _selectedSubCategory = null;
                            });
                          },
                        ),
                        const SizedBox(width: 7),
                        ...subCategories.map((subCategory) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 7),
                            child: _SmallFilterChip(
                              label: subCategory,
                              selected: _selectedSubCategory == subCategory,
                              onTap: () {
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
                ],
              ],
            ),
          ),
          Expanded(
            child: products.isEmpty
                ? const _EmptyProducts()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                    itemCount: products.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final product = products[index];

                      return _ProductCard(
                        product: product,
                        quantity: pos.quantityOf(product.id),
                        promotionLabel: pos.promotionLabelForProduct(product),
                        money: _money,
                        onAdd: () {
                          pos.addToCart(product);
                        },
                        onRemove: () {
                          pos.removeFromCart(product);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _CartBottomBar(
        itemCount: pos.cartItemCount,
        total: _money(pos.cartTotal),
        enabled: pos.cart.isNotEmpty,
        onHold: () {
          _holdCart(context);
        },
        onClear: () {
          _clearCart(context);
        },
        onPayment: () {
          _goPayment(context);
        },
      ),
    );
  }
}

class _ShiftStatusBanner extends StatelessWidget {
  const _ShiftStatusBanner({required this.cashierName});

  final String? cashierName;

  @override
  Widget build(BuildContext context) {
    final opened = cashierName != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: opened ? PosPalette.softGreen : PosPalette.softOrange,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            opened ? Icons.check_circle_outline : Icons.info_outline,
            size: 20,
            color: opened ? PosPalette.success : PosPalette.warning,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              opened ? '$cashierName님 근무 중' : '근무 시작 후 결제할 수 있어요.',
              style: const TextStyle(
                color: PosPalette.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.quantity,
    required this.promotionLabel,
    required this.money,
    required this.onAdd,
    required this.onRemove,
  });

  final Product product;
  final int quantity;
  final String? promotionLabel;
  final String Function(int value) money;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final expired = product.expirationStatus == ExpirationStatus.expired;

    final stockColor = product.isLowStock
        ? PosPalette.danger
        : PosPalette.textSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PosPalette.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: PosPalette.softBlue,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  product.adultProduct
                      ? Icons.no_adult_content
                      : Icons.inventory_2_outlined,
                  color: product.adultProduct
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
                  ],
                ),
              ),
              Text(
                money(product.price),
                style: const TextStyle(
                  color: PosPalette.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (promotionLabel != null ||
              product.expirationDate != null ||
              product.isLowStock) ...[
            const SizedBox(height: 13),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                if (promotionLabel != null)
                  _StatusBadge(
                    text: promotionLabel!,
                    background: PosPalette.softBlue,
                    foreground: PosPalette.primary,
                  ),
                if (product.isLowStock)
                  const _StatusBadge(
                    text: '재고 부족',
                    background: PosPalette.softRed,
                    foreground: PosPalette.danger,
                  ),
                if (product.expirationDate != null &&
                    product.expirationStatus != ExpirationStatus.normal &&
                    product.expirationStatus != ExpirationStatus.none)
                  _StatusBadge(
                    text: product.expirationLabel,
                    background: expired
                        ? PosPalette.softRed
                        : PosPalette.softOrange,
                    foreground: expired
                        ? PosPalette.danger
                        : PosPalette.warning,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                '재고 ${product.stock}개',
                style: TextStyle(
                  color: stockColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (quantity > 0) ...[
                _CircleActionButton(icon: Icons.remove, onTap: onRemove),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '$quantity',
                    style: const TextStyle(
                      color: PosPalette.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
              _CircleActionButton(
                icon: Icons.add,
                enabled: !expired && product.stock > quantity,
                filled: true,
                onTap: onAdd,
              ),
            ],
          ),
          if (expired) ...[
            const SizedBox(height: 8),
            const Text(
              '만료된 상품은 판매할 수 없습니다.',
              style: TextStyle(
                color: PosPalette.danger,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CartBottomBar extends StatelessWidget {
  const _CartBottomBar({
    required this.itemCount,
    required this.total,
    required this.enabled,
    required this.onHold,
    required this.onClear,
    required this.onPayment,
  });

  final int itemCount;
  final String total;
  final bool enabled;
  final VoidCallback onHold;
  final VoidCallback onClear;
  final VoidCallback onPayment;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: PosPalette.surface,
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 18,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: '보류',
              onPressed: enabled ? onHold : null,
              icon: const Icon(Icons.pause_circle_outline),
            ),
            IconButton(
              tooltip: '취소',
              onPressed: enabled ? onClear : null,
              icon: const Icon(Icons.delete_outline),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: FilledButton(
                onPressed: enabled ? onPayment : null,
                style: FilledButton.styleFrom(
                  backgroundColor: PosPalette.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$itemCount개',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      total,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      '결제',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      side: BorderSide.none,
      selectedColor: PosPalette.primary,
      backgroundColor: PosPalette.surface,
      labelStyle: TextStyle(
        color: selected ? Colors.white : PosPalette.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (value) {
        onTap();
      },
    );
  }
}

class _SmallFilterChip extends StatelessWidget {
  const _SmallFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      selectedColor: PosPalette.textPrimary,
      backgroundColor: PosPalette.surface,
      labelStyle: TextStyle(
        fontSize: 12,
        color: selected ? Colors.white : PosPalette.textSecondary,
      ),
      onSelected: (value) {
        onTap();
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    required this.onTap,
    this.enabled = true,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: !enabled
          ? PosPalette.background
          : filled
          ? PosPalette.primary
          : PosPalette.background,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            size: 20,
            color: !enabled
                ? PosPalette.textTertiary
                : filled
                ? Colors.white
                : PosPalette.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 50,
              color: PosPalette.textTertiary,
            ),
            SizedBox(height: 12),
            Text(
              '조건에 맞는 상품이 없습니다.',
              style: TextStyle(
                color: PosPalette.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
