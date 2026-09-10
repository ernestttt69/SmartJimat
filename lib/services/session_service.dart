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
        var profile = await client
            .from('user')
            .select('role')
            .eq('id', id)
            .maybeSingle();
        if (generation != _generation) return;
        if (profile == null) {
          await _createMissingProfile(id, generation);
          if (generation != _generation) return;
          profile = await client.from('user').select('role')
              .eq('id', id).maybeSingle();
          if (generation != _generation) return;
        }
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

  Future<void> _createMissingProfile(String id, int generation) async {
    final user = client.auth.currentUser;
    if (generation != _generation || user == null || user.id != id) return;
    final metadata = user.userMetadata ?? <String, dynamic>{};
    final accountRole = metadata['role'];
    final name = metadata['full_name']?.toString().trim() ?? '';
    final phone = metadata['phone']?.toString().trim() ?? '';
    if ((accountRole != 'customer' && accountRole != 'seller') ||
        name.isEmpty || phone.isEmpty) {
      throw StateError('Your account is missing registration details. Please contact support to restore your profile.');
    }

    int? premiseCode;
    if (accountRole == 'seller') {
      premiseCode = int.tryParse(metadata['premise_code']?.toString() ?? '');
      if (premiseCode == null) {
        throw StateError('Your seller account is missing its registered premise. Please contact support.');
      }
      final premise = await client.from('lookup_premise')
          .select('premise_code').eq('premise_code', premiseCode).maybeSingle();
      if (premise == null) {
        throw StateError('Your registered premise could not be found. Please contact support.');
      }
    }
    if (generation != _generation || client.auth.currentUser?.id != id) return;
    try {
      // Insert only: never overwrite an existing role or profile with metadata.
      // RLS must restrict profile creation to the authenticated user's own ID.
      await client.from('user').insert({
        'id': id,
        'full_name': name,
        'phone': phone,
        'role': accountRole,
        if (accountRole == 'seller') 'premise_code': premiseCode,
      });
    } on PostgrestException catch (e) {
      // A trigger or concurrent session load may already have created the row.
      // The caller reads it again and validates the persisted role.
      if (e.code == '23505') return;
      if (e.code == '42501') {
        throw StateError('Your account exists, but profile creation was denied. Please ask the administrator to check user-table permissions, then tap Retry.');
      }
      rethrow;
    }
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
