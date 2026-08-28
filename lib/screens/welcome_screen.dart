import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'seller_register_screens.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const Color smartJimatGreen = Color(0xFF38BB62);
  static const Color smartJimatDark = Color(0xFF333632);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 20,
          ),
          child: Column(
            children: [
              const Spacer(flex: 2),

              SizedBox(
                width: 360,
                height: 300,
                child: Image.asset(
                  'assets/images/smartjimat_logo.png',
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Welcome to SmartJimat',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: smartJimatDark,
                ),
              ),

              const Spacer(flex: 3),

              // LOGIN
              SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: smartJimatGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                  },
                  child: const Text(
                    'LOGIN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // REGISTER
              SizedBox(
                width: double.infinity,
                height: 58,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: smartJimatGreen,
                    backgroundColor: Colors.white,
                    side: const BorderSide(
                      color: smartJimatGreen,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                        const SellerRegisterScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'REGISTER',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}