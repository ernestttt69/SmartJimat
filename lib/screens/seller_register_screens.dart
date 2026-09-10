import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/premise.dart';
import '../services/premise_service.dart';

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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final PremiseService _premiseService = PremiseService();

  List<Premise> _premises = [];
  Premise? _selectedPremise;

  bool _isLoadingPremises = true;
  bool _isRegistering = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadPremises();
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();

    _nameController.text =
        prefs.getString('seller_name') ?? '';

    _emailController.text =
        prefs.getString('seller_email') ?? '';

    _phoneController.text =
        prefs.getString('seller_phone') ?? '';

    final savedPremiseCode =
    prefs.getInt('seller_premise_code');

    if (savedPremiseCode != null &&
        _premises.isNotEmpty) {
      final matches = _premises.where(
            (premise) =>
        premise.premiseCode == savedPremiseCode,
      );

      if (matches.isNotEmpty) {
        _selectedPremise = matches.first;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadPremises() async {
    try {
      final premises = await _premiseService.getPremises();

      debugPrint('Premises loaded: ${premises.length}');

      if (!mounted) return;

      setState(() {
        _premises = premises;
        _isLoadingPremises = false;
      });

      await _loadDraft();
    } catch (error) {
      debugPrint('Premise loading error: $error');

      if (!mounted) return;

      setState(() {
        _isLoadingPremises = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load premises: $error',
          ),
          backgroundColor: Colors.red,
        ),
      );
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

    if (_selectedPremise != null) {
      await prefs.setInt(
        'seller_premise_code',
        _selectedPremise!.premiseCode,
      );
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPremise == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a premise'),
        ),
      );
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      final supabase = Supabase.instance.client;

      final authResponse = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        emailRedirectTo: 'com.example.assignment://login-callback/',
        data: {
          'full_name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'role': 'seller',
          'premise_code': _selectedPremise!.premiseCode,
        },
      );

      final user = authResponse.user;

      if (user == null) {
        throw Exception('Unable to create account');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Seller account created successfully!',
          ),
          backgroundColor: Color(0xFF38BB62),
        ),
      );

      _clearForm();

      Navigator.pop(context);
    } on AuthException catch (error) {
      if (!mounted) return;

      String message = error.message;

      if (message.toLowerCase().contains('security purposes')) {
        message = 'Please wait a moment before trying again.';
      } else if (message
          .toLowerCase()
          .contains('already registered')) {
        message = 'This email is already registered.';
      } else if (message.toLowerCase().contains('invalid email')) {
        message = 'Please enter a valid email address.';
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
            'Registration failed: $error',
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

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();

    setState(() {
      _selectedPremise = null;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
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
                    width: 170,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Create Seller Account',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333632),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Register your premise to manage products and prices.',
                  style: TextStyle(
                    color: Color(0xFF666666),
                  ),
                ),

                const SizedBox(height: 24),

                TextFormField(
                  controller: _nameController,
                  onChanged: (_) => _saveDraft(),
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  onChanged: (_) => _saveDraft(),
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }

                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => _saveDraft(),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],

                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Example: 0123456789',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    final phone = value.trim();
                    final phoneRegex = RegExp(r'^01[0-9]{8,9}$');
                    if (!phoneRegex.hasMatch(phone)) {
                      return 'Please enter a valid Malaysian phone number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Premise
                _isLoadingPremises
                    ? const Center(
                  child: CircularProgressIndicator(),
                )
                    : DropdownButtonFormField<Premise>(
                  initialValue: _selectedPremise,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Premise',
                  ),
                  items: _premises.map((premise) {
                    return DropdownMenuItem<Premise>(
                      value: premise,
                      child: Text(
                        premise.premise,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPremise = value;
                    });
                    _saveDraft();
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select your premise';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _hidePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    errorMaxLines: 6,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _hidePassword = !_hidePassword;
                        });
                      },
                      icon: Icon(
                        _hidePassword
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

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _hideConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
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
                      return 'Please confirm your password';
                    }

                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Register Button
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed:
                    _isRegistering ? null : _register,
                    child: _isRegistering
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'REGISTER',
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