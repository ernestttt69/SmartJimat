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

  final _nameController =
  TextEditingController();

  final _emailController =
  TextEditingController();

  final _phoneController =
  TextEditingController();

  final _premiseCodeController =
  TextEditingController();

  final _shopNameController =
  TextEditingController();

  final _passwordController =
  TextEditingController();

  final _confirmPasswordController =
  TextEditingController();

  final DataGovService _dataGovService =
  DataGovService();

  bool _isRegistering = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final prefs =
    await SharedPreferences.getInstance();

    _nameController.text =
        prefs.getString(
          'seller_name',
        ) ??
            '';

    _emailController.text =
        prefs.getString(
          'seller_email',
        ) ??
            '';

    _phoneController.text =
        prefs.getString(
          'seller_phone',
        ) ??
            '';

    _premiseCodeController.text =
        prefs.getString(
          'seller_premise_code',
        ) ??
            '';

    _shopNameController.text =
        prefs.getString(
          'seller_shop_name',
        ) ??
            '';

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveDraft() async {
    final prefs =
    await SharedPreferences.getInstance();

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
    final prefs =
    await SharedPreferences.getInstance();

    await prefs.remove(
      'seller_name',
    );

    await prefs.remove(
      'seller_email',
    );

    await prefs.remove(
      'seller_phone',
    );

    await prefs.remove(
      'seller_premise_code',
    );

    await prefs.remove(
      'seller_shop_name',
    );
  }

  Future<Map<String, dynamic>?>
  _validatePremise() async {
    final premiseCode =
    int.tryParse(
      _premiseCodeController.text.trim(),
    );

    final shopName =
    _shopNameController.text.trim();

    if (premiseCode == null ||
        shopName.isEmpty) {
      return null;
    }

    return _dataGovService.findPremise(
      premiseCode: premiseCode,
      shopName: shopName,
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      final premise =
      await _validatePremise();

      if (!mounted) {
        return;
      }

      if (premise == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Premise code and shop name do not match the latest data.gov.my PriceCatcher premise data. Seller account cannot be created.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(
              seconds: 5,
            ),
          ),
        );

        return;
      }

      final supabase =
          Supabase.instance.client;

      final premiseCode =
      premise['premise_code'];

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
          'role':
          'seller',
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
        'id':
        user.id,
        'full_name':
        _nameController.text.trim(),
        'phone':
        _phoneController.text.trim(),
        'role':
        'seller',
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
          Color(
            0xFF38BB62,
          ),
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

      String message =
          error.message;

      if (message
          .toLowerCase()
          .contains(
        'security purposes',
      )) {
        message =
        'Please wait a moment before trying again.';
      } else if (message
          .toLowerCase()
          .contains(
        'already registered',
      )) {
        message =
        'This email is already registered.';
      } else if (message
          .toLowerCase()
          .contains(
        'invalid email',
      )) {
        message =
        'Please enter a valid email address.';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),
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
    } catch (error) {
      debugPrint(
        'SELLER REGISTER ERROR: $error',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            error
                .toString()
                .contains(
              'latest premise data',
            )
                ? 'Unable to get the latest premise data from data.gov.my. Please check your internet connection and try again.'
                : 'Registration failed. Please try again.',
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
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor:
      const Color(
        0xFFF7F7F7,
      ),
      border:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          12,
        ),
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
      backgroundColor:
      Colors.white,
      appBar: AppBar(
        backgroundColor:
        Colors.white,
        surfaceTintColor:
        Colors.white,
        elevation: 0,
        title: const Text(
          'Seller Registration',
          style: TextStyle(
            color:
            Color(
              0xFF333632,
            ),
            fontWeight:
            FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (
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
                    : 28,
                vertical:
                30,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints:
                  const BoxConstraints(
                    maxWidth:
                    500,
                  ),
                  child: Form(
                    key:
                    _formKey,
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons
                              .storefront_outlined,
                          size:
                          70,
                          color:
                          Color(
                            0xFF38BB62,
                          ),
                        ),
                        const SizedBox(
                          height:
                          20,
                        ),
                        const Text(
                          'Create Seller Account',
                          textAlign:
                          TextAlign.center,
                          style:
                          TextStyle(
                            fontSize:
                            26,
                            fontWeight:
                            FontWeight.bold,
                            color:
                            Color(
                              0xFF333632,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height:
                          8,
                        ),
                        const Text(
                          'Register your shop using the latest PriceCatcher premise data.',
                          textAlign:
                          TextAlign.center,
                          style:
                          TextStyle(
                            fontSize:
                            14,
                            color:
                            Colors.grey,
                          ),
                        ),
                        const SizedBox(
                          height:
                          30,
                        ),
                        TextFormField(
                          controller:
                          _nameController,
                          onChanged:
                              (_) =>
                              _saveDraft(),
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
                          height:
                          16,
                        ),
                        TextFormField(
                          controller:
                          _emailController,
                          onChanged:
                              (_) =>
                              _saveDraft(),
                          keyboardType:
                          TextInputType.emailAddress,
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

                            final regex =
                            RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            );

                            if (!regex
                                .hasMatch(
                              email,
                            )) {
                              return 'Please enter a valid email';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(
                          height:
                          16,
                        ),
                        TextFormField(
                          controller:
                          _phoneController,
                          onChanged:
                              (_) =>
                              _saveDraft(),
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

                            final phone =
                            value.trim();

                            if (!RegExp(
                              r'^01[0-9]{8,9}$',
                            ).hasMatch(
                              phone,
                            )) {
                              return 'Please enter a valid Malaysian phone number';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(
                          height:
                          16,
                        ),
                        TextFormField(
                          controller:
                          _premiseCodeController,
                          onChanged:
                              (_) =>
                              _saveDraft(),
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
                            'Enter PriceCatcher premise code',
                            icon:
                            Icons
                                .pin_outlined,
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
                          height:
                          16,
                        ),
                        TextFormField(
                          controller:
                          _shopNameController,
                          onChanged:
                              (_) =>
                              _saveDraft(),
                          textInputAction:
                          TextInputAction.next,
                          decoration:
                          _decoration(
                            label:
                            'Shop Name',
                            hint:
                            'Enter shop name exactly as registered',
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
                          height:
                          12,
                        ),
                        Container(
                          padding:
                          const EdgeInsets.all(
                            12,
                          ),
                          decoration:
                          BoxDecoration(
                            color:
                            const Color(
                              0xFFE8F8ED,
                            ),
                            borderRadius:
                            BorderRadius.circular(
                              10,
                            ),
                          ),
                          child:
                          const Row(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons
                                    .cloud_download_outlined,
                                color:
                                Color(
                                  0xFF38BB62,
                                ),
                              ),
                              SizedBox(
                                width:
                                10,
                              ),
                              Expanded(
                                child:
                                Text(
                                  'Premise information will be checked against the latest data from data.gov.my when you register.',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height:
                          16,
                        ),
                        TextFormField(
                          controller:
                          _passwordController,
                          obscureText:
                          _hidePassword,
                          textInputAction:
                          TextInputAction.next,
                          decoration:
                          _decoration(
                            label:
                            'Password',
                            icon:
                            Icons
                                .lock_outline,
                            suffixIcon:
                            IconButton(
                              onPressed:
                                  () {
                                setState(() {
                                  _hidePassword =
                                  !_hidePassword;
                                });
                              },
                              icon:
                              Icon(
                                _hidePassword
                                    ? Icons
                                    .visibility_outlined
                                    : Icons
                                    .visibility_off_outlined,
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
                          height:
                          16,
                        ),
                        TextFormField(
                          controller:
                          _confirmPasswordController,
                          obscureText:
                          _hideConfirmPassword,
                          textInputAction:
                          TextInputAction.done,
                          decoration:
                          _decoration(
                            label:
                            'Confirm Password',
                            icon:
                            Icons
                                .lock_outline,
                            suffixIcon:
                            IconButton(
                              onPressed:
                                  () {
                                setState(() {
                                  _hideConfirmPassword =
                                  !_hideConfirmPassword;
                                });
                              },
                              icon:
                              Icon(
                                _hideConfirmPassword
                                    ? Icons
                                    .visibility_outlined
                                    : Icons
                                    .visibility_off_outlined,
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
                                _passwordController.text) {
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
                          height:
                          28,
                        ),
                        SizedBox(
                          height:
                          55,
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
                          height:
                          15,
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