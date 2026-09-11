import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/data_gov_service.dart';
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

  final DataGovService _dataGovService = DataGovService();

  bool _isRegistering = false;
  bool _isVerifyingPremise = false;
  bool _premiseVerified = false;

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  Map<String, dynamic>? _verifiedPremise;
  String? _premiseError;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();

    _nameController.text =
        prefs.getString('seller_name') ?? '';

    _emailController.text =
        prefs.getString('seller_email') ?? '';

    _phoneController.text =
        prefs.getString('seller_phone') ?? '';

    _premiseCodeController.text =
        prefs.getString('seller_premise_code') ?? '';

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

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('seller_name');
    await prefs.remove('seller_email');
    await prefs.remove('seller_phone');
    await prefs.remove('seller_premise_code');
    await prefs.remove('seller_shop_name');
  }

  void _onPremiseChanged() {
    if (_premiseVerified ||
        _premiseError != null) {
      setState(() {
        _premiseVerified = false;
        _verifiedPremise = null;
        _premiseError = null;

        _passwordController.clear();
        _confirmPasswordController.clear();
      });
    }

    _saveDraft();
  }

  Future<void> _verifyPremise() async {
    final premiseCode = int.tryParse(
      _premiseCodeController.text.trim(),
    );

    final shopName =
    _shopNameController.text.trim();

    if (premiseCode == null) {
      setState(() {
        _premiseVerified = false;
        _verifiedPremise = null;
        _premiseError =
        'Please enter a valid Premise Code.';
      });

      return;
    }

    if (shopName.isEmpty) {
      setState(() {
        _premiseVerified = false;
        _verifiedPremise = null;
        _premiseError =
        'Please enter your Shop Name.';
      });

      return;
    }

    setState(() {
      _isVerifyingPremise = true;
      _premiseVerified = false;
      _verifiedPremise = null;
      _premiseError = null;
    });

    try {
      final premise =
      await _dataGovService.findPremise(
        premiseCode: premiseCode,
        shopName: shopName,
      );

      if (!mounted) {
        return;
      }

      if (premise == null) {
        setState(() {
          _premiseVerified = false;
          _verifiedPremise = null;
          _premiseError =
          'The Premise Code and Shop Name do not match the latest government data. Please check your details and try again.';
        });

        return;
      }

      setState(() {
        _premiseVerified = true;
        _verifiedPremise = premise;
        _premiseError = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _premiseVerified = false;
        _verifiedPremise = null;
        _premiseError =
        'We could not check your shop details right now. Please check your internet connection and try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingPremise = false;
        });
      }
    }
  }

  Future<void> _register() async {
    if (!_premiseVerified ||
        _verifiedPremise == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please verify your shop details before creating your account.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      final supabase =
          Supabase.instance.client;

      final premiseCode =
      _verifiedPremise!['premise_code'];

      final parsedPremiseCode =
      premiseCode is int
          ? premiseCode
          : int.tryParse(
        premiseCode.toString(),
      );

      if (parsedPremiseCode == null) {
        throw Exception(
          'Invalid premise code.',
        );
      }

      final authResponse =
      await supabase.auth.signUp(
        email:
        _emailController.text.trim(),
        password:
        _passwordController.text,
        emailRedirectTo:
        'com.example.assignment://login-callback/',
        data: {
          'full_name':
          _nameController.text.trim(),
          'phone':
          _phoneController.text.trim(),
          'role': 'seller',
          'premise_code':
          parsedPremiseCode,
        },
      );

      final user =
          authResponse.user;

      if (user == null) {
        throw Exception(
          'Unable to create account.',
        );
      }

      await supabase
          .from('user')
          .insert({
        'id': user.id,
        'full_name':
        _nameController.text.trim(),
        'phone':
        _phoneController.text.trim(),
        'role': 'seller',
        'premise_code':
        parsedPremiseCode,
      });

      await _clearDraft();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Seller account created successfully. Please log in.',
          ),
          backgroundColor:
          Color(0xFF38BB62),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
          const LoginScreen(),
        ),
            (route) => false,
      );
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }

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

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
          Colors.red,
        ),
      );
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Database error: ${error.message}',
          ),
          backgroundColor:
          Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to create your account. Please try again.',
          ),
          backgroundColor:
          Colors.red,
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

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    String? hint,
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: enabled
          ? const Color(0xFFF7F7F7)
          : const Color(0xFFE9E9E9),
      border: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildVerificationStatus() {
    if (_premiseVerified) {
      return Container(
        width: double.infinity,
        padding:
        const EdgeInsets.all(14),
        decoration:
        BoxDecoration(
          color:
          const Color(0xFFE8F8ED),
          borderRadius:
          BorderRadius.circular(12),
        ),
        child:
        const Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Icon(
              Icons
                  .check_circle_outline,
              color:
              Color(0xFF38BB62),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Shop Verified\n'
                    'Your Premise Code and Shop Name match the latest government data. You can now create your password.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_premiseError != null) {
      return Container(
        width: double.infinity,
        padding:
        const EdgeInsets.all(14),
        decoration:
        BoxDecoration(
          color:
          const Color(0xFFFFEBEE),
          borderRadius:
          BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _premiseError!,
                style:
                const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(14),
      decoration:
      BoxDecoration(
        color:
        const Color(0xFFE8F8ED),
        borderRadius:
        BorderRadius.circular(12),
      ),
      child:
      const Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            Icons
                .storefront_outlined,
            color:
            Color(0xFF38BB62),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Verify Your Shop\n'
                  'Enter your Premise Code and Shop Name, then verify them with the latest government data before creating your account.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
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
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Seller Registration',
          style: TextStyle(
            color:
            Color(0xFF333632),
            fontWeight:
            FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder:
              (
              context,
              constraints,
              ) {
            final isLandscape =
                constraints.maxWidth >
                    constraints.maxHeight;

            return SingleChildScrollView(
              padding:
              EdgeInsets.symmetric(
                horizontal:
                isLandscape
                    ? 100
                    : 24,
                vertical: 24,
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
                      CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller:
                          _nameController,
                          onChanged:
                              (_) => _saveDraft(),
                          textInputAction:
                          TextInputAction.next,
                          decoration:
                          _decoration(
                            label:
                            'Full Name',
                            icon:
                            Icons
                                .person_outline,
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
                          height: 14,
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
                          _decoration(
                            label:
                            'Email',
                            icon:
                            Icons
                                .email_outlined,
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

                            if (!RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(email)) {
                              return 'Please enter a valid email';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 14,
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
                          _decoration(
                            label:
                            'Phone Number',
                            hint:
                            'Example: 0123456789',
                            icon:
                            Icons
                                .phone_outlined,
                          ),
                          validator:
                              (value) {
                            if (value == null ||
                                value
                                    .trim()
                                    .isEmpty) {
                              return 'Please enter your phone number';
                            }

                            if (!RegExp(
                              r'^01[0-9]{8,9}$',
                            ).hasMatch(
                              value.trim(),
                            )) {
                              return 'Please enter a valid Malaysian phone number';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 14,
                        ),
                        TextFormField(
                          controller:
                          _premiseCodeController,
                          onChanged:
                              (_) =>
                              _onPremiseChanged(),
                          keyboardType:
                          TextInputType.number,
                          textInputAction:
                          TextInputAction.next,
                          inputFormatters: [
                            FilteringTextInputFormatter
                                .digitsOnly,
                          ],
                          decoration:
                          _decoration(
                            label:
                            'Premise Code',
                            hint:
                            'Enter Premise Code',
                            icon:
                            Icons.pin_outlined,
                          ),
                          validator:
                              (value) {
                            if (value == null ||
                                value
                                    .trim()
                                    .isEmpty) {
                              return 'Please enter your premise code';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 14,
                        ),
                        TextFormField(
                          controller:
                          _shopNameController,
                          onChanged:
                              (_) =>
                              _onPremiseChanged(),
                          textInputAction:
                          TextInputAction.done,
                          decoration:
                          _decoration(
                            label:
                            'Shop Name',
                            hint:
                            'Enter Shop Name',
                            icon:
                            Icons
                                .store_outlined,
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
                          height: 12,
                        ),
                        SizedBox(
                          height: 48,
                          child:
                          OutlinedButton.icon(
                            onPressed:
                            _isVerifyingPremise
                                ? null
                                : _verifyPremise,
                            icon:
                            _isVerifyingPremise
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                              CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                                : const Icon(
                              Icons
                                  .verified_outlined,
                            ),
                            label: Text(
                              _isVerifyingPremise
                                  ? 'VERIFYING...'
                                  : 'VERIFY SHOP',
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        _buildVerificationStatus(),
                        const SizedBox(
                          height: 16,
                        ),
                        TextFormField(
                          controller:
                          _passwordController,
                          enabled:
                          _premiseVerified,
                          obscureText:
                          _hidePassword,
                          textInputAction:
                          TextInputAction.next,
                          decoration:
                          _decoration(
                            label:
                            'Password',
                            icon:
                            Icons.lock_outline,
                            enabled:
                            _premiseVerified,
                            suffixIcon:
                            _premiseVerified
                                ? IconButton(
                              onPressed:
                                  () {
                                setState(
                                      () {
                                    _hidePassword =
                                    !_hidePassword;
                                  },
                                );
                              },
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            )
                                : null,
                          ),
                          validator:
                              (value) {
                            if (!_premiseVerified) {
                              return null;
                            }

                            if (value == null ||
                                value.isEmpty) {
                              return 'Please enter a password';
                            }

                            final valid =
                                value.length >= 8 &&
                                    RegExp(
                                      r'[A-Z]',
                                    ).hasMatch(
                                      value,
                                    ) &&
                                    RegExp(
                                      r'[a-z]',
                                    ).hasMatch(
                                      value,
                                    ) &&
                                    RegExp(
                                      r'[0-9]',
                                    ).hasMatch(
                                      value,
                                    ) &&
                                    RegExp(
                                      r'[!@#$%^&*(),.?":{}|<>]',
                                    ).hasMatch(
                                      value,
                                    );

                            if (!valid) {
                              return 'Password must have at least 8 characters, uppercase, lowercase, number and special character';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 14,
                        ),
                        TextFormField(
                          controller:
                          _confirmPasswordController,
                          enabled:
                          _premiseVerified,
                          obscureText:
                          _hideConfirmPassword,
                          textInputAction:
                          TextInputAction.done,
                          decoration:
                          _decoration(
                            label:
                            'Confirm Password',
                            icon:
                            Icons.lock_outline,
                            enabled:
                            _premiseVerified,
                            suffixIcon:
                            _premiseVerified
                                ? IconButton(
                              onPressed:
                                  () {
                                setState(
                                      () {
                                    _hideConfirmPassword =
                                    !_hideConfirmPassword;
                                  },
                                );
                              },
                              icon: Icon(
                                _hideConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            )
                                : null,
                          ),
                          validator:
                              (value) {
                            if (!_premiseVerified) {
                              return null;
                            }

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
                            if (_premiseVerified &&
                                !_isRegistering) {
                              _register();
                            }
                          },
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        SizedBox(
                          height: 55,
                          child:
                          FilledButton(
                            onPressed:
                            _isRegistering ||
                                !_premiseVerified
                                ? null
                                : _register,
                            child:
                            _isRegistering
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                              CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                Colors.white,
                              ),
                            )
                                : const Text(
                              'REGISTER AS SELLER',
                              style:
                              TextStyle(
                                fontSize: 16,
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 14,
                        ),
                        TextButton(
                          onPressed:
                          _isRegistering
                              ? null
                              : () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
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