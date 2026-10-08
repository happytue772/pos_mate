import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/pos_palette.dart';
import '../../data/models/sale.dart';
import '../../providers/pos_provider.dart';
import '../../providers/shift_provider.dart';

class VoidSalePage extends StatefulWidget {
  const VoidSalePage({super.key});

  @override
  State<VoidSalePage> createState() => _VoidSalePageState();
}

class _VoidSalePageState extends State<VoidSalePage> {
  String _query = '';

  String _money(int value) {
    final raw = value.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < raw.length; i++) {
      final remain = raw.length - i;
      buffer.write(raw[i]);

      if (remain > 1 && remain % 3 == 1) {
        buffer.write(',');
      }
    }

    return '${buffer.toString()}원';
  }

  String _dateTime(DateTime value) {
    String two(int number) {
      return number.toString().padLeft(2, '0');
    }

    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}';
  }

  Future<void> _voidSale(Sale sale, int activeShiftId) async {
    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('거래 취소'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${sale.receiptNumber}\n${_money(sale.totalAmount)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                maxLines: 2,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '취소 사유',
                  hintText: '예: 결제수단 선택 오류',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('닫기'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.pop(dialogContext, value);
              },
              style: FilledButton.styleFrom(backgroundColor: PosPalette.danger),
              child: const Text('거래 취소'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (reason == null || !mounted) {
      return;
    }

    final success = context.read<PosProvider>().voidSale(
      saleId: sale.id,
      activeShiftId: activeShiftId,
      reason: reason,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '거래를 취소하고 재고를 복구했습니다.' : '거래를 취소할 수 없습니다.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();
    final shift = context.watch<ShiftProvider>();

    final activeShiftId = shift.activeShift?.id;

    final keyword = _query.trim().toLowerCase();

    final sales = pos.sales.where((sale) {
      return keyword.isEmpty ||
          sale.receiptNumber.toLowerCase().contains(keyword) ||
          sale.cashierName.toLowerCase().contains(keyword);
    }).toList();

    return Scaffold(
      backgroundColor: PosPalette.background,
      appBar: AppBar(
        backgroundColor: PosPalette.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          '거래 취소',
          style: TextStyle(
            color: PosPalette.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: activeShiftId == null
                  ? PosPalette.softOrange
                  : PosPalette.softBlue,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              activeShiftId == null
                  ? '거래 취소는 근무 중에만 가능합니다.'
                  : '현재 근무에서 결제된 미환불 거래만 취소할 수 있습니다. '
                        '취소 시 판매 재고가 자동으로 복구됩니다.',
              style: const TextStyle(
                color: PosPalette.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              hintText: '영수증 번호 · 직원 검색',
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: PosPalette.surface,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(18)),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _query = value;
              });
            },
          ),
          const SizedBox(height: 16),
          if (sales.isEmpty)
            const _VoidEmpty()
          else
            ...sales.map((sale) {
              VoidCallback? onVoid;

              if (activeShiftId != null &&
                  pos.canVoidSale(sale: sale, activeShiftId: activeShiftId)) {
                final shiftId = activeShiftId;

                onVoid = () {
                  _voidSale(sale, shiftId);
                };
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _VoidSaleCard(
                  sale: sale,
                  canVoid: onVoid != null,
                  money: _money,
                  dateTime: _dateTime,
                  onVoid: onVoid,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _VoidSaleCard extends StatelessWidget {
  const _VoidSaleCard({
    required this.sale,
    required this.canVoid,
    required this.money,
    required this.dateTime,
    required this.onVoid,
  });

  final Sale sale;
  final bool canVoid;
  final String Function(int value) money;
  final String Function(DateTime value) dateTime;
  final VoidCallback? onVoid;

  @override
  Widget build(BuildContext context) {
    Color badgeBackground = PosPalette.softGreen;
    Color badgeColor = PosPalette.success;

    if (sale.status == SaleStatus.voided) {
      badgeBackground = PosPalette.softRed;
      badgeColor = PosPalette.danger;
    } else if (sale.status == SaleStatus.refunded ||
        sale.status == SaleStatus.partiallyRefunded) {
      badgeBackground = PosPalette.softOrange;
      badgeColor = PosPalette.warning;
    }

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
            children: [
              Expanded(
                child: Text(
                  sale.receiptNumber,
                  style: const TextStyle(
                    color: PosPalette.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  sale.status.label,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            '${sale.cashierName} · ${dateTime(sale.soldAt)}',
            style: const TextStyle(
              color: PosPalette.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                money(sale.totalAmount),
                style: const TextStyle(
                  color: PosPalette.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                sale.paymentMethod.label,
                style: const TextStyle(color: PosPalette.textSecondary),
              ),
            ],
          ),
          if (sale.isVoided) ...[
            const SizedBox(height: 10),
            Text(
              '취소 사유: ${sale.voidReason ?? '-'}',
              style: const TextStyle(
                color: PosPalette.danger,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onVoid,
              icon: const Icon(Icons.block_outlined),
              label: Text(
                canVoid
                    ? '거래 취소'
                    : sale.isVoided
                    ? '취소 완료'
                    : '취소 불가',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: canVoid
                    ? PosPalette.danger
                    : PosPalette.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoidEmpty extends StatelessWidget {
  const _VoidEmpty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Text(
          '판매 내역이 없습니다.',
          style: TextStyle(color: PosPalette.textSecondary),
        ),
      ),
    );
  }
}
