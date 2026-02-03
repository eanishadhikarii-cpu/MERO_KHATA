import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/audit_provider.dart';
import 'providers/fast_sales_provider.dart';
import 'providers/search_provider.dart';
import 'database/audit_database.dart';
import 'widgets/audit_widgets.dart';
import 'widgets/fast_search_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Database integrity check on startup
  final isIntact = await AuditDatabase.checkIntegrity();
  if (!isIntact) {
    runApp(const DatabaseCorruptedApp());
    return;
  }
  
  runApp(const MeroKhataApp());
}

class MeroKhataApp extends StatelessWidget {
  const MeroKhataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuditProvider()),
        ChangeNotifierProvider(create: (_) => FastSalesProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
      ],
      child: MaterialApp(
        title: 'Mero Khata',
        debugShowCheckedModeBanner: false,
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize providers
    context.read<AuditProvider>().loadAuditMode();
    context.read<FastSalesProvider>().initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mero Khata'),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const AuditToggleDialog(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const AuditIndicator(),
          
          // Sales summary
          Consumer<FastSalesProvider>(
            builder: (context, sales, child) {
              return Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Items: ${sales.cart.length}'),
                    Text('Total: Rs. ${sales.total.toStringAsFixed(2)}'),
                  ],
                ),
              );
            },
          ),
          
          // Product search
          Expanded(
            child: FastSearchWidget(
              onProductSelected: (product) {
                context.read<FastSalesProvider>().addProduct(product, 1);
              },
            ),
          ),
          
          // Complete sale button
          Consumer2<FastSalesProvider, AuditProvider>(
            builder: (context, sales, audit, child) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: AuditSafeAction(
                  onPressed: sales.cart.isNotEmpty ? () async {
                    final success = await sales.completeSale();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(success ? 'Sale completed' : 'Sale failed')),
                    );
                  } : null,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: sales.cart.isNotEmpty ? () {} : null,
                      child: const Text('COMPLETE SALE'),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Database corruption screen
class DatabaseCorruptedApp extends StatelessWidget {
  const DatabaseCorruptedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Database Corrupted', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 8),
              const Text('Please restore from backup'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {}, // Implement backup restore
                child: const Text('Restore Backup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}