import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_assignment/services/session_service.dart';
import 'package:mobile_assignment/services/shopping_cart_service.dart';

import 'support/fake_backend.dart';
import 'support/fake_cart_store.dart';

void main() {
  late FakeBackend backend;
  late SupabaseClient client;
  late ShoppingCartService cart;
  late SessionService session;
  Future<void> waitFor(bool Function() ready) async {
    for (var i = 0; i < 100; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
      if (ready()) return;
    }
    fail('Session did not reach expected state: ${session.error}');
  }

  setUp(() async {
    backend = FakeBackend();
    client = SupabaseClient(
      'https://integration.example.test',
      'fake-key',
      httpClient: backend.client,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    cart = ShoppingCartService(store: FakeCartStore());
    session = SessionService(client: client, cart: cart)..start();
    await waitFor(() => !session.loading);
  });
  tearDown(() async {
    session.dispose();
    cart.dispose();
    await client.dispose();
  });

  test('invalid credentials keep the account signed out', () async {
    await expectLater(
      client.auth.signInWithPassword(
        email: 'customer@example.test',
        password: 'wrong',
      ),
      throwsA(isA<AuthException>()),
    );
    expect(session.userId, isNull);
    expect(session.role, isNull);
  });
  test('customer and seller resolve to their own roles', () async {
    await client.auth.signInWithPassword(
      email: 'customer@example.test',
      password: 'TestPassword1!',
    );
    await waitFor(() => session.role == 'customer');
    expect(cart.userId, 'integration-customer');
    await session.signOut();
    await waitFor(() => session.userId == null && !session.loading);
    expect(cart.userId, isNull);
    await client.auth.signInWithPassword(
      email: 'seller@example.test',
      password: 'TestPassword1!',
    );
    await waitFor(() => session.role == 'seller');
  });
  test(
    'missing profile shows a retryable error instead of entering Home',
    () async {
      backend.missingProfile = true;
      await client.auth.signInWithPassword(
        email: 'customer@example.test',
        password: 'TestPassword1!',
      );
      await waitFor(() => session.error != null);
      expect(session.role, isNull);
      backend.missingProfile = false;
      await session.retry();
      expect(session.role, 'customer');
      expect(session.error, isNull);
    },
  );
  test('existing session restores its role on app start', () async {
    await client.auth.signInWithPassword(
      email: 'customer@example.test',
      password: 'TestPassword1!',
    );
    await waitFor(() => session.role == 'customer');
    session.dispose();
    session = SessionService(client: client, cart: cart)..start();
    await waitFor(() => session.role == 'customer');
    expect(session.error, isNull);
  });
}
