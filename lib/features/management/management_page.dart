import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/pos_palette.dart';
import '../../providers/auth_provider.dart';
import '../inventory/expiration_management_page.dart';
import '../inventory/stock_adjustment_page.dart';
import '../inventory/stock_history_page.dart';
import '../sales/receipt_search_page.dart';
import '../sales/refund_history_page.dart';
import '../sales/refund_page.dart';
import '../sales/sales_analytics_page.dart';
import '../sales/sales_history_page.dart';
import '../sales/void_sale_page.dart';
import '../shift/settlement_history_page.dart';
import 'audit_log_page.dart';
import 'price_change_history_page.dart';
import 'product_manage_page.dart';
import 'promotion_manage_page.dart';
import 'staff_manage_page.dart';
import 'stock_in_page.dart';

class ManagementPage extends StatelessWidget {
  const ManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.currentUser?.isAdmin != true) {
      return Scaffold(
        backgroundColor: PosPalette.background,
        appBar: AppBar(
          backgroundColor: PosPalette.background,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            '관리',
            style: TextStyle(
              color: PosPalette.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: const Center(
          child: Text(
            '관리자만 접근할 수 있습니다.',
            style: TextStyle(
              color: PosPalette.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: PosPalette.background,
      appBar: AppBar(
        backgroundColor: PosPalette.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          '관리',
          style: TextStyle(
            color: PosPalette.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          _ManagementHeader(userName: auth.currentUser?.name ?? '관리자'),
          const SizedBox(height: 22),

          const _SectionTitle(title: '매장 운영', subtitle: '근무 상태와 관리 기록을 확인해요.'),
          const SizedBox(height: 10),
          _MenuCard(
            children: [
              _ManagementMenuItem(
                icon: Icons.summarize_outlined,
                iconBackground: PosPalette.softBlue,
                iconColor: PosPalette.primary,
                title: '근무 / 정산 이력',
                subtitle: '직원별 근무 및 마감 정산',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettlementHistoryPage(),
                    ),
                  );
                },
              ),
              _ManagementMenuItem(
                icon: Icons.security_outlined,
                iconBackground: PosPalette.softGreen,
                iconColor: PosPalette.success,
                title: '감사 로그',
                subtitle: '상품·재고·환불·현금·근무 작업 이력',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuditLogPage()),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 22),

          const _SectionTitle(title: '상품 / 재고', subtitle: '상품과 재고 상태를 관리해요.'),
          const SizedBox(height: 10),
          _MenuCard(
            children: [
              _ManagementMenuItem(
                icon: Icons.inventory_2_outlined,
                iconBackground: PosPalette.softBlue,
                iconColor: PosPalette.primary,
                title: '상품 관리',
                subtitle: '상품 등록 / 수정 / 삭제',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProductManagePage(),
                    ),
                  );
                },
              ),
              _ManagementMenuItem(
                icon: Icons.price_change_outlined,
                iconBackground: PosPalette.softGreen,
                iconColor: PosPalette.success,
                title: '가격 변경 이력',
                subtitle: '판매가·원가 변경 전후와 변경 직원',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PriceChangeHistoryPage(),
                    ),
                  );
                },
              ),
              _ManagementMenuItem(
                icon: Icons.local_offer_outlined,
                iconBackground: PosPalette.softOrange,
                iconColor: PosPalette.warning,
                title: '행사 관리',
                subtitle: '1+1 · 2+1 · 할인 · 특가',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PromotionManagePage(),
                    ),
                  );
                },
              ),
              _ManagementMenuItem(
                icon: Icons.input_outlined,
                iconBackground: PosPalette.softGreen,
                iconColor: PosPalette.success,
                title: '입고 관리',
                subtitle: '상품 재고 입고 처리',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StockInPage()),
                  );
                },
              ),
              _ManagementMenuItem(
                icon: Icons.event_busy_outlined,
                iconBackground: PosPalette.softRed,
                iconColor: PosPalette.danger,
                title: '유통기한 / 폐기 관리',
                subtitle: '임박·만료 상품과 폐기 처리',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ExpirationManagementPage(),
                    ),
                  );
                },
              ),
              _ManagementMenuItem(
                icon: Icons.tune_outlined,
                iconBackground: PosPalette.softOrange,
                iconColor: PosPalette.warning,
                title: '재고 조정',
                subtitle: '실사 / 파손 / 분실 등 재고 조정',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StockAdjustmentPage(),
                    ),
                  );
                },
              ),
              _ManagementMenuItem(
                icon: Icons.history,
                iconBackground: PosPalette.softBlue,
                iconColor: PosPalette.primary,
                title: '재고 이력',
                subtitle: '입고 / 판매 / 환불 / 폐기 / 조정',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StockHistoryPage()),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 22),

          const _SectionTitle(
            title: '판매 / 영수증',
            subtitle: '판매 기록과 환불 업무를 확인해요.',
          ),
          const SizedBox(height: 10),
          _MenuCard(
            children: [
              _ManagementMenuItem(
                icon: Icons.receipt_long_outlined,
                iconBackground: PosPalette.softBlue,
                iconColor: PosPalette.primary,
                title: '판매 내역',
                subtitle: '전체 판매 기록 확인',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SalesHistoryPage()),
                  );
                },
              ),
              _ManagementMenuItem(
                icon: Icons.block_outlined,
                iconBackground: PosPalette.softRed,
                iconColor: PosPalette.danger,
                title: '거래 취소',
                subtitle: '현재 근무의 미환불 거래 취소 / 재고 복구',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VoidSalePage()),
                  );
                },
              ),
              _ManagementMenuItem(
                icon: Icons.manage_search,
                iconBackground: PosPalette.softGreen,
                iconColor: PosPalette.success,
                title: '영수증 검색 / 재출력',
                subtitle: '번호·직원·상품명으로 검색',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReceiptSearchPage(),
                    ),
                  );
                },
              ),
              _ManagementMenuItem(
                icon: Icons.undo_outlined,
                iconBackground: PosPalette.softRed,
                iconColor: PosPalette.danger,
                title: '환불 관리',
                subtitle: '전체 / 부분 환불 처리',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RefundPage()),
                  );
                },
              ),
              _ManagementMenuItem(
                icon: Icons.history_outlined,
                iconBackground: PosPalette.softOrange,
                iconColor: PosPalette.warning,
                title: '환불 이력',
                subtitle: '환불 번호 · 사유 · 처리직원 · 환불금액',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RefundHistoryPage(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 22),

          const _SectionTitle(title: '분석', subtitle: '매출 흐름과 운영 지표를 확인해요.'),
          const SizedBox(height: 10),
          _MenuCard(
            children: [
              _ManagementMenuItem(
                icon: Icons.analytics_outlined,
                iconBackground: PosPalette.softBlue,
                iconColor: PosPalette.primary,
                title: '매출 분석',
                subtitle: '기간·결제·카테고리·상품별 분석',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SalesAnalyticsPage(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 22),

          const _SectionTitle(
            title: '직원',
            subtitle: 'staff1 ~ staff99 직원 계정을 관리해요.',
          ),
          const SizedBox(height: 10),
          _MenuCard(
            children: [
              _ManagementMenuItem(
                icon: Icons.manage_accounts_outlined,
                iconBackground: PosPalette.softGreen,
                iconColor: PosPalette.success,
                title: '직원 관리',
                subtitle: '등록 직원 확인 / 계정 활성·비활성',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StaffManagePage()),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _ManagementHeader extends StatelessWidget {
  const _ManagementHeader({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PosPalette.textPrimary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.admin_panel_settings_outlined,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$userName님,',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '매장 관리 센터',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  '상품부터 판매·정산까지 한곳에서 관리하세요.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: PosPalette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: PosPalette.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.children});

  final List<_ManagementMenuItem> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PosPalette.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 72),
                child: Container(height: 1, color: PosPalette.background),
              ),
          ],
        ],
      ),
    );
  }
}

class _ManagementMenuItem extends StatelessWidget {
  const _ManagementMenuItem({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: PosPalette.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: PosPalette.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: PosPalette.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
