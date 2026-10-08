import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../inventory/expiration_management_page.dart';
import '../inventory/stock_adjustment_page.dart';
import '../inventory/stock_history_page.dart';
import '../sales/receipt_search_page.dart';
import '../sales/refund_history_page.dart';
import '../sales/refund_page.dart';
import '../sales/sales_analytics_page.dart';
import '../sales/sales_history_page.dart';
import '../shift/settlement_history_page.dart';
import 'audit_log_page.dart';
import 'product_manage_page.dart';
import 'promotion_manage_page.dart';
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
          const _SectionHeader(title: '매장 운영'),
          ListTile(
            leading: const Icon(Icons.summarize_outlined),
            title: const Text('근무 / 정산 이력'),
            subtitle: const Text('직원별 근무 및 마감 정산'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettlementHistoryPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.security_outlined),
            title: const Text('감사 로그'),
            subtitle: const Text('상품·재고·환불·현금·근무 작업 이력'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AuditLogPage()),
              );
            },
          ),
          const Divider(),
          const _SectionHeader(title: '상품 / 재고'),
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
            leading: const Icon(Icons.local_offer_outlined),
            title: const Text('행사 관리'),
            subtitle: const Text('1+1 · 2+1 · 할인 · 특가'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PromotionManagePage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.input_outlined),
            title: const Text('입고 관리'),
            subtitle: const Text('상품 재고 입고 처리'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StockInPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.event_busy_outlined),
            title: const Text('유통기한 / 폐기 관리'),
            subtitle: const Text('임박·만료 상품과 폐기 처리'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ExpirationManagementPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.tune_outlined),
            title: const Text('재고 조정'),
            subtitle: const Text('실사 / 파손 / 분실 등 재고 조정'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StockAdjustmentPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('재고 이력'),
            subtitle: const Text('입고 / 판매 / 환불 / 폐기 / 조정'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StockHistoryPage()),
              );
            },
          ),
          const Divider(),
          const _SectionHeader(title: '판매 / 영수증'),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('판매 내역'),
            subtitle: const Text('전체 판매 기록 확인'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SalesHistoryPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.manage_search),
            title: const Text('영수증 검색 / 재출력'),
            subtitle: const Text('번호·직원·상품명으로 검색'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReceiptSearchPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.undo_outlined),
            title: const Text('환불 관리'),
            subtitle: const Text('전체 / 부분 환불 처리'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RefundPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history_outlined),
            title: const Text('환불 이력'),
            subtitle: const Text('환불 번호 · 사유 · 처리직원 · 환불금액 확인'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RefundHistoryPage()),
              );
            },
          ),
          const Divider(),
          const _SectionHeader(title: '분석'),
          ListTile(
            leading: const Icon(Icons.analytics_outlined),
            title: const Text('매출 분석'),
            subtitle: const Text('매출·결제·카테고리·상품·시간대 분석'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SalesAnalyticsPage()),
              );
            },
          ),
          const Divider(),
          const _SectionHeader(title: '직원'),
          const ListTile(
            leading: Icon(Icons.manage_accounts_outlined),
            title: Text('직원 관리'),
            subtitle: Text('서버 인증 단계에서 구현 예정'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }
}
