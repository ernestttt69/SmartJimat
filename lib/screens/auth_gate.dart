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

    debugPrint('AuthGate initState');

    session =
        widget.session ??
            SessionService(
              client: Supabase.instance.client,
              cart: ShoppingCartService.instance,
            );

    debugPrint('Before session.start');

    session.start();

    debugPrint('After session.start');
  }

  @override
  void dispose() {
    session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      'AuthGate build loading=${session.loading} '
          'error=${session.error} '
          'userId=${session.userId} '
          'role=${session.role} '
          'recovering=${session.recoveringPassword}',
    );

    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        debugPrint(
          'AuthGate listener loading=${session.loading} '
              'error=${session.error} '
              'userId=${session.userId} '
              'role=${session.role}',
        );

        if (session.recoveringPassword) {
          return ResetPasswordScreen(
            onComplete: session.finishPasswordRecovery,
          );
        }

        if (session.loading) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (session.error != null) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      session.error!,
                      textAlign: TextAlign.center,
                    ),
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
                              SnackBar(
                                content: Text('Logout failed: $e'),
                              ),
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

        return Navigator(
          key: ValueKey('${session.userId}:${session.role}'),
          onGenerateRoute: (_) {
            debugPrint(
              'Navigator route userId=${session.userId} role=${session.role}',
            );

            return MaterialPageRoute(
              builder: (_) {
                if (session.userId == null) {
                  debugPrint('Opening WelcomeScreen');
                  return const WelcomeScreen();
                }

                if (session.role == 'seller') {
                  debugPrint('Opening SellerHomeScreen');
                  return const SellerHomeScreen();
                }

                debugPrint('Opening MainNavigationScreen');
                return const MainNavigationScreen();
              },
            );
          },
        );
      },
    );
  }
}