import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../inventory/stock_history_page.dart';
import '../sales/refund_page.dart';
import '../sales/sales_history_page.dart';
import 'product_manage_page.dart';
import 'stock_in_page.dart';

class ManagementPage extends StatelessWidget {
  const ManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.currentUser?.isAdmin != true) {
      return Scaffold(
        appBar: AppBar(title: const Text('관리')),
        body: const Center(child: Text('관리자만 접근할 수 있습니다.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('관리')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('상품 관리'),
            subtitle: const Text('상품 등록 / 수정 / 삭제'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductManagePage()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.input_outlined),
            title: const Text('입고 관리'),
            subtitle: const Text('상품 재고를 추가합니다.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StockInPage()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('판매 내역'),
            subtitle: const Text('판매 및 영수증 기록을 확인합니다.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SalesHistoryPage()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.undo_outlined),
            title: const Text('환불 관리'),
            subtitle: const Text('완료된 판매를 환불합니다.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RefundPage()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('재고 이력'),
            subtitle: const Text('판매 / 입고 / 환불 기록을 확인합니다.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StockHistoryPage()),
              );
            },
          ),

          const ListTile(
            leading: Icon(Icons.manage_accounts_outlined),
            title: Text('직원 관리'),
            subtitle: Text('Spring Boot 인증 단계에서 구현 예정'),
          ),
        ],
      ),
    );
  }
}
