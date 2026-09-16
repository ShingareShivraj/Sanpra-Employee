import 'package:flutter/material.dart';

import '../../services/login_service.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  final TextEditingController usernameController =
      TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool _loading = false;

  bool get loading => _loading;

  Future<void> sendResetLink() async {
    if (!formKey.currentState!.validate()) {
      throw Exception("Invalid Form");
    }

    _loading = true;
    notifyListeners();

    try {
      await _authService.forgotPassword(
        username: usernameController.text.trim(),
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }
}
