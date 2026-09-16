import 'package:flutter/material.dart';

import '../../services/password_reset_service.dart';

class PasswordResetViewModel extends ChangeNotifier {
  final PasswordResetService _service = PasswordResetService();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final String resetKey;

  bool _loading = false;
  bool get loading => _loading;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  bool _obscureConfirmPassword = true;
  bool get obscureConfirmPassword => _obscureConfirmPassword;

  PasswordResetViewModel({
    required this.resetKey,
  });

  void togglePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleConfirmPassword() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  Future<void> resetPassword() async {
    if (!formKey.currentState!.validate()) {
      throw Exception("Invalid Form");
    }

    _loading = true;
    notifyListeners();

    try {
      await _service.resetPassword(
        key: resetKey,
        newPassword: passwordController.text,
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
