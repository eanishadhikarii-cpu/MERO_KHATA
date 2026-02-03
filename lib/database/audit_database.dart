import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AuditDatabase {
  static Database? _db;
  
  static Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    return await openDatabase(
      join(await getDatabasesPath(), 'audit_khata.db'),
      version: 1,
      onCreate: (db, version) async {
        // Transaction sequences (audit-critical)
        await db.execute('''
          CREATE TABLE sequences (
            type TEXT PRIMARY KEY,
            fiscal_year TEXT NOT NULL,
            last_number INTEGER DEFAULT 0
          )
        ''');

        // Audit settings
        await db.execute('''
          CREATE TABLE audit_settings (
            key TEXT PRIMARY KEY,
            value TEXT,
            locked_at TEXT
          )
        ''');

        // Products (search-optimized)
        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            barcode TEXT UNIQUE,
            price REAL NOT NULL,
            stock INTEGER DEFAULT 0,
            is_favorite INTEGER DEFAULT 0,
            last_sold TEXT,
            sale_count INTEGER DEFAULT 0
          )
        ''');

        // Sales (audit-safe)
        await db.execute('''
          CREATE TABLE sales (
            id INTEGER PRIMARY KEY,
            transaction_number TEXT UNIQUE NOT NULL,
            vat_invoice_number TEXT UNIQUE,
            total REAL NOT NULL,
            is_finalized INTEGER DEFAULT 0,
            finalized_at TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // Draft recovery
        await db.execute('''
          CREATE TABLE drafts (
            type TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // Performance indexes
        await db.execute('CREATE INDEX idx_products_name ON products(name)');
        await db.execute('CREATE INDEX idx_products_barcode ON products(barcode)');
        await db.execute('CREATE INDEX idx_products_favorite ON products(is_favorite, last_sold DESC)');
        await db.execute('CREATE INDEX idx_sales_finalized ON sales(is_finalized)');

        // Initialize sequences
        final year = DateTime.now().year + 57; // Nepali calendar
        await db.insert('sequences', {'type': 'SALE', 'fiscal_year': year.toString()});
        await db.insert('sequences', {'type': 'VAT-INV', 'fiscal_year': year.toString()});
        
        // Initialize audit settings
        await db.insert('audit_settings', {'key': 'audit_mode', 'value': 'false'});
      },
    );
  }

  // Generate sequential transaction number (audit-safe)
  static Future<String> getNextNumber(String type) async {
    final db = await database;
    final year = (DateTime.now().year + 57).toString();
    
    return await db.transaction((txn) async {
      final result = await txn.query('sequences', where: 'type = ?', whereArgs: [type]);
      final current = result.isEmpty ? 0 : result.first['last_number'] as int;
      final next = current + 1;
      
      await txn.update('sequences', {'last_number': next}, where: 'type = ?', whereArgs: [type]);
      return '$type-$year-${next.toString().padLeft(6, '0')}';
    });
  }

  // Fast product search (sub-100ms)
  static Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final db = await database;
    
    if (query.isEmpty) {
      return await db.rawQuery('''
        SELECT * FROM products 
        WHERE stock > 0 
        ORDER BY is_favorite DESC, last_sold DESC 
        LIMIT 20
      ''');
    }
    
    return await db.rawQuery('''
      SELECT *, 
        CASE 
          WHEN barcode = ? THEN 1
          WHEN name LIKE ? THEN 2
          ELSE 3
        END as priority
      FROM products 
      WHERE (barcode = ? OR name LIKE ?) AND stock > 0
      ORDER BY priority, is_favorite DESC, sale_count DESC
      LIMIT 10
    ''', [query, '$query%', query, '%$query%']);
  }

  // Check audit mode
  static Future<bool> isAuditMode() async {
    final db = await database;
    final result = await db.query('audit_settings', where: 'key = ?', whereArgs: ['audit_mode']);
    return result.isNotEmpty && result.first['value'] == 'true';
  }

  // Database integrity check
  static Future<bool> checkIntegrity() async {
    try {
      final db = await database;
      final result = await db.rawQuery('PRAGMA integrity_check');
      return result.first.values.first == 'ok';
    } catch (e) {
      return false;
    }
  }
}