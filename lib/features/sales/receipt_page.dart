import 'package:flutter/material.dart';

import '../../data/models/promotion.dart';
import '../../data/models/sale.dart';
import '../../data/models/sale_item.dart';

class ReceiptPage extends StatelessWidget {
  const ReceiptPage({super.key, required this.sale, this.isReprint = false});

  final Sale sale;

  final bool isReprint;

  String _formatDate(DateTime value) {
    String two(int number) {
      return number.toString().padLeft(2, '0');
    }

    return '${value.year}-'
        '${two(value.month)}-'
        '${two(value.day)} '
        '${two(value.hour)}:'
        '${two(value.minute)}';
  }

  String? _promotionText(SaleItem item) {
    final type = item.promotionType;

    if (type == null) {
      return null;
    }

    switch (type) {
      case PromotionType.onePlusOne:
        return '1+1';

      case PromotionType.twoPlusOne:
        return '2+1';

      case PromotionType.percentDiscount:
        return '${item.promotionPercent ?? 0}% 할인';

      case PromotionType.specialPrice:
        return '${item.promotionSpecialPrice ?? item.unitPrice}원 특가';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isReprint ? '영수증 재출력' : '영수증')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isReprint)
            const Card(
              child: ListTile(
                leading: Icon(Icons.print_outlined),
                title: Text('재출력 미리보기'),
                subtitle: Text(
                  '현재 단계에서는 실제 프린터 대신 '
                  '영수증 재출력 화면을 제공합니다.',
                ),
              ),
            ),

          const SizedBox(height: 8),

          Center(
            child: Text(
              'POS Mate',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),

          const Divider(height: 32),

          _row('영수증 번호', sale.receiptNumber),

          _row('결제 일시', _formatDate(sale.soldAt)),

          _row('직원', sale.cashierName),

          _row('결제 방법', sale.paymentMethod.label),

          _row('상태', sale.status.label),

          const Divider(height: 32),

          ...sale.items.map((item) {
            final promotion = _promotionText(item);

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.productName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text('${item.subtotal}원'),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '${item.unitPrice}원 × '
                    '${item.quantity}개',
                  ),

                  if (promotion != null) Text('행사: $promotion'),

                  if (item.discountAmount > 0)
                    Text(
                      '할인: '
                      '${item.discountAmount}원',
                    ),

                  if (item.refundedQuantity > 0)
                    Text(
                      '환불 수량: '
                      '${item.refundedQuantity}개',
                    ),
                ],
              ),
            );
          }),

          const Divider(height: 32),

          _moneyRow('결제 금액', sale.totalAmount),

          if (sale.refundedAmount > 0) _moneyRow('환불 금액', -sale.refundedAmount),

          _moneyRow('현재 순매출', sale.netAmount, bold: true),

          if (sale.paymentMethod == PaymentMethod.cash) ...[
            const Divider(height: 32),

            _moneyRow('받은 금액', sale.receivedAmount ?? 0),

            _moneyRow('거스름돈', sale.changeAmount ?? 0),
          ],

          const SizedBox(height: 30),

          FilledButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value),
        ],
      ),
    );
  }

  Widget _moneyRow(String label, int value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            '$value원',
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
