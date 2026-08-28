import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _emailSent = true;
      });
    } on AuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong. Please try again.',
          ),
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
    _emailController.dispose();
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
          'Forgot Password',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          child: _emailSent
              ? _buildEmailSent()
              : _buildForgotPasswordForm(),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Image.asset(
              'assets/images/smartjimat_logo.png',
              width: 210,
              height: 150,
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Reset Your Password',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333632),
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Enter the email address associated with your SmartJimat account.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 35),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(
                Icons.email_outlined,
              ),
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

          const SizedBox(height: 24),

          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: _isLoading
                  ? null
                  : _sendResetEmail,
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
                'SEND RESET LINK',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF38BB62),
                side: const BorderSide(
                  color: Color(0xFF38BB62),
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'BACK TO LOGIN',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailSent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),

        const Icon(
          Icons.mark_email_read_outlined,
          size: 90,
          color: Color(0xFF38BB62),
        ),

        const SizedBox(height: 25),

        const Text(
          'Check Your Email',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333632),
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'We sent password reset instructions to\n${_emailController.text.trim()}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
            height: 1.5,
          ),
        ),

        const SizedBox(height: 35),

        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'BACK TO LOGIN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        TextButton(
          onPressed: _isLoading
              ? null
              : _sendResetEmail,
          child: const Text(
            'Resend Email',
            style: TextStyle(
              color: Color(0xFF38BB62),
            ),
          ),
        ),
      ],
    );
  }
}