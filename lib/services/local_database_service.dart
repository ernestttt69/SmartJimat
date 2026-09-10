import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabaseService {
  static final LocalDatabaseService instance =
  LocalDatabaseService._internal();

  static Database? _database;

  LocalDatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(
      databasePath,
      'smartjimat.db',
    );

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(
      Database db,
      int version,
      ) async {
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
  }

  Future<void> insertPrice(
      Map<String, dynamic> price,
      ) async {
    final db = await database;

    await db.insert(
      'cached_prices',
      price,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> savePrices(
      List<Map<String, dynamic>> prices,
      ) async {
    final db = await database;

    final batch = db.batch();

    for (final price in prices) {
      batch.insert(
        'cached_prices',
        price,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedPrices() async {
    final db = await database;

    return await db.query(
      'cached_prices',
      orderBy: 'price ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getPricesByItem(
      int itemCode,
      ) async {
    final db = await database;

    return await db.query(
      'cached_prices',
      where: 'item_code = ?',
      whereArgs: [itemCode],
      orderBy: 'price ASC',
    );
  }

  Future<void> clearCache() async {
    final db = await database;

    await db.delete('cached_prices');
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();

    _database = null;
  }
}