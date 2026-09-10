import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hideCurrentPassword = true;
  bool _hideNewPassword = true;
  bool _hideConfirmPassword = true;
  bool _isLoading = false;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;

      final currentUser = supabase.auth.currentUser;

      if (currentUser == null || currentUser.email == null) {
        throw Exception('User is not logged in');
      }

      // Step 1: Verify current password
      await supabase.auth.signInWithPassword(
        email: currentUser.email!,
        password: _currentPasswordController.text,
      );

      // Step 2: Update to new password
      await supabase.auth.updateUser(
        UserAttributes(
          password: _newPasswordController.text,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password updated successfully!',
          ),
          backgroundColor: Color(0xFF38BB62),
        ),
      );

      Navigator.pop(context);
    } on AuthException catch (error) {
      if (!mounted) return;

      String message = error.message;

      if (message.toLowerCase().contains('invalid login credentials')) {
        message = 'Current password is incorrect.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update password: $error',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Change Password',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/smartjimat_logo.png',
                    width: 180,
                    height: 130,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Change Your Password',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333632),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Enter your current password before creating a new password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF666666),
                  ),
                ),

                const SizedBox(height: 32),

                // Current Password
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _hideCurrentPassword,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _hideCurrentPassword =
                          !_hideCurrentPassword;
                        });
                      },
                      icon: Icon(
                        _hideCurrentPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // New Password
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _hideNewPassword,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    errorMaxLines: 6,
                    prefixIcon: const Icon(
                      Icons.lock_reset_outlined,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _hideNewPassword =
                          !_hideNewPassword;
                        });
                      },
                      icon: Icon(
                        _hideNewPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password requirements:\n'
                          '• At least 8 characters\n'
                          '• At least 1 uppercase letter\n'
                          '• At least 1 lowercase letter\n'
                          '• At least 1 number\n'
                          '• At least 1 special character';
                    }

                    final hasMinLength = value.length >= 8;
                    final hasUppercase =
                    RegExp(r'[A-Z]').hasMatch(value);
                    final hasLowercase =
                    RegExp(r'[a-z]').hasMatch(value);
                    final hasNumber =
                    RegExp(r'[0-9]').hasMatch(value);
                    final hasSpecialCharacter =
                    RegExp(
                      r'[!@#$%^&*(),.?":{}|<>]',
                    ).hasMatch(value);

                    if (!hasMinLength ||
                        !hasUppercase ||
                        !hasLowercase ||
                        !hasNumber ||
                        !hasSpecialCharacter) {
                      return 'Password requirements:\n'
                          '• At least 8 characters\n'
                          '• At least 1 uppercase letter\n'
                          '• At least 1 lowercase letter\n'
                          '• At least 1 number\n'
                          '• At least 1 special character';
                    }

                    if (value == _currentPasswordController.text) {
                      return 'New password must be different from current password';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // Confirm New Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _hideConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: const Icon(
                      Icons.lock_reset_outlined,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _hideConfirmPassword =
                          !_hideConfirmPassword;
                        });
                      },
                      icon: Icon(
                        _hideConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your new password';
                    }

                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 28),

                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed:
                    _isLoading ? null : _changePassword,
                    child: _isLoading
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'UPDATE PASSWORD',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}