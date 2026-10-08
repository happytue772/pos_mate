import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/pos_palette.dart';
import '../../providers/auth_provider.dart';

class StaffManagePage extends StatelessWidget {
  const StaffManagePage({super.key});

  String _date(DateTime value) {
    String two(int number) {
      return number.toString().padLeft(2, '0');
    }

    return '${value.year}-${two(value.month)}-${two(value.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: PosPalette.background,
      appBar: AppBar(
        backgroundColor: PosPalette.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          '직원 관리',
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PosPalette.softBlue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '관리자 계정은 admin 한 개로 고정됩니다. '
              '직원은 로그인 화면에서 staff1 ~ staff99 아이디로 가입할 수 있고, '
              '여기서는 직원 계정의 사용 여부를 관리합니다.',
              style: TextStyle(color: PosPalette.textSecondary, height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '등록 직원',
                  style: TextStyle(
                    color: PosPalette.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${auth.staffAccounts.length}명',
                style: const TextStyle(
                  color: PosPalette.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (auth.staffAccounts.isEmpty)
            const _EmptyStaff()
          else
            ...auth.staffAccounts.map(
              (account) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: PosPalette.surface,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: account.enabled
                              ? PosPalette.softGreen
                              : PosPalette.softRed,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.badge_outlined,
                          color: account.enabled
                              ? PosPalette.success
                              : PosPalette.danger,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.name,
                              style: const TextStyle(
                                color: PosPalette.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${account.username} · 가입 ${_date(account.createdAt)}',
                              style: const TextStyle(
                                color: PosPalette.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: account.enabled,
                        onChanged: (value) {
                          auth.setStaffEnabled(
                            staffId: account.id,
                            enabled: value,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyStaff extends StatelessWidget {
  const _EmptyStaff();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.manage_accounts_outlined,
              size: 48,
              color: PosPalette.textTertiary,
            ),
            SizedBox(height: 12),
            Text(
              '등록된 직원이 없습니다.',
              style: TextStyle(color: PosPalette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
