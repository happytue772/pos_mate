enum UserRole { admin, staff }

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
  });

  final int id;
  final String username;
  final String name;
  final UserRole role;

  bool get isAdmin => role == UserRole.admin;

  String get roleLabel {
    switch (role) {
      case UserRole.admin:
        return '관리자';
      case UserRole.staff:
        return '직원';
    }
  }
}
