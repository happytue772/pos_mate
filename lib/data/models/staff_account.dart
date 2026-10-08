import 'app_user.dart';

class StaffAccount {
  const StaffAccount({
    required this.id,
    required this.username,
    required this.name,
    required this.password,
    required this.enabled,
    required this.createdAt,
  });

  final int id;
  final String username;
  final String name;
  final String password;
  final bool enabled;
  final DateTime createdAt;

  AppUser toUser() {
    return AppUser(
      id: id,
      username: username,
      name: name,
      role: UserRole.staff,
    );
  }

  StaffAccount copyWith({
    int? id,
    String? username,
    String? name,
    String? password,
    bool? enabled,
    DateTime? createdAt,
  }) {
    return StaffAccount(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      password: password ?? this.password,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
