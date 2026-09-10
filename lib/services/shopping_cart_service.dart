import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

class ShoppingCartService extends ChangeNotifier {
  ShoppingCartService._();

  static final ShoppingCartService instance =
  ShoppingCartService._();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalUniqueItems => _items.length;

  int get totalQuantity {
    int total = 0;

    for (final item in _items) {
      total += item.quantity;
    }

    return total;
  }

  void addProduct(Product product) {
    final index = _items.indexWhere(
          (item) => item.product.itemCode == product.itemCode,
    );

    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(
        CartItem(
          product: product,
          quantity: 1,
        ),
      );
    }

    notifyListeners();
  }

  void increaseQuantity(int itemCode) {
    final index = _items.indexWhere(
          (item) => item.product.itemCode == itemCode,
    );

    if (index == -1) return;

    _items[index].quantity++;

    notifyListeners();
  }

  void decreaseQuantity(int itemCode) {
    final index = _items.indexWhere(
          (item) => item.product.itemCode == itemCode,
    );

    if (index == -1) return;

    if (_items[index].quantity > 1) {
      _items[index].quantity--;
    } else {
      _items.removeAt(index);
    }

    notifyListeners();
  }

  void removeProduct(int itemCode) {
    _items.removeWhere(
          (item) => item.product.itemCode == itemCode,
    );

    notifyListeners();
  }

  void clearCart() {
    _items.clear();

    notifyListeners();
  }

  bool containsProduct(int itemCode) {
    return _items.any(
          (item) => item.product.itemCode == itemCode,
    );
  }
}