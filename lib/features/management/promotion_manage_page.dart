import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/promotion.dart';
import '../../providers/pos_provider.dart';
import 'promotion_form_page.dart';

class PromotionManagePage extends StatelessWidget {
  const PromotionManagePage({super.key});

  String _formatDate(DateTime date) {
    String two(int value) {
      return value.toString().padLeft(2, '0');
    }

    return '${date.year}-'
        '${two(date.month)}-'
        '${two(date.day)}';
  }

  String _productName(PosProvider pos, int productId) {
    for (final product in pos.products) {
      if (product.id == productId) {
        return product.name;
      }
    }

    return '삭제된 상품';
  }

  String _promotionDetail(Promotion promotion) {
    switch (promotion.type) {
      case PromotionType.onePlusOne:
        return '1개 구매 시 1개 증정';

      case PromotionType.twoPlusOne:
        return '2개 구매 시 1개 증정';

      case PromotionType.percentDiscount:
        return '${promotion.percent ?? 0}% 할인';

      case PromotionType.specialPrice:
        return '${promotion.specialPrice ?? 0}원 특가';
    }
  }

  Future<void> _delete(
    BuildContext context,
    PosProvider pos,
    Promotion promotion,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('행사 삭제'),
          content: const Text('이 행사를 삭제하시겠습니까?'),
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
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    pos.deletePromotion(promotion.id);
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();

    final promotions = [...pos.promotions]
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    return Scaffold(
      appBar: AppBar(title: const Text('행사 관리')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PromotionFormPage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('행사 등록'),
      ),
      body: promotions.isEmpty
          ? const Center(child: Text('등록된 행사가 없습니다.'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              itemCount: promotions.length,
              itemBuilder: (context, index) {
                final promotion = promotions[index];

                final active = promotion.isActive;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        promotion.type.label,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    title: Text(_productName(pos, promotion.productId)),
                    subtitle: Text(
                      '${_promotionDetail(promotion)}\n'
                      '${_formatDate(promotion.startDate)} '
                      '~ ${_formatDate(promotion.endDate)}\n'
                      '${promotion.enabled ? (active ? '행사 적용 중' : '활성 · 기간 외') : '비활성'}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        switch (value) {
                          case 'edit':
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PromotionFormPage(promotion: promotion),
                              ),
                            );
                            break;

                          case 'toggle':
                            final success = pos.togglePromotion(promotion.id);

                            if (!success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '다른 활성 행사와 기간이 겹쳐 활성화할 수 없습니다.',
                                  ),
                                ),
                              );
                            }
                            break;

                          case 'delete':
                            await _delete(context, pos, promotion);
                            break;
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('수정')),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(promotion.enabled ? '비활성화' : '활성화'),
                        ),
                        const PopupMenuItem(value: 'delete', child: Text('삭제')),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PromotionFormPage(promotion: promotion),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
