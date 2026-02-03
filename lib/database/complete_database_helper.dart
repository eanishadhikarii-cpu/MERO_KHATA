import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class CompleteDatabaseHelper {
  static final CompleteDatabaseHelper _instance = CompleteDatabaseHelper._internal();
  factory CompleteDatabaseHelper() => _instance;
  CompleteDatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'mero_khata_complete.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // CORE INVENTORY TABLES
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
        minimum_stock INTEGER DEFAULT 5,
        is_favorite INTEGER DEFAULT 0,
        last_sold_at TEXT,
        sale_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        email TEXT,
        credit_limit REAL DEFAULT 0,
        balance REAL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bill_number TEXT NOT NULL UNIQUE,
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

    await db.execute('''
      CREATE TABLE purchase_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        total_amount REAL NOT NULL,
        FOREIGN KEY (purchase_id) REFERENCES purchases (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE product_batches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        batch_number TEXT,
        expiry_date TEXT,
        quantity INTEGER NOT NULL,
        cost_price REAL NOT NULL,
        supplier_id INTEGER,
        purchase_id INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id),
        FOREIGN KEY (supplier_id) REFERENCES suppliers (id),
        FOREIGN KEY (purchase_id) REFERENCES purchases (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE stock_adjustments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        adjustment_type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        reason TEXT,
        adjusted_by TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // SALES TABLES
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        email TEXT,
        total_debit REAL DEFAULT 0,
        total_credit REAL DEFAULT 0,
        balance REAL DEFAULT 0,
        credit_limit REAL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_number TEXT NOT NULL UNIQUE,
        bill_number TEXT NOT NULL,
        customer_id INTEGER,
        customer_name TEXT,
        customer_phone TEXT,
        sale_date TEXT NOT NULL,
        total_amount REAL NOT NULL,
        discount_amount REAL DEFAULT 0,
        vat_amount REAL NOT NULL,
        grand_total REAL NOT NULL,
        sale_type TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        payment_status TEXT DEFAULT 'paid',
        is_finalized INTEGER DEFAULT 0,
        finalized_at TEXT,
        created_at TEXT NOT NULL,
        created_by TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        original_price REAL NOT NULL,
        item_discount REAL DEFAULT 0,
        vat_percent REAL NOT NULL,
        total_amount REAL NOT NULL,
        price_overridden INTEGER DEFAULT 0,
        FOREIGN KEY (sale_id) REFERENCES sales (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE customer_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        transaction_type TEXT NOT NULL,
        amount REAL NOT NULL,
        reference_id INTEGER,
        reference_type TEXT,
        description TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE payment_installments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        installment_number INTEGER NOT NULL,
        due_amount REAL NOT NULL,
        paid_amount REAL DEFAULT 0,
        due_date TEXT NOT NULL,
        paid_date TEXT,
        status TEXT DEFAULT 'pending',
        created_at TEXT NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id)
      )
    ''');

    // ACCOUNTING TABLES
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        expense_date TEXT NOT NULL,
        payment_method TEXT,
        receipt_number TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_code TEXT NOT NULL UNIQUE,
        account_name TEXT NOT NULL,
        account_type TEXT NOT NULL,
        parent_id INTEGER,
        balance REAL DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (parent_id) REFERENCES accounts (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_number TEXT NOT NULL UNIQUE,
        transaction_date TEXT NOT NULL,
        description TEXT,
        reference_id INTEGER,
        reference_type TEXT,
        total_amount REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transaction_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        account_id INTEGER NOT NULL,
        debit_amount REAL DEFAULT 0,
        credit_amount REAL DEFAULT 0,
        description TEXT,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id),
        FOREIGN KEY (account_id) REFERENCES accounts (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE supplier_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplier_id INTEGER NOT NULL,
        transaction_type TEXT NOT NULL,
        amount REAL NOT NULL,
        reference_id INTEGER,
        reference_type TEXT,
        description TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (supplier_id) REFERENCES suppliers (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE tax_rates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tax_name TEXT NOT NULL,
        tax_rate REAL NOT NULL,
        is_default INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // CASH MANAGEMENT
    await db.execute('''
      CREATE TABLE cash_drawer_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        opening_amount REAL NOT NULL,
        closing_amount REAL DEFAULT 0,
        expected_amount REAL DEFAULT 0,
        variance REAL DEFAULT 0,
        opened_at TEXT NOT NULL,
        closed_at TEXT,
        status TEXT DEFAULT 'open',
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE cash_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        movement_type TEXT NOT NULL,
        amount REAL NOT NULL,
        reference_id INTEGER,
        reference_type TEXT,
        description TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES cash_drawer_sessions (id)
      )
    ''');

    // EMI TRACKING
    await db.execute('''
      CREATE TABLE emis (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lender_name TEXT NOT NULL,
        loan_amount REAL NOT NULL,
        interest_type TEXT NOT NULL,
        interest_rate REAL NOT NULL,
        emi_amount REAL NOT NULL,
        start_date TEXT NOT NULL,
        duration_months INTEGER NOT NULL,
        total_payable REAL NOT NULL,
        total_interest REAL NOT NULL,
        remaining_balance REAL NOT NULL,
        is_completed INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE emi_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        emi_id INTEGER NOT NULL,
        due_date TEXT NOT NULL,
        amount REAL NOT NULL,
        paid_amount REAL DEFAULT 0,
        status TEXT DEFAULT 'pending',
        paid_date TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (emi_id) REFERENCES emis (id)
      )
    ''');

    // AUDIT & COMPLIANCE
    await db.execute('''
      CREATE TABLE transaction_sequences (
        fiscal_year TEXT NOT NULL,
        transaction_type TEXT NOT NULL,
        last_number INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (fiscal_year, transaction_type)
      )
    ''');

    await db.execute('''
      CREATE TABLE audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id INTEGER NOT NULL,
        action TEXT NOT NULL,
        old_values TEXT,
        new_values TEXT,
        user_id TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE day_close_records (
        close_date TEXT PRIMARY KEY,
        closed_at TEXT NOT NULL,
        closed_by TEXT NOT NULL,
        total_sales REAL NOT NULL,
        total_cash REAL NOT NULL,
        total_expenses REAL NOT NULL,
        is_finalized INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE financial_periods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        period_name TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        status TEXT DEFAULT 'open',
        closed_by TEXT,
        closed_at TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE data_integrity_checks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_count INTEGER NOT NULL,
        checksum TEXT NOT NULL,
        validation_status TEXT NOT NULL,
        last_checked TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transaction_reversals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        original_transaction_id INTEGER NOT NULL,
        original_table TEXT NOT NULL,
        reversal_reason TEXT NOT NULL,
        reversed_by TEXT NOT NULL,
        reversal_amount REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // SYSTEM TABLES
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        description TEXT,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        full_name TEXT NOT NULL,
        role TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        last_login TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE user_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        session_token TEXT NOT NULL UNIQUE,
        expires_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE draft_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_type TEXT NOT NULL,
        draft_data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sequence_numbers (
        sequence_type TEXT PRIMARY KEY,
        current_number INTEGER NOT NULL DEFAULT 0,
        prefix TEXT,
        suffix TEXT,
        reset_frequency TEXT,
        last_reset TEXT,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE data_sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id INTEGER NOT NULL,
        operation TEXT NOT NULL,
        data_json TEXT NOT NULL,
        sync_status TEXT DEFAULT 'pending',
        created_at TEXT NOT NULL,
        synced_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_summaries (
        summary_date TEXT PRIMARY KEY,
        total_sales REAL NOT NULL,
        total_purchases REAL NOT NULL,
        total_expenses REAL NOT NULL,
        net_profit REAL NOT NULL,
        cash_sales REAL NOT NULL,
        credit_sales REAL NOT NULL,
        transaction_count INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE inventory_snapshots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        snapshot_date TEXT NOT NULL,
        product_id INTEGER NOT NULL,
        stock_quantity INTEGER NOT NULL,
        stock_value REAL NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE backups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        backup_name TEXT NOT NULL,
        backup_path TEXT NOT NULL,
        backup_size INTEGER NOT NULL,
        backup_type TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // CREATE PERFORMANCE INDEXES
    await db.execute('CREATE INDEX idx_products_name ON products(name)');
    await db.execute('CREATE INDEX idx_products_barcode ON products(barcode)');
    await db.execute('CREATE INDEX idx_products_category ON products(category)');
    await db.execute('CREATE INDEX idx_products_favorite ON products(is_favorite)');
    await db.execute('CREATE INDEX idx_sales_date ON sales(sale_date)');
    await db.execute('CREATE INDEX idx_sales_customer ON sales(customer_id)');
    await db.execute('CREATE INDEX idx_sales_transaction_number ON sales(transaction_number)');
    await db.execute('CREATE INDEX idx_customers_phone ON customers(phone)');
    await db.execute('CREATE INDEX idx_expenses_date ON expenses(expense_date)');
    await db.execute('CREATE INDEX idx_expenses_category ON expenses(category)');
    await db.execute('CREATE INDEX idx_audit_logs_table ON audit_logs(table_name, record_id)');
    await db.execute('CREATE INDEX idx_cash_movements_session ON cash_movements(session_id)');
    await db.execute('CREATE INDEX idx_installments_due_date ON payment_installments(due_date)');

    // INSERT DEFAULT DATA
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

    await db.insert('tax_rates', {
      'tax_name': 'VAT',
      'tax_rate': 13.0,
      'is_default': 1,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String()
    });

    await db.insert('settings', {
      'key': 'shop_name',
      'value': 'My Shop',
      'description': 'Shop name for receipts',
      'updated_at': DateTime.now().toIso8601String()
    });

    await db.insert('settings', {
      'key': 'vat_number',
      'value': '',
      'description': 'VAT registration number',
      'updated_at': DateTime.now().toIso8601String()
    });

    await db.insert('settings', {
      'key': 'currency',
      'value': 'NPR',
      'description': 'Default currency',
      'updated_at': DateTime.now().toIso8601String()
    });
  }
}