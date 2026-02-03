import '../models/user.dart';
import '../database/complete_database_helper.dart';

class UserRepository {
  final CompleteDatabaseHelper _dbHelper = CompleteDatabaseHelper();

  // Add users table to database if not exists
  Future<void> _ensureUsersTable() async {
    final db = await _dbHelper.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_users (
        user_id TEXT PRIMARY KEY,
        phone TEXT UNIQUE,
        email TEXT UNIQUE,
        primary_login_method TEXT NOT NULL,
        shop_id TEXT,
        device_id TEXT,
        shop_name TEXT,
        owner_name TEXT,
        shop_type TEXT,
        currency TEXT DEFAULT 'NPR',
        gst_number TEXT,
        app_pin TEXT,
        is_setup_completed INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // Find user by phone or email
  Future<User?> findUser(String phoneOrEmail) async {
    await _ensureUsersTable();
    final db = await _dbHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'app_users',
      where: 'phone = ? OR email = ?',
      whereArgs: [phoneOrEmail, phoneOrEmail],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // Create new user
  Future<User> createUser({
    required String phoneOrEmail,
    required String loginMethod,
    String? deviceId,
  }) async {
    await _ensureUsersTable();
    final db = await _dbHelper.database;
    
    final userId = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();
    
    final user = User(
      userId: userId,
      phone: loginMethod == 'phone' ? phoneOrEmail : null,
      email: loginMethod == 'email' ? phoneOrEmail : null,
      primaryLoginMethod: loginMethod,
      deviceId: deviceId,
      currency: 'NPR',
      createdAt: now,
    );

    await db.insert('app_users', user.toMap());
    return user;
  }

  // Update user profile after setup
  Future<void> updateUserProfile(User user) async {
    await _ensureUsersTable();
    final db = await _dbHelper.database;
    
    await db.update(
      'app_users',
      user.toMap(),
      where: 'user_id = ?',
      whereArgs: [user.userId],
    );
  }

  // Verify PIN for offline access
  Future<bool> verifyPin(String userId, String pin) async {
    await _ensureUsersTable();
    final db = await _dbHelper.database;
    
    final result = await db.query(
      'app_users',
      where: 'user_id = ? AND app_pin = ?',
      whereArgs: [userId, pin],
    );
    
    return result.isNotEmpty;
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    await _ensureUsersTable();
    final db = await _dbHelper.database;
    
    final result = await db.query(
      'app_users',
      orderBy: 'created_at DESC',
      limit: 1,
    );
    
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }
}