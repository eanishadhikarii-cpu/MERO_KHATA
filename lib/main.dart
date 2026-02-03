import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/sales_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/emi_provider.dart';
import 'providers/purchase_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/profit_provider.dart';
import 'providers/supplier_provider.dart';
import 'providers/audit_mode_provider.dart';
import 'providers/fast_search_provider.dart';
import 'providers/performance_sales_provider.dart';
import 'services/performance_monitor_service.dart';
import 'screens/working_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize performance monitoring
  final performanceService = PerformanceMonitorService();
  await performanceService.initialize();
  
  runApp(const MeroKhataApp());
}

class MeroKhataApp extends StatelessWidget {
  const MeroKhataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => EMIProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => ProfitProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => AuditModeProvider()),
        ChangeNotifierProvider(create: (_) => FastSearchProvider()),
        ChangeNotifierProvider(create: (_) => PerformanceSalesProvider()),
      ],
      child: MaterialApp(
        title: 'Mero Khata',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const WorkingHomeScreen(),
      ),
    );
  }
}