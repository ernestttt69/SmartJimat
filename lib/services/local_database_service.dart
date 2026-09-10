import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabaseService {
  LocalDatabaseService._();

  static final LocalDatabaseService instance =
  LocalDatabaseService._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath =
    await getDatabasesPath();

    final path = join(
      databasePath,
      'smartjimat.db',
    );

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cached_prices (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            item_code INTEGER NOT NULL,
            item_name TEXT NOT NULL,
            premise_code INTEGER NOT NULL,
            premise_name TEXT NOT NULL,
            price REAL NOT NULL,
            date TEXT NOT NULL,
            synced_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE cached_seller_products (
            id INTEGER PRIMARY KEY,
            seller_id TEXT NOT NULL,
            premise_code INTEGER NOT NULL,
            item_code INTEGER NOT NULL,
            item_name TEXT NOT NULL,
            unit TEXT,
            item_group TEXT,
            item_category TEXT,
            price REAL NOT NULL,
            image_url TEXT,
            created_at TEXT,
            synced_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (
          db,
          oldVersion,
          newVersion,
          ) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS cached_seller_products (
              id INTEGER PRIMARY KEY,
              seller_id TEXT NOT NULL,
              premise_code INTEGER NOT NULL,
              item_code INTEGER NOT NULL,
              item_name TEXT NOT NULL,
              unit TEXT,
              item_group TEXT,
              item_category TEXT,
              price REAL NOT NULL,
              image_url TEXT,
              created_at TEXT,
              synced_at TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  Future<void> cacheSellerProducts(
      List<Map<String, dynamic>> products,
      ) async {
    final db = await database;

    final batch = db.batch();

    for (final product in products) {
      batch.insert(
        'cached_seller_products',
        product,
        conflictAlgorithm:
        ConflictAlgorithm.replace,
      );
    }

    await batch.commit(
      noResult: true,
    );
  }

  Future<List<Map<String, dynamic>>>
  getCachedSellerProducts(
      String sellerId,
      ) async {
    final db = await database;

    return db.query(
      'cached_seller_products',
      where: 'seller_id = ?',
      whereArgs: [
        sellerId,
      ],
      orderBy: 'created_at DESC',
    );
  }

  Future<void> clearSellerProductCache(
      String sellerId,
      ) async {
    final db = await database;

    await db.delete(
      'cached_seller_products',
      where: 'seller_id = ?',
      whereArgs: [
        sellerId,
      ],
    );
  }
}