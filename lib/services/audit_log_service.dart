import 'package:flutter/foundation.dart';

import '../data/database/local_database.dart';
import '../data/models/app_user.dart';
import '../data/models/audit_log.dart';

class AuditLogService {
  AuditLogService._();

  static final AuditLogService instance = AuditLogService._();

  final LocalDatabase _database = LocalDatabase.instance;

  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;

  void setCurrentUser(AppUser? user) {
    _currentUser = user;
  }

  Future<void> logCurrent({
    required AuditAction action,
    required String targetType,
    required String detail,
    String? targetId,
    String? targetName,
  }) async {
    final user = _currentUser;

    await log(
      actorName: user?.name ?? 'SYSTEM',
      actorRole: user?.roleLabel ?? 'SYSTEM',
      action: action,
      targetType: targetType,
      detail: detail,
      targetId: targetId,
      targetName: targetName,
    );
  }

  Future<void> log({
    required String actorName,
    required String actorRole,
    required AuditAction action,
    required String targetType,
    required String detail,
    String? targetId,
    String? targetName,
  }) async {
    try {
      await _database.insertAuditLog(
        AuditLog(
          actorName: actorName,
          actorRole: actorRole,
          action: action,
          targetType: targetType,
          targetId: targetId,
          targetName: targetName,
          detail: detail,
          createdAt: DateTime.now(),
        ),
      );
    } catch (error) {
      debugPrint('Audit Log 저장 실패: $error');
    }
  }

  Future<List<AuditLog>> getLogs() {
    return _database.getAuditLogs();
  }
}
