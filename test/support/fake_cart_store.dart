import 'package:mobile_assignment/models/cart_item.dart';
import 'package:mobile_assignment/services/cart_store.dart';

class FakeCartStore implements CartStore {
  final data = <String, List<CartItem>>{};
  bool failWrites = false;
  bool failReads = false;
  @override
  Future<List<CartItem>> load(String id) async {
    if (failReads) throw StateError('Disk unavailable');
    return (data[id] ?? [])
        .map((e) => CartItem(product: e.product, quantity: e.quantity))
        .toList();
  }

  @override
  Future<void> save(String id, List<CartItem> items) async {
    if (failWrites) throw StateError('Disk full');
    data[id] = items
        .map((e) => CartItem(product: e.product, quantity: e.quantity))
        .toList();
  }
}
