import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/sale.dart';
import '../../providers/pos_provider.dart';
import 'receipt_page.dart';

class ReceiptSearchPage extends StatefulWidget {
  const ReceiptSearchPage({super.key});

  @override
  State<ReceiptSearchPage> createState() => _ReceiptSearchPageState();
}

class _ReceiptSearchPageState extends State<ReceiptSearchPage> {
  final TextEditingController _searchController = TextEditingController();

  String _query = '';

  PaymentMethod? _paymentMethod;

  SaleStatus? _saleStatus;

  bool _todayOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isToday(DateTime value) {
    final now = DateTime.now();

    return value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
  }

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

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();

    final query = _query.trim().toLowerCase();

    final sales = pos.sales.where((sale) {
      final matchesQuery =
          query.isEmpty ||
          sale.receiptNumber.toLowerCase().contains(query) ||
          sale.cashierName.toLowerCase().contains(query) ||
          sale.items.any(
            (item) => item.productName.toLowerCase().contains(query),
          );

      final matchesPayment =
          _paymentMethod == null || sale.paymentMethod == _paymentMethod;

      final matchesStatus = _saleStatus == null || sale.status == _saleStatus;

      final matchesDate = !_todayOnly || _isToday(sale.soldAt);

      return matchesQuery && matchesPayment && matchesStatus && matchesDate;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('영수증 검색 / 재출력')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: '영수증 번호 / 직원 / 상품명 검색',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _query = value;
                });
              },
            ),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('오늘'),
                  selected: _todayOnly,
                  onSelected: (value) {
                    setState(() {
                      _todayOnly = value;
                    });
                  },
                ),
                const SizedBox(width: 8),

                ChoiceChip(
                  label: const Text('결제 전체'),
                  selected: _paymentMethod == null,
                  onSelected: (_) {
                    setState(() {
                      _paymentMethod = null;
                    });
                  },
                ),
                const SizedBox(width: 8),

                ...PaymentMethod.values.map((method) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(method.label),
                      selected: _paymentMethod == method,
                      onSelected: (_) {
                        setState(() {
                          _paymentMethod = method;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 8),

          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('상태 전체'),
                  selected: _saleStatus == null,
                  onSelected: (_) {
                    setState(() {
                      _saleStatus = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ...SaleStatus.values.map((status) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(status.label),
                      selected: _saleStatus == status,
                      onSelected: (_) {
                        setState(() {
                          _saleStatus = status;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '검색 결과 ${sales.length}건',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          Expanded(
            child: sales.isEmpty
                ? const Center(child: Text('검색된 영수증이 없습니다.'))
                : ListView.builder(
                    itemCount: sales.length,
                    itemBuilder: (context, index) {
                      final sale = sales[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.receipt_long_outlined),
                          title: Text(sale.receiptNumber),
                          subtitle: Text(
                            '${_formatDate(sale.soldAt)}\n'
                            '${sale.cashierName} · '
                            '${sale.paymentMethod.label} · '
                            '${sale.status.label}',
                          ),
                          isThreeLine: true,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${sale.netAmount}원',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ReceiptPage(
                                        sale: sale,
                                        isReprint: true,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  '재출력',
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReceiptPage(sale: sale),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
