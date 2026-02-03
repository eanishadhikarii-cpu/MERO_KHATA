import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/customer.dart';
import '../models/emi.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'mero_khata.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        barcode TEXT,
        cost_price REAL NOT NULL,
        selling_price REAL NOT NULL,
        vat_percent REAL NOT NULL,
        stock_quantity INTEGER NOT NULL,
        category TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bill_number TEXT NOT NULL UNIQUE,
        sale_date TEXT NOT NULL,
        total_amount REAL NOT NULL,
        vat_amount REAL NOT NULL,
        grand_total REAL NOT NULL,
        sale_type TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        customer_id INTEGER,
        customer_name TEXT,
        customer_phone TEXT,
        created_at TEXT NOT NULL,
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
        item_discount REAL DEFAULT 0.0,
        vat_percent REAL NOT NULL,
        total_amount REAL NOT NULL,
        price_overridden INTEGER DEFAULT 0,
        FOREIGN KEY (sale_id) REFERENCES sales (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        total_debit REAL DEFAULT 0,
        total_credit REAL DEFAULT 0,
        balance REAL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

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
        paid_amount REAL DEFAULT 0.0,
        status TEXT DEFAULT 'pending',
        paid_date TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (emi_id) REFERENCES emis (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE voice_ledger_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ledger_name TEXT NOT NULL,
        transaction_type TEXT NOT NULL,
        amount REAL NOT NULL,
        language TEXT NOT NULL,
        entry_mode TEXT DEFAULT 'voice',
        timestamp TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertSale(Sale sale) async {
    final db = await database;
    return await db.transaction((txn) async {
      int saleId = await txn.insert('sales', sale.toMap());
      
      for (SaleItem item in sale.items) {
        await txn.insert('sale_items', {
          'sale_id': saleId,
          'product_id': item.productId,
          'product_name': item.productName,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'original_price': item.originalPrice,
          'item_discount': item.itemDiscount,
          'vat_percent': item.vatPercent,
          'total_amount': item.totalAmount,
          'price_overridden': item.priceOverridden ? 1 : 0,
        });
        
        await txn.rawUpdate(
          'UPDATE products SET stock_quantity = stock_quantity - ? WHERE id = ?',
          [item.quantity, item.productId],
        );
      }
      
      return saleId;
    });
  }

  Future<List<Sale>> getSales({DateTime? startDate, DateTime? endDate}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (startDate != null && endDate != null) {
      whereClause = 'WHERE sale_date BETWEEN ? AND ?';
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    }
    
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM sales $whereClause ORDER BY created_at DESC',
      whereArgs,
    );
    
    List<Sale> sales = [];
    for (Map<String, dynamic> map in maps) {
      Sale sale = Sale.fromMap(map);
      List<SaleItem> items = await getSaleItems(sale.id!);
      sales.add(Sale(
        id: sale.id,
        billNumber: sale.billNumber,
        saleDate: sale.saleDate,
        totalAmount: sale.totalAmount,
        vatAmount: sale.vatAmount,
        grandTotal: sale.grandTotal,
        saleType: sale.saleType,
        paymentMethod: sale.paymentMethod,
        customerId: sale.customerId,
        customerName: sale.customerName,
        customerPhone: sale.customerPhone,
        items: items,
        createdAt: sale.createdAt,
      ));
    }
    
    return sales;
  }

  Future<List<SaleItem>> getSaleItems(int saleId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sale_items',
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    return List.generate(maps.length, (i) => SaleItem(
      id: maps[i]['id'],
      saleId: maps[i]['sale_id'],
      productId: maps[i]['product_id'],
      productName: maps[i]['product_name'],
      quantity: maps[i]['quantity'],
      unitPrice: maps[i]['unit_price'].toDouble(),
      originalPrice: maps[i]['original_price']?.toDouble() ?? maps[i]['unit_price'].toDouble(),
      itemDiscount: maps[i]['item_discount']?.toDouble() ?? 0.0,
      vatPercent: maps[i]['vat_percent'].toDouble(),
      totalAmount: maps[i]['total_amount'].toDouble(),
      priceOverridden: (maps[i]['price_overridden'] ?? 0) == 1,
    ));
  }

  Future<String> generateBillNumber() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM sales');
    int count = result.first['count'] as int;
    return 'MK${(count + 1).toString().padLeft(6, '0')}';
  }

  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return await db.insert('customers', customer.toMap());
  }

  Future<List<Customer>> getCustomers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('customers');
    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  Future<Customer?> getCustomerByPhone(String phone) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'phone = ?',
      whereArgs: [phone],
    );
    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'];
    }
    return null;
  }

  // EMI operations
  Future<int> insertEMI(EMI emi) async {
    final db = await database;
    return await db.transaction((txn) async {
      int emiId = await txn.insert('emis', emi.toMap());
      
      DateTime currentDate = emi.startDate;
      for (int i = 0; i < emi.durationMonths; i++) {
        DateTime dueDate = DateTime(currentDate.year, currentDate.month + i, currentDate.day);
        
        EMIPayment payment = EMIPayment(
          emiId: emiId,
          dueDate: dueDate,
          amount: emi.emiAmount,
          createdAt: DateTime.now(),
        );
        
        await txn.insert('emi_payments', payment.toMap());
      }
      
      return emiId;
    });
  }

  Future<List<EMI>> getEMIs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('emis', orderBy: 'created_at DESC');
    return List.generate(maps.length, (i) => EMI.fromMap(maps[i]));
  }

  Future<List<EMIPayment>> getDueEMIPayments() async {
    final db = await database;
    final today = DateTime.now();
    final todayStr = DateTime(today.year, today.month, today.day).toIso8601String();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'emi_payments',
      where: 'due_date <= ? AND status != ?',
      whereArgs: [todayStr, 'paid'],
      orderBy: 'due_date ASC',
    );
    return List.generate(maps.length, (i) => EMIPayment.fromMap(maps[i]));
  }

  Future<void> markEMIPaymentAsPaid(int paymentId, double amount) async {
    final db = await database;
    await db.update(
      'emi_payments',
      {
        'paid_amount': amount,
        'status': 'paid',
        'paid_date': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [paymentId],
    );
  }

  // Voice Ledger operations
  Future<int> insertVoiceLedgerEntry(Map<String, dynamic> entry) async {
    final db = await database;
    return await db.insert('voice_ledger_entries', entry);
  }

  Future<List<Map<String, dynamic>>> getVoiceLedgerEntries() async {
    final db = await database;
    return await db.query('voice_ledger_entries', orderBy: 'timestamp DESC');
  }
}