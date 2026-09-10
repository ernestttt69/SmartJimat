import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_screen.dart';

class UserRegisterScreen extends StatefulWidget {
  const UserRegisterScreen({super.key});

  @override
  State<UserRegisterScreen> createState() =>
      _UserRegisterScreenState();
}

class _UserRegisterScreenState
    extends State<UserRegisterScreen> {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController =
  TextEditingController();

  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _phoneController =
  TextEditingController();

  final TextEditingController _passwordController =
  TextEditingController();

  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool _isLoading = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response =
      await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'full_name':
          _fullNameController.text.trim(),
          'phone':
          _phoneController.text.trim(),
          'role': 'customer',
        },
      );

      final user = response.user;

      if (user == null) {
        throw Exception(
          'Unable to create account',
        );
      }

      await _supabase
          .from('user')
          .insert({
        'id': user.id,
        'full_name':
        _fullNameController.text.trim(),
        'phone':
        _phoneController.text.trim(),
        'role': 'customer',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registration successful. Please log in.',
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
    } on AuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      debugPrint(
        'USER REGISTER ERROR: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to register account. Please try again.',
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
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'User Registration',
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
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
                          Icons.person_add_alt_1,
                          size: 70,
                          color:
                          Color(0xFF38BB62),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        const Text(
                          'Create User Account',
                          textAlign:
                          TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        const Text(
                          'Register to compare prices and shop smarter.',
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
                          _fullNameController,
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

                            if (!value
                                .contains('@')) {
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
                          keyboardType:
                          TextInputType.phone,
                          textInputAction:
                          TextInputAction.next,
                          decoration:
                          InputDecoration(
                            labelText:
                            'Phone Number',
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
                              return 'Please enter a password';
                            }

                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
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
                            if (!_isLoading) {
                              _registerUser();
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
                            _isLoading
                                ? null
                                : _registerUser,
                            style:
                            FilledButton
                                .styleFrom(
                              backgroundColor:
                              const Color(
                                0xFF38BB62,
                              ),
                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius
                                    .circular(
                                  12,
                                ),
                              ),
                            ),
                            child:
                            _isLoading
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
                              'REGISTER AS USER',
                              style:
                              TextStyle(
                                fontSize:
                                16,
                                fontWeight:
                                FontWeight
                                    .w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        TextButton(
                          onPressed:
                          _isLoading
                              ? null
                              : () {
                            Navigator
                                .pushReplacement(
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
                            style: TextStyle(
                              color:
                              Color(
                                0xFF38BB62,
                              ),
                              fontSize:
                              13,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
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