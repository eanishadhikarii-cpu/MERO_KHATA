import 'package:flutter/material.dart';
import '../database/audit_safe_database_helper.dart';
import 'dart:async';

class PerformanceMonitorService {
  static final PerformanceMonitorService _instance = PerformanceMonitorService._internal();
  factory PerformanceMonitorService() => _instance;
  PerformanceMonitorService._internal();

  final AuditSafeDatabaseHelper _db = AuditSafeDatabaseHelper();
  DateTime? _appStartTime;
  bool _isInitialized = false;

  // Performance metrics
  double _averageDbTime = 0.0;
  final List<double> _dbTimes = [];

  // Initialize performance monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _appStartTime = DateTime.now();
    
    // Check database integrity on startup
    final isIntact = await _db.checkDatabaseIntegrity();
    if (!isIntact) {
      throw Exception('Database corruption detected. Please restore from backup.');
    }

    _isInitialized = true;
  }

  // Track database operation time
  Future<T> trackDbOperation<T>(Future<T> Function() operation) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      _dbTimes.add(stopwatch.elapsedMilliseconds.toDouble());
      
      // Alert if operation is too slow
      if (stopwatch.elapsedMilliseconds > 500) {
        debugPrint('Slow DB operation detected: ${stopwatch.elapsedMilliseconds}ms');
      }
      
      return result;
    } catch (e) {
      stopwatch.stop();
      debugPrint('DB operation failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      rethrow;
    }
  }

  // Get app launch time
  Duration? getAppLaunchTime() {
    if (_appStartTime == null) return null;
    return DateTime.now().difference(_appStartTime!);
  }

  // Check if app is performing well
  bool isPerformingWell() {
    if (_dbTimes.isEmpty) return true;
    _averageDbTime = _dbTimes.reduce((a, b) => a + b) / _dbTimes.length;
    return _averageDbTime < 100.0; // Less than 100ms average
  }

  // Crash recovery check
  Future<Map<String, dynamic>?> checkForCrashRecovery() async {
    try {
      final salesDraft = await _db.getLatestDraft('SALE');
      if (salesDraft != null) {
        final draftTime = DateTime.parse(salesDraft['updated_at']);
        final timeDiff = DateTime.now().difference(draftTime);
        
        if (timeDiff.inMinutes > 5) {
          return {
            'type': 'SALE',
            'data': salesDraft,
            'crash_time': draftTime,
          };
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error checking crash recovery: $e');
      return null;
    }
  }
}