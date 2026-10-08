import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/pos_palette.dart';
import '../../data/models/price_change_history.dart';
import '../../providers/pos_provider.dart';

class PriceChangeHistoryPage extends StatefulWidget {
  const PriceChangeHistoryPage({super.key});

  @override
  State<PriceChangeHistoryPage> createState() => _PriceChangeHistoryPageState();
}

class _PriceChangeHistoryPageState extends State<PriceChangeHistoryPage> {
  String _query = '';

  String _money(int value) {
    final negative = value < 0;
    final raw = value.abs().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < raw.length; i++) {
      final remain = raw.length - i;

      buffer.write(raw[i]);

      if (remain > 1 && remain % 3 == 1) {
        buffer.write(',');
      }
    }

    return '${negative ? '-' : ''}${buffer.toString()}원';
  }

  String _dateTime(DateTime value) {
    String two(int number) {
      return number.toString().padLeft(2, '0');
    }

    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();

    final keyword = _query.trim().toLowerCase();

    final rows = pos.priceChangeHistory
        .where(
          (item) =>
              keyword.isEmpty ||
              item.productName.toLowerCase().contains(keyword) ||
              item.changedBy.toLowerCase().contains(keyword),
        )
        .toList();

    return Scaffold(
      backgroundColor: PosPalette.background,
      appBar: AppBar(
        backgroundColor: PosPalette.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          '가격 변경 이력',
          style: TextStyle(
            color: PosPalette.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: '상품명 · 변경 직원 검색',
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  '변경 기록',
                  style: TextStyle(
                    color: PosPalette.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${rows.length}건',
                style: const TextStyle(
                  color: PosPalette.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            const _EmptyState()
          else
            ...rows.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PriceHistoryCard(
                  item: item,
                  money: _money,
                  dateTime: _dateTime,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PriceHistoryCard extends StatelessWidget {
  const _PriceHistoryCard({
    required this.item,
    required this.money,
    required this.dateTime,
  });

  final PriceChangeHistory item;
  final String Function(int value) money;
  final String Function(DateTime value) dateTime;

  @override
  Widget build(BuildContext context) {
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: PosPalette.softBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.price_change_outlined,
                  color: PosPalette.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(
                        color: PosPalette.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.changedBy} · ${dateTime(item.changedAt)}',
                      style: const TextStyle(
                        color: PosPalette.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (item.salePriceChanged)
            _ChangeRow(
              label: '판매가',
              before: money(item.beforePrice),
              after: money(item.afterPrice),
            ),
          if (item.costPriceChanged)
            _ChangeRow(
              label: '원가',
              before: money(item.beforeCostPrice),
              after: money(item.afterCostPrice),
            ),
        ],
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({
    required this.label,
    required this.before,
    required this.after,
  });

  final String label;
  final String before;
  final String after;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            child: Text(
              label,
              style: const TextStyle(
                color: PosPalette.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            before,
            style: const TextStyle(
              color: PosPalette.textTertiary,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.arrow_forward,
              size: 16,
              color: PosPalette.textTertiary,
            ),
          ),
          Text(
            after,
            style: const TextStyle(
              color: PosPalette.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.price_change_outlined,
              size: 48,
              color: PosPalette.textTertiary,
            ),
            SizedBox(height: 12),
            Text(
              '가격 변경 이력이 없습니다.',
              style: TextStyle(color: PosPalette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
