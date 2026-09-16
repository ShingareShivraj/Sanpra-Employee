import 'package:flutter/material.dart';

import '../../model/login_response.dart';
import '../../services/login_service.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  final TextEditingController usernameController =
  TextEditingController();

  final TextEditingController passwordController =
  TextEditingController();

  final GlobalKey<FormState> formKey =
  GlobalKey<FormState>();

  bool _loading = false;

  bool get loading => _loading;

  bool _obscurePassword = true;

  bool get obscurePassword =>
      _obscurePassword;

  void togglePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void fillDemoCredentials() {
    usernameController.text = "demo@sanpra.com";
    passwordController.text = "Demo@123";

    notifyListeners();
  }

  Future<LoginResponseModel> login() async {
    if (!formKey.currentState!.validate()) {
      throw Exception("Invalid Form");
    }

    _loading = true;
    notifyListeners();

    try {
      final LoginResponseModel response =
      await _authService.login(
        username: usernameController.text.trim(),
        password: passwordController.text,
      );

      return response;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}