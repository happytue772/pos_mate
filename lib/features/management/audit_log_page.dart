import 'package:flutter/material.dart';

import '../../data/models/audit_log.dart';
import '../../services/audit_log_service.dart';

class AuditLogPage extends StatefulWidget {
  const AuditLogPage({super.key});

  @override
  State<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends State<AuditLogPage> {
  late Future<List<AuditLog>> _logsFuture;

  String _query = '';
  String _actionFilter = 'all';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _logsFuture = AuditLogService.instance.getLogs();
  }

  String _dateTime(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');

    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
  }

  IconData _icon(AuditAction action) {
    switch (action) {
      case AuditAction.productCreate:
      case AuditAction.productUpdate:
      case AuditAction.productDelete:
        return Icons.inventory_2_outlined;
      case AuditAction.promotionCreate:
      case AuditAction.promotionUpdate:
      case AuditAction.promotionDelete:
        return Icons.local_offer_outlined;
      case AuditAction.stockIn:
      case AuditAction.stockAdjust:
      case AuditAction.stockDispose:
        return Icons.warehouse_outlined;
      case AuditAction.refund:
        return Icons.assignment_return_outlined;
      case AuditAction.cashDeposit:
      case AuditAction.cashWithdrawal:
        return Icons.account_balance_wallet_outlined;
      case AuditAction.shiftOpen:
      case AuditAction.shiftClose:
        return Icons.badge_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('감사 로그'),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: () {
              setState(_reload);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<AuditLog>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                '감사 로그를 불러오지 못했습니다.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final source = snapshot.data ?? [];
          final query = _query.trim().toLowerCase();

          final logs = source.where((log) {
            final matchesAction =
                _actionFilter == 'all' || log.action.name == _actionFilter;

            final matchesQuery =
                query.isEmpty ||
                log.actorName.toLowerCase().contains(query) ||
                log.action.label.toLowerCase().contains(query) ||
                (log.targetName ?? '').toLowerCase().contains(query) ||
                log.detail.toLowerCase().contains(query);

            return matchesAction && matchesQuery;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: '직원 / 작업 / 대상 검색',
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonFormField<String>(
                  initialValue: _actionFilter,
                  decoration: const InputDecoration(
                    labelText: '작업 종류',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('전체')),
                    ...AuditAction.values.map(
                      (action) => DropdownMenuItem(
                        value: action.name,
                        child: Text(action.label),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _actionFilter = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              Expanded(
                child: logs.isEmpty
                    ? const Center(child: Text('감사 로그가 없습니다.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ExpansionTile(
                              leading: Icon(_icon(log.action)),
                              title: Text(log.action.label),
                              subtitle: Text(
                                '${log.actorName} · ${log.actorRole}\n'
                                '${_dateTime(log.createdAt)}',
                              ),
                              children: [
                                const Divider(height: 1),
                                _InfoRow(label: '대상 종류', value: log.targetType),
                                if (log.targetName != null)
                                  _InfoRow(label: '대상', value: log.targetName!),
                                if (log.targetId != null)
                                  _InfoRow(
                                    label: '대상 ID',
                                    value: log.targetId!,
                                  ),
                                _InfoRow(label: '상세 내용', value: log.detail),
                                const SizedBox(height: 10),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 85, child: Text(label)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
