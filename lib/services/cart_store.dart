import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

abstract class CartStore {
  Future<List<CartItem>> load(String userId);
  Future<void> save(String userId, List<CartItem> items);
}

/// Separate from the seller cache so clearing prices cannot erase carts.
class SqliteCartStore implements CartStore {
  Future<Database>? _database;
  Future<Database> get database => _database ??= _open();

  Future<Database> _open() async {
    try {
      return await openDatabase(
        path.join(await getDatabasesPath(), 'smartjimat_carts.db'),
        version: 1,
        onCreate: (db, version) => db.execute('''
          CREATE TABLE cart_items (
            user_id TEXT NOT NULL,
            item_code INTEGER NOT NULL,
            item TEXT NOT NULL,
            unit TEXT NOT NULL,
            item_group TEXT NOT NULL,
            item_category TEXT NOT NULL,
            quantity INTEGER NOT NULL CHECK (quantity > 0),
            PRIMARY KEY (user_id, item_code)
          )
        '''),
      );
    } catch (_) {
      _database = null;
      rethrow;
    }
  }

  @override
  Future<List<CartItem>> load(String userId) async {
    final db = await database;
    final rows = await db.query(
      'cart_items',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'rowid',
    );
    return rows
        .map(
          (row) => CartItem(
            product: Product.fromMap(row),
            quantity: row['quantity'] as int,
          ),
        )
        .toList();
  }

  @override
  Future<void> save(String userId, List<CartItem> items) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('cart_items', where: 'user_id = ?', whereArgs: [userId]);
      final batch = txn.batch();
      for (final entry in items) {
        batch.insert('cart_items', {
          'user_id': userId,
          'item_code': entry.product.itemCode,
          'item': entry.product.item,
          'unit': entry.product.unit,
          'item_group': entry.product.itemGroup,
          'item_category': entry.product.itemCategory,
          'quantity': entry.quantity,
        });
      }
      await batch.commit(noResult: true);
    });
  }
}
