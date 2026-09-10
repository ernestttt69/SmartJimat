import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_assignment/models/product.dart';
import 'package:mobile_assignment/services/shopping_cart_service.dart';

import 'support/fake_cart_store.dart';

void main() {
  final rice = Product(
    itemCode: 1,
    item: 'Rice',
    unit: '5kg',
    itemGroup: 'Food',
    itemCategory: 'Rice',
  );
  late FakeCartStore store;
  late ShoppingCartService cart;
  setUp(() {
    store = FakeCartStore();
    cart = ShoppingCartService(store: store);
  });
  tearDown(() => cart.dispose());

  test(
    'restart and logout/login restore product details and quantity',
    () async {
      await cart.bindUser('alice');
      await cart.addProduct(rice);
      await cart.increaseQuantity(1);
      await cart.bindUser(null);
      expect(cart.items, isEmpty);
      final restarted = ShoppingCartService(store: store);
      await restarted.bindUser('alice');
      expect(restarted.items.single.product.item, 'Rice');
      expect(restarted.items.single.product.unit, '5kg');
      expect(restarted.totalQuantity, 2);
      restarted.dispose();
    },
  );
  test('accounts remain isolated and anonymous writes are rejected', () async {
    await expectLater(cart.addProduct(rice), throwsStateError);
    await cart.bindUser('alice');
    await cart.addProduct(rice);
    await cart.bindUser('bob');
    expect(cart.items, isEmpty);
    await cart.addProduct(rice);
    await cart.increaseQuantity(1);
    await cart.bindUser('alice');
    expect(cart.totalQuantity, 1);
  });
  test('rapid edits serialize without losing quantities', () async {
    await cart.bindUser('alice');
    await Future.wait(List.generate(20, (_) => cart.addProduct(rice)));
    await cart.bindUser('alice');
    expect(cart.totalQuantity, 20);
    await cart.decreaseQuantity(1);
    await cart.bindUser('alice');
    expect(cart.totalQuantity, 19);
  });
  test(
    'failed save preserves old cart and subsequent writes recover',
    () async {
      await cart.bindUser('alice');
      await cart.addProduct(rice);
      store.failWrites = true;
      await expectLater(cart.clearCart(), throwsStateError);
      expect(cart.totalQuantity, 1);
      store.failWrites = false;
      await cart.addProduct(rice);
      await cart.bindUser('alice');
      expect(cart.totalQuantity, 2);
    },
  );
  test(
    'failed restore blocks edits rather than overwriting saved items',
    () async {
      await cart.bindUser('alice');
      await cart.addProduct(rice);
      store.failReads = true;
      await expectLater(cart.bindUser('alice'), throwsStateError);
      await expectLater(cart.addProduct(rice), throwsStateError);
      store.failReads = false;
      await cart.bindUser('alice');
      expect(cart.totalQuantity, 1);
    },
  );
  test('decrease to zero, remove and clear are durable', () async {
    await cart.bindUser('alice');
    await cart.addProduct(rice);
    await cart.decreaseQuantity(1);
    await cart.bindUser('alice');
    expect(cart.items, isEmpty);
    await cart.addProduct(rice);
    await cart.removeProduct(1);
    await cart.bindUser('alice');
    expect(cart.items, isEmpty);
    await cart.addProduct(rice);
    await cart.clearCart();
    await cart.bindUser('alice');
    expect(cart.items, isEmpty);
  });
  test('late AI response cannot add items to another account', () async {
    await cart.bindUser('bob');
    await expectLater(
      cart.addProduct(rice, expectedUserId: 'alice'),
      throwsStateError,
    );
    expect(cart.items, isEmpty);
  });
}
