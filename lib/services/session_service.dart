import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'shopping_cart_service.dart';

class SessionService extends ChangeNotifier {
  SessionService({required this.client, required this.cart});
  final SupabaseClient client;
  final ShoppingCartService cart;
  StreamSubscription<AuthState>? _subscription;
  String? userId;
  String? role;
  String? error;
  bool loading = true;
  bool recoveringPassword = false;
  int _generation = 0;

  void start() {
    _subscription = client.auth.onAuthStateChange.listen(
      (state) {
        // Defer work outside the auth callback (which may hold the auth lock).
        Future<void>(() async {
          if (_subscription == null) return;
          if (state.event == AuthChangeEvent.passwordRecovery) {
            recoveringPassword = true;
            notifyListeners();
          }
          final id = state.session?.user.id;
          if (id != userId || state.event == AuthChangeEvent.initialSession) {
            await _load(id);
          }
        });
      },
      onError: (Object e) {
        error = 'Unable to restore your session. Please try again.';
        loading = false;
        notifyListeners();
      },
    );
    unawaited(_load(client.auth.currentUser?.id));
  }

  Future<void> retry() => _load(client.auth.currentUser?.id);

  Future<void> _load(String? id) async {
    final generation = ++_generation;
    userId = id;
    role = null;
    error = null;
    loading = true;
    if (id == null) recoveringPassword = false;
    notifyListeners();
    try {
      await cart.bindUser(id);
      if (id != null) {
        final profile = await client
            .from('user')
            .select('role')
            .eq('id', id)
            .maybeSingle();
        if (generation != _generation) return;
        final accountRole = profile?['role'];
        if (accountRole != 'seller' && accountRole != 'customer') {
          throw StateError(
            'Your account profile is missing or has an unsupported role. Please contact support.',
          );
        }
        role = accountRole as String;
      }
    } catch (e) {
      if (generation != _generation) return;
      error = 'Unable to open your account: $e';
    }
    if (generation != _generation) return;
    loading = false;
    notifyListeners();
  }

  void finishPasswordRecovery() {
    recoveringPassword = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await cart.flush();
    await client.auth.signOut();
  }

  @override
  void dispose() {
    _generation++;
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}
