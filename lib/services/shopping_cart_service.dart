import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/product.dart';
import 'cart_store.dart';

class ShoppingCartService extends ChangeNotifier {
  ShoppingCartService({required CartStore store}) : _store = store;
  static final instance = ShoppingCartService(store: SqliteCartStore());
  final CartStore _store;
  List<CartItem> _items = [];
  String? _userId;
  bool _ready = false;
  int _generation = 0;
  Future<void> _pending = Future.value();

  List<CartItem> get items => List.unmodifiable(_copy(_items));
  String? get userId => _userId;
  int get totalUniqueItems => _items.length;
  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);

  static List<CartItem> _copy(List<CartItem> items) => items
      .map((item) => CartItem(product: item.product, quantity: item.quantity))
      .toList();

  /// Clear visible data on account changes, without deleting saved data.
  Future<void> bindUser(String? userId) async {
    final generation = ++_generation;
    _ready = false;
    _userId = userId;
    _items = [];
    notifyListeners();
    await _pending;
    if (generation != _generation || userId == null) return;
    final saved = await _store.load(userId);
    if (generation != _generation) return;
    _items = saved;
    _ready = true;
    notifyListeners();
  }

  Future<void> flush() => _pending;

  /// Persist edits in order before notifying the UI that they succeeded.
  Future<void> _edit(void Function(List<CartItem>) change) {
    final userId = _userId;
    final generation = _generation;
    if (!_ready || userId == null) {
      return Future.error(
        StateError('Please log in and wait for your cart to load.'),
      );
    }
    final result = _pending.then((_) async {
      if (generation != _generation) {
        throw StateError('Account changed. Please try again.');
      }
      final next = _copy(_items);
      change(next);
      await _store.save(userId, next);
      if (generation == _generation) {
        _items = next;
        notifyListeners();
      }
    });
    // A failed edit must not block subsequent writes. The caller gets the error.
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> addProduct(Product product, {String? expectedUserId}) =>
      _edit((items) {
        if (expectedUserId != null && expectedUserId != _userId) {
          throw StateError('Account changed. Please try again.');
        }
        final index = items.indexWhere(
          (item) => item.product.itemCode == product.itemCode,
        );
        if (index < 0) {
          items.add(CartItem(product: product));
        } else {
          items[index].quantity++;
        }
      });

  Future<void> increaseQuantity(int itemCode) => _edit((items) {
    for (final item in items) {
      if (item.product.itemCode == itemCode) item.quantity++;
    }
  });

  Future<void> decreaseQuantity(int itemCode) => _edit((items) {
    for (final item in items) {
      if (item.product.itemCode == itemCode) item.quantity--;
    }
    items.removeWhere((item) => item.quantity <= 0);
  });

  Future<void> removeProduct(int itemCode) => _edit((items) {
    items.removeWhere((item) => item.product.itemCode == itemCode);
  });

  Future<void> clearCart() => _edit((items) => items.clear());
  bool containsProduct(int itemCode) =>
      _items.any((item) => item.product.itemCode == itemCode);
}
