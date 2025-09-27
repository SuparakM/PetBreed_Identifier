import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB("pets_history.db");
    return _database!;
  }

  static Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  static Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pets_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        datetime TEXT,
        originalImage TEXT,
        boxedImage TEXT,
        breeds TEXT,
        ages TEXT,
        breedDetails TEXT,
        ageTips TEXT,
        boxes TEXT
      )
    ''');
  }
  /// Insert history
  static Future<int> insertHistory(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('pets_history', data);
  }

  /// Get all history (เรียงตาม datetime ล่าสุด)
  static Future<List<Map<String, dynamic>>> getAllHistory() async {
    final db = await database;
    return await db.query('pets_history', orderBy: "datetime DESC");
  }

  /// Delete history by id
  static Future<int> deleteHistory(int id) async {
    final db = await database;
    return await db.delete('pets_history', where: 'id = ?', whereArgs: [id]);
  }

  /// Clear all history
  static Future<int> clearHistory() async {
    final db = await database;
    return await db.delete('pets_history');
  }
}