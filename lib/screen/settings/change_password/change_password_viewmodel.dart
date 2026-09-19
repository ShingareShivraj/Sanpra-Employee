import 'package:flutter/material.dart';

class ChangePasswordViewModel extends ChangeNotifier {
  final Future<String?> Function(String currentPassword, String newPassword)?
      onChangePassword;

  ChangePasswordViewModel({this.onChangePassword});

  final formKey = GlobalKey<FormState>();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _loading = false;
  bool get loading => _loading;

  bool showCurrentPassword = false;
  bool showNewPassword = false;
  bool showConfirmPassword = false;

  String? errorMessage;
  String? successMessage;

  void toggleCurrentPasswordVisibility() {
    showCurrentPassword = !showCurrentPassword;
    notifyListeners();
  }

  void toggleNewPasswordVisibility() {
    showNewPassword = !showNewPassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    showConfirmPassword = !showConfirmPassword;
    notifyListeners();
  }

  String? validateCurrentPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your current password.';
    }
    return null;
  }

  String? validateNewPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Please enter a new password.';
    if (password.length < 8) {
      return 'Password must contain at least 8 characters.';
    }
    if (password == currentPasswordController.text) {
      return 'New password must be different from current password.';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your new password.';
    }
    if (value != newPasswordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  Future<bool> changePassword() async {
    errorMessage = null;
    successMessage = null;

    if (!formKey.currentState!.validate()) {
      errorMessage = 'Please correct the highlighted fields.';
      notifyListeners();
      return false;
    }

    if (onChangePassword == null) {
      errorMessage =
          'Password API is not connected yet. Add the change-password service.';
      notifyListeners();
      return false;
    }

    _loading = true;
    notifyListeners();

    try {
      final result = await onChangePassword!(
        currentPasswordController.text,
        newPasswordController.text,
      );

      if (result == null || result.trim().isEmpty) {
        successMessage =
            'Password changed successfully. Please log in again.';
        return true;
      }

      errorMessage = result;
      return false;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '').trim();
      if (errorMessage!.isEmpty) {
        errorMessage = 'Unable to change password. Please try again.';
      }
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
