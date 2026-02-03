import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class EnhancedDatabaseHelper {
  static final EnhancedDatabaseHelper _instance = EnhancedDatabaseHelper._internal();
  factory EnhancedDatabaseHelper() => _instance;
  EnhancedDatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'mero_khata_enhanced.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Products table (enhanced)
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        barcode TEXT UNIQUE,
        category TEXT,
        cost_price REAL NOT NULL,
        selling_price REAL NOT NULL,
        vat_applicable INTEGER DEFAULT 1,
        vat_percent REAL DEFAULT 13.0,
        stock_quantity INTEGER NOT NULL DEFAULT 0,
        min_stock_threshold INTEGER DEFAULT 5,
        unit TEXT DEFAULT 'pcs',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Suppliers table
    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        pan_number TEXT,
        credit_limit REAL DEFAULT 0,
        balance REAL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Customers table (enhanced)
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        credit_limit REAL DEFAULT 0,
        balance REAL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Purchases table
    await db.execute('''
      CREATE TABLE purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bill_number TEXT NOT NULL,
        supplier_id INTEGER,
        purchase_date TEXT NOT NULL,
        total_amount REAL NOT NULL,
        vat_amount REAL NOT NULL,
        grand_total REAL NOT NULL,
        payment_status TEXT DEFAULT 'pending',
        created_at TEXT NOT NULL,
        FOREIGN KEY (supplier_id) REFERENCES suppliers (id)
      )
    ''');

    // Purchase items table
    await db.execute('''
      CREATE TABLE purchase_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        cost_price REAL NOT NULL,
        vat_percent REAL NOT NULL,
        total_amount REAL NOT NULL,
        FOREIGN KEY (purchase_id) REFERENCES purchases (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // Sales table (enhanced)
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bill_number TEXT NOT NULL UNIQUE,
        customer_id INTEGER,
        sale_date TEXT NOT NULL,
        total_amount REAL NOT NULL,
        vat_amount REAL NOT NULL,
        grand_total REAL NOT NULL,
        sale_type TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        profit_amount REAL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    // Sale items table (enhanced)
    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        cost_price REAL NOT NULL,
        selling_price REAL NOT NULL,
        vat_percent REAL NOT NULL,
        total_amount REAL NOT NULL,
        profit_amount REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // Expenses table
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        description TEXT,
        amount REAL NOT NULL,
        expense_date TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Payments table (customer/supplier)
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL, -- 'customer' or 'supplier'
        entity_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        payment_date TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Insert default expense categories
    await db.insert('settings', {'key': 'expense_categories', 'value': 'Rent,Electricity,Salary,Transport,Internet,Misc'});
    await db.insert('settings', {'key': 'shop_name', 'value': 'My Shop'});
    await db.insert('settings', {'key': 'vat_rate', 'value': '13.0'});
  }

  // Profit calculation helper
  double calculateProfit(double sellingPrice, double costPrice, int quantity) {
    return (sellingPrice - costPrice) * quantity;
  }

  // VAT calculation helper
  double calculateVAT(double amount, double vatPercent) {
    return amount * (vatPercent / 100);
  }

  // Get low stock products
  Future<List<Map<String, dynamic>>> getLowStockProducts() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT * FROM products 
      WHERE stock_quantity <= min_stock_threshold 
      ORDER BY stock_quantity ASC
    ''');
  }

  // Daily profit calculation
  Future<double> getDailyProfit(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];
    
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(profit_amount), 0) as total_profit
      FROM sales 
      WHERE DATE(sale_date) = ?
    ''', [dateStr]);
    
    return result.first['total_profit'] as double;
  }

  // Daily expenses
  Future<double> getDailyExpenses(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];
    
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total_expenses
      FROM expenses 
      WHERE DATE(expense_date) = ?
    ''', [dateStr]);
    
    return result.first['total_expenses'] as double;
  }

  // Net profit (profit - expenses)
  Future<double> getNetProfit(DateTime date) async {
    final profit = await getDailyProfit(date);
    final expenses = await getDailyExpenses(date);
    return profit - expenses;
  }
}