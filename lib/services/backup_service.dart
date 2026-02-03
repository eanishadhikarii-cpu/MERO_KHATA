import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final DatabaseHelper _db = DatabaseHelper();

  // Create backup
  Future<BackupResult> createBackup() async {
    try {
      final database = await _db.database;
      final dbPath = database.path;
      
      // Get backup directory
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      
      // Generate backup filename
      final timestamp = DateTime.now();
      final filename = 'mero_khata_backup_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}.mkb';
      final backupPath = '${backupDir.path}/$filename';
      
      // Copy database file
      final dbFile = File(dbPath);
      await dbFile.copy(backupPath);
      
      // Get file size
      final backupFile = File(backupPath);
      final fileSize = await backupFile.length();
      
      return BackupResult.success(
        filePath: backupPath,
        fileName: filename,
        fileSize: fileSize,
        timestamp: timestamp,
      );
    } catch (e) {
      return BackupResult.error('Backup failed: $e');
    }
  }

  // Restore from backup
  Future<RestoreResult> restoreBackup(String backupPath) async {
    try {
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        return RestoreResult.error('Backup file not found');
      }
      
      // Validate backup file
      if (!await _validateBackupFile(backupPath)) {
        return RestoreResult.error('Invalid backup file');
      }
      
      // Close current database
      final database = await _db.database;
      await database.close();
      
      // Get current database path
      final dbPath = database.path;
      
      // Create backup of current database
      final currentDbFile = File(dbPath);
      final tempBackupPath = '$dbPath.temp';
      await currentDbFile.copy(tempBackupPath);
      
      try {
        // Restore backup
        await backupFile.copy(dbPath);
        
        // Test restored database
        final restoredDb = await openDatabase(dbPath);
        await restoredDb.rawQuery('SELECT COUNT(*) FROM products');
        await restoredDb.close();
        
        // Delete temp backup
        await File(tempBackupPath).delete();
        
        return RestoreResult.success('Database restored successfully');
      } catch (e) {
        // Restore original database on failure
        await File(tempBackupPath).copy(dbPath);
        await File(tempBackupPath).delete();
        return RestoreResult.error('Restore failed: $e');
      }
    } catch (e) {
      return RestoreResult.error('Restore failed: $e');
    }
  }

  // List available backups
  Future<List<BackupInfo>> getAvailableBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');
      
      if (!await backupDir.exists()) {
        return [];
      }
      
      final files = await backupDir.list().toList();
      final backups = <BackupInfo>[];
      
      for (FileSystemEntity file in files) {
        if (file is File && file.path.endsWith('.mkb')) {
          final stat = await file.stat();
          final filename = basename(file.path);
          
          backups.add(BackupInfo(
            fileName: filename,
            filePath: file.path,
            fileSize: stat.size,
            createdAt: stat.modified,
          ));
        }
      }
      
      backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return backups;
    } catch (e) {
      return [];
    }
  }

  // Delete backup
  Future<bool> deleteBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Validate backup file
  Future<bool> _validateBackupFile(String backupPath) async {
    try {
      final db = await openDatabase(backupPath, readOnly: true);
      
      // Check if required tables exist
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
      );
      
      final requiredTables = ['products', 'sales', 'customers', 'settings'];
      final existingTables = tables.map((t) => t['name'] as String).toList();
      
      for (String table in requiredTables) {
        if (!existingTables.contains(table)) {
          await db.close();
          return false;
        }
      }
      
      await db.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get backup statistics
  Future<BackupStats> getBackupStats() async {
    final backups = await getAvailableBackups();
    final totalSize = backups.fold(0, (sum, backup) => sum + backup.fileSize);
    
    return BackupStats(
      totalBackups: backups.length,
      totalSize: totalSize,
      latestBackup: backups.isNotEmpty ? backups.first.createdAt : null,
    );
  }
}

class BackupResult {
  final bool success;
  final String? filePath;
  final String? fileName;
  final int? fileSize;
  final DateTime? timestamp;
  final String? error;

  BackupResult._({
    required this.success,
    this.filePath,
    this.fileName,
    this.fileSize,
    this.timestamp,
    this.error,
  });

  factory BackupResult.success({
    required String filePath,
    required String fileName,
    required int fileSize,
    required DateTime timestamp,
  }) => BackupResult._(
    success: true,
    filePath: filePath,
    fileName: fileName,
    fileSize: fileSize,
    timestamp: timestamp,
  );

  factory BackupResult.error(String error) => BackupResult._(
    success: false,
    error: error,
  );
}

class RestoreResult {
  final bool success;
  final String message;

  RestoreResult._(this.success, this.message);

  factory RestoreResult.success(String message) => RestoreResult._(true, message);
  factory RestoreResult.error(String message) => RestoreResult._(false, message);
}

class BackupInfo {
  final String fileName;
  final String filePath;
  final int fileSize;
  final DateTime createdAt;

  BackupInfo({
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.createdAt,
  });

  String get formattedSize {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

class BackupStats {
  final int totalBackups;
  final int totalSize;
  final DateTime? latestBackup;

  BackupStats({
    required this.totalBackups,
    required this.totalSize,
    this.latestBackup,
  });
}