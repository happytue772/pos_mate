import 'package:flutter/material.dart';

import '../data/models/app_user.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  bool login({required String username, required String password}) {
    if (username == 'admin' && password == 'admin1234') {
      _currentUser = const AppUser(
        id: 1,
        username: 'admin',
        name: '관리자',
        role: UserRole.admin,
      );

      notifyListeners();
      return true;
    }

    if (username == 'staff' && password == 'staff1234') {
      _currentUser = const AppUser(
        id: 2,
        username: 'staff',
        name: '직원',
        role: UserRole.staff,
      );

      notifyListeners();
      return true;
    }

    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
