import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_screen.dart';

class SellerRegisterScreen extends StatefulWidget {
  const SellerRegisterScreen({super.key});

  @override
  State<SellerRegisterScreen> createState() =>
      _SellerRegisterScreenState();
}

class _SellerRegisterScreenState
    extends State<SellerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _premiseCodeController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isRegistering = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    _nameController.text =
        prefs.getString('seller_name') ?? '';

    _emailController.text =
        prefs.getString('seller_email') ?? '';

    _phoneController.text =
        prefs.getString('seller_phone') ?? '';

    _premiseCodeController.text =
        prefs.get('seller_premise_code')?.toString() ?? '';

    _shopNameController.text =
        prefs.getString('seller_shop_name') ?? '';

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'seller_name',
      _nameController.text,
    );

    await prefs.setString(
      'seller_email',
      _emailController.text,
    );

    await prefs.setString(
      'seller_phone',
      _phoneController.text,
    );

    await prefs.setString(
      'seller_premise_code',
      _premiseCodeController.text,
    );

    await prefs.setString(
      'seller_shop_name',
      _shopNameController.text,
    );
  }

  Future<Map<String, dynamic>?> _validatePremise() async {
    final premiseCode =
    int.tryParse(_premiseCodeController.text.trim());

    final shopName =
    _shopNameController.text.trim();

    if (premiseCode == null || shopName.isEmpty) {
      return null;
    }

    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('lookup_premise')
        .select(
      'premise_code, premise, address, premise_type, state, district',
    )
        .eq('premise_code', premiseCode)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    final databaseShopName =
        response['premise']?.toString().trim() ?? '';

    if (databaseShopName.toLowerCase() !=
        shopName.toLowerCase()) {
      return null;
    }

    return Map<String, dynamic>.from(response);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      final premise = await _validatePremise();

      if (premise == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Premise code and shop name do not match our database.',
            ),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      final supabase = Supabase.instance.client;

      final premiseCode =
      premise['premise_code'] as int;

      final authResponse =
      await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        emailRedirectTo:
        'com.example.assignment://login-callback/',
        data: {
          'full_name':
          _nameController.text.trim(),
          'phone':
          _phoneController.text.trim(),
          'role': 'seller',
          'premise_code': premiseCode,
        },
      );

      final user = authResponse.user;

      if (user == null) {
        throw Exception(
          'Unable to create account',
        );
      }

      // SessionService creates a missing profile after authentication, using
      // the signup metadata. Unconfirmed users may not have a session yet.

      await _clearDraft();

      if (!mounted) return;

      // An immediate session is handled by AuthGate; otherwise show login.
      if (authResponse.session != null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Seller account created successfully. Check your email to confirm your account, then log in.',
          ),
          backgroundColor: Color(0xFF38BB62),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
            (route) => route.isFirst,
      );
    } on AuthException catch (error) {
      if (!mounted) return;

      String message = error.message;

      if (message
          .toLowerCase()
          .contains('security purposes')) {
        message =
        'Please wait a moment before trying again.';
      } else if (message
          .toLowerCase()
          .contains('already registered')) {
        message =
        'This email is already registered.';
      } else if (message
          .toLowerCase()
          .contains('invalid email')) {
        message =
        'Please enter a valid email address.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } on PostgrestException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Database error: ${error.message}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (error) {
      debugPrint(
        'SELLER REGISTER ERROR: $error',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registration failed. Please try again.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('seller_name');
    await prefs.remove('seller_email');
    await prefs.remove('seller_phone');
    await prefs.remove('seller_premise_code');
    await prefs.remove('seller_shop_name');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _premiseCodeController.dispose();
    _shopNameController.dispose();
    _passwordController.dispose();
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
          'Seller Registration',
          style: TextStyle(
            color: Color(0xFF333632),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape =
                constraints.maxWidth >
                    constraints.maxHeight;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal:
                isLandscape ? 100 : 28,
                vertical: 30,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints:
                  const BoxConstraints(
                    maxWidth: 500,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .stretch,
                      children: [
                        const Icon(
                          Icons.storefront_outlined,
                          size: 70,
                          color: Color(0xFF38BB62),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'Create Seller Account',
                          textAlign:
                          TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight:
                            FontWeight.bold,
                            color:
                            Color(0xFF333632),
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        const Text(
                          'Register your shop to manage products and prices.',
                          textAlign:
                          TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color:
                            Colors.grey,
                          ),
                        ),
                        const SizedBox(
                          height: 30,
                        ),
                        TextFormField(
                          controller:
                          _nameController,
                          onChanged:
                              (_) => _saveDraft(),
                          textInputAction:
                          TextInputAction.next,
                          decoration:
                          InputDecoration(
                            labelText:
                            'Full Name',
                            prefixIcon:
                            const Icon(
                              Icons
                                  .person_outline,
                            ),
                            filled: true,
                            fillColor:
                            const Color(
                              0xFFF7F7F7,
                            ),
                            border:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                12,
                              ),
                            ),
                          ),
                          validator:
                              (value) {
                            if (value == null ||
                                value
                                    .trim()
                                    .isEmpty) {
                              return 'Please enter your full name';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        TextFormField(
                          controller:
                          _emailController,
                          onChanged:
                              (_) => _saveDraft(),
                          keyboardType:
                          TextInputType
                              .emailAddress,
                          textInputAction:
                          TextInputAction.next,
                          decoration:
                          InputDecoration(
                            labelText: 'Email',
                            prefixIcon:
                            const Icon(
                              Icons
                                  .email_outlined,
                            ),
                            filled: true,
                            fillColor:
                            const Color(
                              0xFFF7F7F7,
                            ),
                            border:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                12,
                              ),
                            ),
                          ),
                          validator:
                              (value) {
                            if (value == null ||
                                value
                                    .trim()
                                    .isEmpty) {
                              return 'Please enter your email';
                            }

                            final email =
                            value.trim();

                            final emailRegex =
                            RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            );

                            if (!emailRegex
                                .hasMatch(email)) {
                              return 'Please enter a valid email';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        TextFormField(
                          controller:
                          _phoneController,
                          onChanged:
                              (_) => _saveDraft(),
                          keyboardType:
                          TextInputType.phone,
                          textInputAction:
                          TextInputAction.next,
                          inputFormatters: [
                            FilteringTextInputFormatter
                                .digitsOnly,
                            LengthLimitingTextInputFormatter(
                              11,
                            ),
                          ],
                          decoration:
                          InputDecoration(
                            labelText:
                            'Phone Number',
                            hintText:
                            'Example: 0123456789',
                            prefixIcon:
                            const Icon(
                              Icons
                                  .phone_outlined,
                            ),
                            filled: true,
                            fillColor:
                            const Color(
                              0xFFF7F7F7,
                            ),
                            border:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                12,
                              ),
                            ),
                          ),
                          validator:
                              (value) {
                            if (value == null ||
                                value
                                    .trim()
                                    .isEmpty) {
                              return 'Please enter your phone number';
                            }

                            final phone =
                            value.trim();

                            final phoneRegex =
                            RegExp(
                              r'^01[0-9]{8,9}$',
                            );

                            if (!phoneRegex
                                .hasMatch(phone)) {
                              return 'Please enter a valid Malaysian phone number';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        TextFormField(
                          controller:
                          _premiseCodeController,
                          onChanged:
                              (_) => _saveDraft(),
                          keyboardType:
                          TextInputType.number,
                          textInputAction:
                          TextInputAction.next,
                          inputFormatters: [
                            FilteringTextInputFormatter
                                .digitsOnly,
                          ],
                          decoration:
                          InputDecoration(
                            labelText:
                            'Premise Code',
                            hintText:
                            'Enter registered premise code',
                            prefixIcon:
                            const Icon(
                              Icons
                                  .pin_outlined,
                            ),
                            filled: true,
                            fillColor:
                            const Color(
                              0xFFF7F7F7,
                            ),
                            border:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                12,
                              ),
                            ),
                          ),
                          validator:
                              (value) {
                            if (value == null ||
                                value
                                    .trim()
                                    .isEmpty) {
                              return 'Please enter your premise code';
                            }

                            if (int.tryParse(
                              value.trim(),
                            ) ==
                                null) {
                              return 'Premise code must contain numbers only';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        TextFormField(
                          controller:
                          _shopNameController,
                          onChanged:
                              (_) => _saveDraft(),
                          textInputAction:
                          TextInputAction.next,
                          decoration:
                          InputDecoration(
                            labelText:
                            'Shop Name',
                            hintText:
                            'Enter shop name exactly as registered',
                            prefixIcon:
                            const Icon(
                              Icons
                                  .store_outlined,
                            ),
                            filled: true,
                            fillColor:
                            const Color(
                              0xFFF7F7F7,
                            ),
                            border:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                12,
                              ),
                            ),
                          ),
                          validator:
                              (value) {
                            if (value == null ||
                                value
                                    .trim()
                                    .isEmpty) {
                              return 'Please enter your shop name';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        TextFormField(
                          controller:
                          _passwordController,
                          obscureText:
                          _hidePassword,
                          textInputAction:
                          TextInputAction.next,
                          decoration:
                          InputDecoration(
                            labelText:
                            'Password',
                            errorMaxLines: 6,
                            prefixIcon:
                            const Icon(
                              Icons
                                  .lock_outline,
                            ),
                            suffixIcon:
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _hidePassword =
                                  !_hidePassword;
                                });
                              },
                              icon: Icon(
                                _hidePassword
                                    ? Icons
                                    .visibility_outlined
                                    : Icons
                                    .visibility_off_outlined,
                              ),
                            ),
                            filled: true,
                            fillColor:
                            const Color(
                              0xFFF7F7F7,
                            ),
                            border:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                12,
                              ),
                            ),
                          ),
                          validator:
                              (value) {
                            if (value == null ||
                                value.isEmpty) {
                              return 'Password requirements:\n'
                                  '• At least 8 characters\n'
                                  '• At least 1 uppercase letter\n'
                                  '• At least 1 lowercase letter\n'
                                  '• At least 1 number\n'
                                  '• At least 1 special character';
                            }

                            final hasMinLength =
                                value.length >= 8;

                            final hasUppercase =
                            RegExp(r'[A-Z]')
                                .hasMatch(value);

                            final hasLowercase =
                            RegExp(r'[a-z]')
                                .hasMatch(value);

                            final hasNumber =
                            RegExp(r'[0-9]')
                                .hasMatch(value);

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

                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        TextFormField(
                          controller:
                          _confirmPasswordController,
                          obscureText:
                          _hideConfirmPassword,
                          textInputAction:
                          TextInputAction.done,
                          decoration:
                          InputDecoration(
                            labelText:
                            'Confirm Password',
                            prefixIcon:
                            const Icon(
                              Icons
                                  .lock_outline,
                            ),
                            suffixIcon:
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _hideConfirmPassword =
                                  !_hideConfirmPassword;
                                });
                              },
                              icon: Icon(
                                _hideConfirmPassword
                                    ? Icons
                                    .visibility_outlined
                                    : Icons
                                    .visibility_off_outlined,
                              ),
                            ),
                            filled: true,
                            fillColor:
                            const Color(
                              0xFFF7F7F7,
                            ),
                            border:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                12,
                              ),
                            ),
                          ),
                          validator:
                              (value) {
                            if (value == null ||
                                value.isEmpty) {
                              return 'Please confirm your password';
                            }

                            if (value !=
                                _passwordController
                                    .text) {
                              return 'Passwords do not match';
                            }

                            return null;
                          },
                          onFieldSubmitted:
                              (_) {
                            if (!_isRegistering) {
                              _register();
                            }
                          },
                        ),
                        const SizedBox(
                          height: 28,
                        ),
                        SizedBox(
                          height: 55,
                          child:
                          FilledButton(
                            onPressed:
                            _isRegistering
                                ? null
                                : _register,
                            child:
                            _isRegistering
                                ? const SizedBox(
                              width:
                              22,
                              height:
                              22,
                              child:
                              CircularProgressIndicator(
                                strokeWidth:
                                2,
                                color:
                                Colors.white,
                              ),
                            )
                                : const Text(
                              'REGISTER AS SELLER',
                              style:
                              TextStyle(
                                fontSize:
                                16,
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        TextButton(
                          onPressed:
                          _isRegistering
                              ? null
                              : () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) =>
                                const LoginScreen(),
                              ),
                            );
                          },
                          child:
                          const Text(
                            'Already have an account? Login',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
