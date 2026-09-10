import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_assignment/main.dart';
import 'package:mobile_assignment/models/product.dart';
import 'package:mobile_assignment/screens/main_navigation_screen.dart';
import 'package:mobile_assignment/screens/seller_home_screen.dart';
import 'package:mobile_assignment/screens/shopping_list_screen.dart';
import 'package:mobile_assignment/services/cart_store.dart';
import 'package:mobile_assignment/services/shopping_cart_service.dart';

import '../test/support/fake_backend.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final backend = FakeBackend();

  setUpAll(() async {
    await Supabase.initialize(
      url: 'https://integration.example.test',
      publishableKey: 'fake-test-key',
      httpClient: backend.client,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
        localStorage: EmptyLocalStorage(),
      ),
    );
  });

  testWidgets('login, Home, add cart, rebuild, logout/login, seller isolation', (
    tester,
  ) async {
    final cart = ShoppingCartService.instance;
    await cart.bindUser('integration-customer');
    await cart.clearCart();
    await cart.bindUser(null);
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    Future<void> login(String email) async {
      await tester.tap(find.text('LOGIN'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), email);
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'TestPassword1!',
      );
      await tester.ensureVisible(find.text('LOGIN'));
      await tester.tap(find.text('LOGIN'));
      await tester.pumpAndSettle();
    }

    await login('customer@example.test');
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'RICE');
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(cart.totalQuantity, 1);

    // Recreate the entire UI/session gate, which clears memory and reloads SQLite.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await cart.bindUser(null);
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Shopping List'));
    await tester.pumpAndSettle();
    expect(find.byType(ShoppingListScreen), findsOneWidget);
    expect(find.text('TEST RICE'), findsOneWidget);
    await tester.tap(find.byTooltip('Increase'));
    await tester.pumpAndSettle();
    expect(cart.totalQuantity, 2);

    // Logout from a deep page must remove the whole authenticated route stack.
    await Supabase.instance.client.auth.signOut();
    await tester.pumpAndSettle();
    expect(find.byType(MainNavigationScreen), findsNothing);
    expect(find.byType(ShoppingListScreen), findsNothing);
    expect(cart.items, isEmpty);
    await login('customer@example.test');
    expect(cart.totalQuantity, 2);

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('LOGOUT'), 250);
    await tester.tap(find.text('LOGOUT'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to SmartJimat'), findsOneWidget);
    await login('seller@example.test');
    expect(find.byType(SellerHomeScreen), findsOneWidget);
    expect(cart.items, isEmpty);
    await Supabase.instance.client.auth.signOut();
    await tester.pumpAndSettle();
    await login('customer@example.test');
    expect(cart.totalQuantity, 2);
    await cart.clearCart();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'SQLite database close/reopen preserves cart and account isolation',
    (tester) async {
      final store = SqliteCartStore();
      final cart = ShoppingCartService(store: store);
      await cart.bindUser('integration-disk-test');
      await cart.clearCart();
      await cart.addProduct(
        Product(
          itemCode: 99,
          item: 'Disk test',
          unit: 'kg',
          itemGroup: 'Food',
          itemCategory: 'Test',
        ),
      );
      await cart.increaseQuantity(99);
      cart.dispose();
      await (await store.database).close();

      final reopenedStore = SqliteCartStore();
      final reopened = ShoppingCartService(store: reopenedStore);
      await reopened.bindUser('integration-disk-test');
      expect(reopened.items.single.product.item, 'Disk test');
      expect(reopened.totalQuantity, 2);
      await reopened.bindUser('integration-other-account');
      expect(reopened.items, isEmpty);
      await reopened.bindUser('integration-disk-test');
      await reopened.clearCart();
      reopened.dispose();
      await (await reopenedStore.database).close();
    },
  );
}
