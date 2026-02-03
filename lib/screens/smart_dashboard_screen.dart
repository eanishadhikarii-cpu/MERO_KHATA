import 'package:flutter/material.dart';
import '../services/smart_analytics_service.dart';
import '../services/voice_summary_service.dart';
import '../services/backup_service.dart';
import '../models/customer.dart';
import '../database/database_helper.dart';

class SmartDashboardScreen extends StatefulWidget {
  const SmartDashboardScreen({super.key});

  @override
  State<SmartDashboardScreen> createState() => _SmartDashboardScreenState();
}

class _SmartDashboardScreenState extends State<SmartDashboardScreen> {
  final SmartAnalyticsService _analytics = SmartAnalyticsService();
  final VoiceSummaryService _voiceService = VoiceSummaryService();
  final BackupService _backupService = BackupService();
  final DatabaseHelper _db = DatabaseHelper();

  BusinessHealth? _businessHealth;
  List<StockPrediction> _stockPredictions = [];
  List<Customer> _dueCustomers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _voiceService.initialize();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      final health = await _analytics.getBusinessHealth();
      final predictions = await _analytics.getStockPredictions();
      final customers = await _db.getCustomers();
      final dueCustomers = customers.where((c) => c.balance > 0).toList();
      
      setState(() {
        _businessHealth = health;
        _stockPredictions = predictions.take(5).toList();
        _dueCustomers = dueCustomers.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Dashboard'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Voice Summary Section
                    _buildVoiceSummaryCard(),
                    const SizedBox(height: 16),

                    // Business Health Score
                    if (_businessHealth != null) _buildBusinessHealthCard(),
                    const SizedBox(height: 16),

                    // Critical Stock Alerts
                    _buildStockAlertsCard(),
                    const SizedBox(height: 16),

                    // Due Customers
                    _buildDueCustomersCard(),
                    const SizedBox(height: 16),

                    // Quick Actions
                    _buildQuickActionsCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildVoiceSummaryCard() {
    final hour = DateTime.now().hour;
    final isMorning = hour < 12;
    final isEvening = hour >= 18;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mic, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text(
                  'Voice Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (isMorning)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _voiceService.playMorningSummary(),
                      icon: const Icon(Icons.wb_sunny, size: 20),
                      label: const Text('Morning Summary'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[400],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (isEvening)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _voiceService.playNightSummary(),
                      icon: const Icon(Icons.nightlight_round, size: 20),
                      label: const Text('Night Summary'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (!isMorning && !isEvening)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _voiceService.playNightSummary(),
                      icon: const Icon(Icons.summarize, size: 20),
                      label: const Text('Daily Summary'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessHealthCard() {
    final health = _businessHealth!;
    final stars = List.generate(5, (index) => 
      index < health.score ? '⭐' : '☆'
    ).join();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.health_and_safety, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text(
                  'Business Health',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  stars,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    health.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHealthMetric('Sales', health.salesTrend),
                _buildHealthMetric('Profit', health.profitMargin),
                _buildHealthMetric('Credit', health.creditRisk),
                _buildHealthMetric('Stock', health.stockRisk),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetric(String label, double value) {
    final color = value >= 0.7 ? Colors.green : value >= 0.4 ? Colors.orange : Colors.red;
    return Column(
      children: [
        CircularProgressIndicator(
          value: value,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStockAlertsCard() {
    final criticalStock = _stockPredictions.where((p) => p.status == StockStatus.critical).toList();
    final warningStock = _stockPredictions.where((p) => p.status == StockStatus.warning).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory, color: Colors.red[600]),
                const SizedBox(width: 8),
                const Text(
                  'Stock Alerts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (criticalStock.isEmpty && warningStock.isEmpty)
              const Text('All products have sufficient stock')
            else
              Column(
                children: [
                  ...criticalStock.take(3).map((p) => _buildStockItem(p, Colors.red)),
                  ...warningStock.take(3).map((p) => _buildStockItem(p, Colors.orange)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockItem(StockPrediction prediction, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              prediction.product.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '${prediction.daysRemaining} days left',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDueCustomersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Colors.orange[600]),
                const SizedBox(width: 8),
                const Text(
                  'Due Customers',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_dueCustomers.isEmpty)
              const Text('No pending customer payments')
            else
              Column(
                children: _dueCustomers.map((customer) => 
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            customer.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          'Rs. ${customer.balance.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.red[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Colors.purple[600]),
                const SizedBox(width: 8),
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _createBackup,
                    icon: const Icon(Icons.backup, size: 20),
                    label: const Text('Backup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/voice_ledger'),
                    icon: const Icon(Icons.mic, size: 20),
                    label: const Text('Voice'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createBackup() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final result = await _backupService.createBackup();
    Navigator.of(context).pop();

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup created: ${result.fileName}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Backup failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}