import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/session_service.dart';
import '../services/shopping_cart_service.dart';
import 'main_navigation_screen.dart';
import 'seller_home_screen.dart';
import 'welcome_screen.dart';
import 'reset_password_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, this.session});
  final SessionService? session;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final SessionService session;

  @override
  void initState() {
    super.initState();
    session =
        widget.session ??
        SessionService(
          client: Supabase.instance.client,
          cart: ShoppingCartService.instance,
        );
    session.start();
  }

  @override
  void dispose() {
    session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) {
      if (session.recoveringPassword) {
        return ResetPasswordScreen(onComplete: session.finishPasswordRecovery);
      }
      if (session.loading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (session.error != null) {
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(session.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: session.retry,
                    child: const Text('Retry'),
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        await session.signOut();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Logout failed: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Back to login'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      // All pushed pages belong to this session. Logout removes the entire stack.
      return Navigator(
        key: ValueKey('${session.userId}:${session.role}'),
        onGenerateRoute: (_) => MaterialPageRoute(
          builder: (_) {
            if (session.userId == null) return const WelcomeScreen();
            if (session.role == 'seller') return const SellerHomeScreen();
            return const MainNavigationScreen();
          },
        ),
      );
    },
  );
}
