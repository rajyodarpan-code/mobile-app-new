import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('rajyo_publisher.db');
    return _database!;
  }

  static Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE local_drafts (
            local_id INTEGER PRIMARY KEY AUTOINCREMENT,
            server_uuid TEXT,
            title TEXT,
            content TEXT,
            excerpt TEXT,
            slug TEXT,
            category TEXT,
            tags TEXT,
            seo_title TEXT,
            meta_description TEXT,
            focus_keyword TEXT,
            image_alt TEXT,
            local_image_path TEXT,
            featured_media_id INTEGER,
            is_breaking INTEGER DEFAULT 0,
            is_featured INTEGER DEFAULT 0,
            sync_status TEXT DEFAULT 'draft',
            last_modified TEXT
          )
        ''');
      },
    );
  }
}
