import 'package:flutter/material.dart';

import 'password_reset_viewmodel.dart';

const kBluePrimary = Color(0xFF1B5FE0);
const kBlueAccent = Color(0xFF4E8CFF);
const kBlueDark = Color(0xFF123FA0);
const kBgGrey = Color(0xFFF4F6FA);

class PasswordResetScreen extends StatefulWidget {
  /// The one-time key received from the Frappe password-reset link.
  final String resetKey;

  const PasswordResetScreen({
    super.key,
    required this.resetKey,
  });

  @override
  State<PasswordResetScreen> createState() =>
      _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  late final PasswordResetViewModel vm;

  @override
  void initState() {
    super.initState();
    vm = PasswordResetViewModel(
      resetKey: widget.resetKey,
    );
  }

  Future<void> _handleResetPassword() async {
    FocusScope.of(context).unfocus();

    try {
      await vm.resetPassword();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Password Updated'),
            content: const Text(
              'Your password has been changed successfully. '
              'You can now sign in with your new password.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).popUntil(
                    (route) => route.isFirst,
                  );
                },
                child: const Text('GO TO LOGIN'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst(
        'Exception: ',
        '',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vm,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: kBgGrey,
          body: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  24,
                  58,
                  24,
                  34,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kBlueDark,
                      kBluePrimary,
                      kBlueAccent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: vm.loading
                            ? null
                            : () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Reset Password',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Create a new password for your account.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    24,
                    20,
                    24,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 18,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Form(
                      key: vm.formKey,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'New Password',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: vm.passwordController,
                            obscureText: vm.obscurePassword,
                            textInputAction:
                                TextInputAction.next,
                            enabled: !vm.loading,
                            decoration: InputDecoration(
                              hintText: 'Enter new password',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                              ),
                              suffixIcon: IconButton(
                                onPressed: vm.loading
                                    ? null
                                    : vm.togglePassword,
                                icon: Icon(
                                  vm.obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons
                                          .visibility_off_outlined,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              enabledBorder:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ),
                            validator: (value) {
                              final password =
                                  value?.trim() ?? '';

                              if (password.isEmpty) {
                                return 'Please enter a new password';
                              }

                              if (password.length < 8) {
                                return 'Password must be at least 8 characters';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          const Text(
                            'Confirm Password',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller:
                                vm.confirmPasswordController,
                            obscureText:
                                vm.obscureConfirmPassword,
                            textInputAction:
                                TextInputAction.done,
                            enabled: !vm.loading,
                            onFieldSubmitted: (_) {
                              if (!vm.loading) {
                                _handleResetPassword();
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'Re-enter new password',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                              ),
                              suffixIcon: IconButton(
                                onPressed: vm.loading
                                    ? null
                                    : vm
                                        .toggleConfirmPassword,
                                icon: Icon(
                                  vm.obscureConfirmPassword
                                      ? Icons
                                          .visibility_outlined
                                      : Icons
                                          .visibility_off_outlined,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              enabledBorder:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ),
                            validator: (value) {
                              final confirm =
                                  value?.trim() ?? '';

                              if (confirm.isEmpty) {
                                return 'Please confirm your password';
                              }

                              if (confirm !=
                                  vm.passwordController.text) {
                                return 'Passwords do not match';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: vm.loading
                                  ? null
                                  : _handleResetPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    kBluePrimary,
                                foregroundColor:
                                    Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                              ),
                              child: vm.loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        valueColor:
                                            AlwaysStoppedAnimation<
                                                Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'RESET PASSWORD',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight:
                                            FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          const Center(
                            child: Text(
                              'Use a strong password that you do not use elsewhere.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
