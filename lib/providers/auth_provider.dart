import 'package:flutter/foundation.dart';

import '../data/database/local_database.dart';
import '../data/models/app_user.dart';
import '../data/models/audit_log.dart';
import '../data/models/staff_account.dart';
import '../services/audit_log_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _initialize();
  }

  static const AppUser adminUser = AppUser(
    id: 1,
    username: 'admin',
    name: '관리자',
    role: UserRole.admin,
  );

  static const String adminPassword = 'admin1234';

  final LocalDatabase _database = LocalDatabase.instance;

  final AuditLogService _audit = AuditLogService.instance;

  final List<StaffAccount> _staffAccounts = [];

  AppUser? _currentUser;
  bool _isLoading = true;
  String? _lastError;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get lastError => _lastError;

  List<StaffAccount> get staffAccounts => List.unmodifiable(_staffAccounts);

  Future<void> _initialize() async {
    try {
      _staffAccounts
        ..clear()
        ..addAll(await _database.getStaffAccounts());
    } catch (error) {
      debugPrint('직원 계정 로딩 오류: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isValidStaffUsername(String username) {
    return RegExp(r'^staff([1-9]|[1-9][0-9])$')
        .hasMatch(username.trim().toLowerCase());
  }

  Future<bool> login(String username, String password) async {
    if (_isLoading) {
      return false;
    }

    _lastError = null;

    final normalizedUsername = username.trim().toLowerCase();

    if (normalizedUsername == adminUser.username) {
      if (password == adminPassword) {
        _currentUser = adminUser;
        _audit.setCurrentUser(_currentUser);
        notifyListeners();
        return true;
      }

      _lastError = '아이디 또는 비밀번호가 올바르지 않습니다.';
      notifyListeners();
      return false;
    }

    if (!isValidStaffUsername(normalizedUsername)) {
      _lastError = '직원 아이디는 staff1 ~ staff99 형식만 사용할 수 있습니다.';
      notifyListeners();
      return false;
    }

    StaffAccount? account;

    for (final item in _staffAccounts) {
      if (item.username == normalizedUsername) {
        account = item;
        break;
      }
    }

    if (account == null || account.password != password) {
      _lastError = '아이디 또는 비밀번호가 올바르지 않습니다.';
      notifyListeners();
      return false;
    }

    if (!account.enabled) {
      _lastError = '사용이 중지된 직원 계정입니다.';
      notifyListeners();
      return false;
    }

    _currentUser = account.toUser();

    _audit.setCurrentUser(_currentUser);

    notifyListeners();

    return true;
  }

  Future<String?> registerStaff({
    required String username,
    required String name,
    required String password,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();

    final normalizedName = name.trim();

    if (!isValidStaffUsername(normalizedUsername)) {
      return '아이디는 staff1 ~ staff99 형식으로 입력해주세요.';
    }

    if (normalizedName.isEmpty) {
      return '직원 이름을 입력해주세요.';
    }

    if (password.length < 4) {
      return '비밀번호는 4자 이상 입력해주세요.';
    }

    final duplicated = _staffAccounts.any(
      (account) => account.username == normalizedUsername,
    );

    if (duplicated) {
      return '이미 사용 중인 직원 아이디입니다.';
    }

    final staffNumber = int.parse(normalizedUsername.replaceFirst('staff', ''));

    final account = StaffAccount(
      id: 100 + staffNumber,
      username: normalizedUsername,
      name: normalizedName,
      password: password,
      enabled: true,
      createdAt: DateTime.now(),
    );

    try {
      await _database.upsertStaffAccount(account);

      _staffAccounts.add(account);
      _staffAccounts.sort((a, b) => a.id.compareTo(b.id));

      await _audit.log(
        actorName: normalizedName,
        actorRole: UserRole.staff.label,
        action: AuditAction.staffRegister,
        targetType: 'STAFF',
        targetId: account.id.toString(),
        targetName: account.username,
        detail: '직원 계정 가입 · ${account.username} · $normalizedName',
      );

      notifyListeners();

      return null;
    } catch (error) {
      debugPrint('직원 계정 생성 오류: $error');

      return '직원 계정을 저장하지 못했습니다.';
    }
  }

  Future<bool> setStaffEnabled({
    required int staffId,
    required bool enabled,
  }) async {
    if (_currentUser?.isAdmin != true) {
      return false;
    }

    final index = _staffAccounts.indexWhere((account) => account.id == staffId);

    if (index == -1) {
      return false;
    }

    final before = _staffAccounts[index];

    final updated = before.copyWith(enabled: enabled);

    try {
      await _database.upsertStaffAccount(updated);

      _staffAccounts[index] = updated;

      await _audit.logCurrent(
        action: AuditAction.staffStatusChange,
        targetType: 'STAFF',
        targetId: updated.id.toString(),
        targetName: updated.username,
        detail: '${updated.name} 계정 ${enabled ? '활성화' : '비활성화'}',
      );

      notifyListeners();
      return true;
    } catch (error) {
      debugPrint('직원 상태 변경 오류: $error');

      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _lastError = null;

    _audit.setCurrentUser(null);

    notifyListeners();
  }
}
