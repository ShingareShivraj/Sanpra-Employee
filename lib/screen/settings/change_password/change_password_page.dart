import 'package:flutter/material.dart';
import 'change_password_viewmodel.dart';

const kBluePrimary = Color(0xFF1B5FE0);
const kBgGrey = Color(0xFFF4F6FA);

class ChangePasswordScreen extends StatefulWidget {
  final Future<String?> Function(String currentPassword, String newPassword)?
      onChangePassword;

  const ChangePasswordScreen({
    super.key,
    this.onChangePassword,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  late final ChangePasswordViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ChangePasswordViewModel(
      onChangePassword: widget.onChangePassword,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final success = await _viewModel.changePassword();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (_viewModel.successMessage ?? 'Password changed successfully.')
              : (_viewModel.errorMessage ??
                  'Unable to change password. Please try again.'),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
      ),
    );

    if (success) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) => Scaffold(
        backgroundColor: kBgGrey,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          title: const Text(
            'Change Password',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _viewModel.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 24),
                  _passwordField(
                    'Current Password',
                    'Enter your current password',
                    _viewModel.currentPasswordController,
                    !_viewModel.showCurrentPassword,
                    _viewModel.toggleCurrentPasswordVisibility,
                    _viewModel.validateCurrentPassword,
                    TextInputAction.next,
                  ),
                  const SizedBox(height: 18),
                  _passwordField(
                    'New Password',
                    'Enter your new password',
                    _viewModel.newPasswordController,
                    !_viewModel.showNewPassword,
                    _viewModel.toggleNewPasswordVisibility,
                    _viewModel.validateNewPassword,
                    TextInputAction.next,
                  ),
                  const SizedBox(height: 18),
                  _passwordField(
                    'Confirm New Password',
                    'Re-enter your new password',
                    _viewModel.confirmPasswordController,
                    !_viewModel.showConfirmPassword,
                    _viewModel.toggleConfirmPasswordVisibility,
                    _viewModel.validateConfirmPassword,
                    TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 14),
                  _requirements(),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _viewModel.loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBluePrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _viewModel.loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Change Password',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: kBluePrimary, size: 30),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Enter your current password and choose a new password for your account.',
                style: TextStyle(fontSize: 13, height: 1.45, color: Colors.black54),
              ),
            ),
          ],
        ),
      );

  Widget _passwordField(
    String label,
    String hint,
    TextEditingController controller,
    bool obscureText,
    VoidCallback toggle,
    String? Function(String?) validator,
    TextInputAction action, {
    void Function(String)? onSubmitted,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            validator: validator,
            textInputAction: action,
            onFieldSubmitted: onSubmitted,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.lock_outline_rounded,
                  color: Colors.black45, size: 21),
              suffixIcon: IconButton(
                onPressed: toggle,
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.black45,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: kBluePrimary, width: 1.5),
              ),
            ),
          ),
        ],
      );

  Widget _requirements() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kBluePrimary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBluePrimary.withValues(alpha: 0.12)),
        ),
        child: const Text(
          'Use at least 8 characters. Avoid using a password that is easy to guess.',
          style: TextStyle(fontSize: 12.5, height: 1.4, color: Colors.black54),
        ),
      );
}
