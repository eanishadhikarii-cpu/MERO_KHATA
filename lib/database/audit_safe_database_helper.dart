import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AuditSafeDatabaseHelper {
  static final AuditSafeDatabaseHelper _instance = AuditSafeDatabaseHelper._internal();
  factory AuditSafeDatabaseHelper() => _instance;
  AuditSafeDatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'mero_khata_audit.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Transaction sequence numbers (audit-critical)
    await db.execute('''
      CREATE TABLE transaction_sequences (
        fiscal_year TEXT NOT NULL,
        transaction_type TEXT NOT NULL,
        last_number INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (fiscal_year, transaction_type)
      )
    ''');

    // Audit settings and locks
    await db.execute('''
      CREATE TABLE audit_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        locked_at TEXT,
        locked_by TEXT
      )
    ''');

    // Day close records (prevents editing)
    await db.execute('''
      CREATE TABLE day_close_records (
        close_date TEXT PRIMARY KEY,
        closed_at TEXT NOT NULL,
        closed_by TEXT NOT NULL,
        total_sales REAL NOT NULL,
        total_cash REAL NOT NULL,
        is_finalized INTEGER DEFAULT 1
      )
    ''');

    // Enhanced products with search optimization
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        barcode TEXT UNIQUE,
        sku_code TEXT,
        category TEXT,
        cost_price REAL NOT NULL,
        selling_price REAL NOT NULL,
        vat_percent REAL DEFAULT 13.0,
        stock_quantity INTEGER NOT NULL DEFAULT 0,
        is_favorite INTEGER DEFAULT 0,
        last_sold_at TEXT,
        sale_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create search indexes for performance
    await db.execute('CREATE INDEX idx_products_name ON products(name)');
    await db.execute('CREATE INDEX idx_products_barcode ON products(barcode)');
    await db.execute('CREATE INDEX idx_products_sku ON products(sku_code)');
    await db.execute('CREATE INDEX idx_products_favorite ON products(is_favorite)');
    await db.execute('CREATE INDEX idx_products_last_sold ON products(last_sold_at DESC)');

    // Enhanced sales with audit trail
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_number TEXT NOT NULL UNIQUE,
        vat_invoice_number TEXT UNIQUE,
        bill_number TEXT NOT NULL,
        customer_id INTEGER,
        sale_date TEXT NOT NULL,
        total_amount REAL NOT NULL,
        vat_amount REAL NOT NULL,
        grand_total REAL NOT NULL,
        sale_type TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        is_finalized INTEGER DEFAULT 0,
        finalized_at TEXT,
        day_closed INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        created_by TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    await db.execute('CREATE INDEX idx_sales_transaction_number ON sales(transaction_number)');
    await db.execute('CREATE INDEX idx_sales_date ON sales(sale_date)');
    await db.execute('CREATE INDEX idx_sales_finalized ON sales(is_finalized)');

    // Sale items with audit trail
    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        total_amount REAL NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // Crash recovery table
    await db.execute('''
      CREATE TABLE draft_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_type TEXT NOT NULL,
        draft_data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Database integrity log
    await db.execute('''
      CREATE TABLE integrity_checks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        check_date TEXT NOT NULL,
        status TEXT NOT NULL,
        error_details TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Insert default fiscal year and sequences
    final currentYear = DateTime.now().year + 57; // Nepali calendar
    await db.insert('transaction_sequences', {
      'fiscal_year': currentYear.toString(),
      'transaction_type': 'SALE',
      'last_number': 0
    });
    await db.insert('transaction_sequences', {
      'fiscal_year': currentYear.toString(),
      'transaction_type': 'PUR',
      'last_number': 0
    });
    await db.insert('transaction_sequences', {
      'fiscal_year': currentYear.toString(),
      'transaction_type': 'EXP',
      'last_number': 0
    });
    await db.insert('transaction_sequences', {
      'fiscal_year': currentYear.toString(),
      'transaction_type': 'VAT-INV',
      'last_number': 0
    });

    // Insert default audit settings
    await db.insert('audit_settings', {'key': 'audit_mode_enabled', 'value': 'false'});
    await db.insert('audit_settings', {'key': 'audit_lock_date', 'value': ''});
  }

  // Generate next transaction number (audit-safe)
  Future<String> getNextTransactionNumber(String type) async {
    final db = await database;
    final currentYear = (DateTime.now().year + 57).toString();
    
    return await db.transaction((txn) async {
      // Get current number
      final result = await txn.query(
        'transaction_sequences',
        where: 'fiscal_year = ? AND transaction_type = ?',
        whereArgs: [currentYear, type],
      );
      
      int nextNumber = 1;
      if (result.isNotEmpty) {
        nextNumber = (result.first['last_number'] as int) + 1;
      }
      
      // Update sequence
      await txn.update(
        'transaction_sequences',
        {'last_number': nextNumber},
        where: 'fiscal_year = ? AND transaction_type = ?',
        whereArgs: [currentYear, type],
      );
      
      // Format: SALE-2081-000123
      return '$type-$currentYear-${nextNumber.toString().padLeft(6, '0')}';
    });
  }

  // Check if audit mode is active
  Future<bool> isAuditModeActive() async {
    final db = await database;
    final result = await db.query(
      'audit_settings',
      where: 'key = ?',
      whereArgs: ['audit_mode_enabled'],
    );
    return result.isNotEmpty && result.first['value'] == 'true';
  }

  // Check if date is locked for editing
  Future<bool> isDateLocked(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];
    
    // Check day close
    final dayCloseResult = await db.query(
      'day_close_records',
      where: 'close_date = ? AND is_finalized = 1',
      whereArgs: [dateStr],
    );
    
    if (dayCloseResult.isNotEmpty) return true;
    
    // Check audit lock date
    final auditResult = await db.query(
      'audit_settings',
      where: 'key = ?',
      whereArgs: ['audit_lock_date'],
    );
    
    if (auditResult.isNotEmpty) {
      final lockDateStr = auditResult.first['value'] as String;
      if (lockDateStr.isNotEmpty) {
        final lockDate = DateTime.parse(lockDateStr);
        return date.isBefore(lockDate) || date.isAtSameMomentAs(lockDate);
      }
    }
    
    return false;
  }

  // Database integrity check
  Future<bool> checkDatabaseIntegrity() async {
    try {
      final db = await database;
      
      // SQLite integrity check
      final result = await db.rawQuery('PRAGMA integrity_check');
      final isIntact = result.first.values.first == 'ok';
      
      // Log check result
      await db.insert('integrity_checks', {
        'check_date': DateTime.now().toIso8601String().split('T')[0],
        'status': isIntact ? 'OK' : 'CORRUPTED',
        'error_details': isIntact ? null : result.toString(),
        'created_at': DateTime.now().toIso8601String(),
      });
      
      return isIntact;
    } catch (e) {
      return false;
    }
  }

  // Fast product search with ranking
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final db = await database;
    
    if (query.isEmpty) {
      // Return recent + favorites when no query
      return await db.rawQuery('''
        SELECT *, 
               CASE 
                 WHEN is_favorite = 1 THEN 1
                 WHEN last_sold_at IS NOT NULL THEN 2
                 ELSE 3
               END as priority
        FROM products 
        WHERE stock_quantity > 0
        ORDER BY priority, last_sold_at DESC, sale_count DESC
        LIMIT 20
      ''');
    }
    
    // Multi-field search with ranking
    return await db.rawQuery('''
      SELECT *,
             CASE 
               WHEN barcode = ? THEN 1
               WHEN sku_code = ? THEN 2
               WHEN name LIKE ? THEN 3
               WHEN name LIKE ? THEN 4
               ELSE 5
             END as match_priority
      FROM products 
      WHERE (barcode = ? OR sku_code = ? OR name LIKE ? OR name LIKE ?)
        AND stock_quantity > 0
      ORDER BY match_priority, is_favorite DESC, sale_count DESC
      LIMIT 10
    ''', [
      query, query, '$query%', '%$query%',
      query, query, '$query%', '%$query%'
    ]);
  }

  // Save draft for crash recovery
  Future<void> saveDraft(String type, Map<String, dynamic> data) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    await db.insert(
      'draft_transactions',
      {
        'transaction_type': type,
        'draft_data': data.toString(),
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get latest draft for recovery
  Future<Map<String, dynamic>?> getLatestDraft(String type) async {
    final db = await database;
    final result = await db.query(
      'draft_transactions',
      where: 'transaction_type = ?',
      whereArgs: [type],
      orderBy: 'updated_at DESC',
      limit: 1,
    );
    
    return result.isNotEmpty ? result.first : null;
  }

  // Clear draft after successful save
  Future<void> clearDraft(String type) async {
    final db = await database;
    await db.delete(
      'draft_transactions',
      where: 'transaction_type = ?',
      whereArgs: [type],
    );
  }
}