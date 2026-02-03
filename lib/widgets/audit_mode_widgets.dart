import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audit_mode_provider.dart';

class AuditModeIndicator extends StatelessWidget {
  const AuditModeIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuditModeProvider>(
      builder: (context, auditProvider, child) {
        if (!auditProvider.isAuditModeActive) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: const BoxDecoration(
            color: Colors.red,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.lock, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'AUDIT MODE ACTIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (auditProvider.auditLockDate != null)
                Text(
                  'Locked from: ${auditProvider.auditLockDate!.day}/${auditProvider.auditLockDate!.month}/${auditProvider.auditLockDate!.year}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class AuditModeDialog extends StatefulWidget {
  const AuditModeDialog({super.key});

  @override
  State<AuditModeDialog> createState() => _AuditModeDialogState();
}

class _AuditModeDialogState extends State<AuditModeDialog> {
  final _pinController = TextEditingController();
  DateTime _selectedLockDate = DateTime.now().subtract(const Duration(days: 30));
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuditModeProvider>(
      builder: (context, auditProvider, child) {
        return AlertDialog(
          title: Text(auditProvider.isAuditModeActive ? 'Disable Audit Mode' : 'Enable Audit Mode'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!auditProvider.isAuditModeActive) ...[
                const Text(
                  'Audit mode will lock all transactions before the selected date from editing or deletion.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Lock Date'),
                  subtitle: Text('${_selectedLockDate.day}/${_selectedLockDate.month}/${_selectedLockDate.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _selectLockDate,
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _pinController,
                decoration: const InputDecoration(
                  labelText: 'Admin PIN',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _toggleAuditMode,
              style: ElevatedButton.styleFrom(
                backgroundColor: auditProvider.isAuditModeActive ? Colors.green : Colors.red,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(auditProvider.isAuditModeActive ? 'Disable' : 'Enable'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectLockDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedLockDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _selectedLockDate) {
      setState(() {
        _selectedLockDate = picked;
      });
    }
  }

  Future<void> _toggleAuditMode() async {
    if (_pinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter admin PIN')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final auditProvider = context.read<AuditModeProvider>();
    bool success;

    if (auditProvider.isAuditModeActive) {
      success = await auditProvider.disableAuditMode(_pinController.text);
    } else {
      success = await auditProvider.enableAuditMode(_selectedLockDate, _pinController.text);
    }

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auditProvider.isAuditModeActive 
                ? 'Audit mode enabled successfully' 
                : 'Audit mode disabled successfully'
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid PIN or operation failed')),
      );
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
}

// Widget to prevent actions in audit mode
class AuditSafeAction extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final DateTime? transactionDate;

  const AuditSafeAction({
    super.key,
    required this.child,
    this.onPressed,
    this.transactionDate,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuditModeProvider>(
      builder: (context, auditProvider, _) {
        bool canPerformAction = true;

        if (auditProvider.isAuditModeActive) {
          canPerformAction = false;
        } else if (transactionDate != null) {
          // Check if date is locked (this would need to be implemented)
          // canPerformAction = await auditProvider.canEditTransaction(transactionDate!);
        }

        return GestureDetector(
          onTap: canPerformAction ? onPressed : () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Action blocked: Audit mode is active'),
                backgroundColor: Colors.red,
              ),
            );
          },
          child: Opacity(
            opacity: canPerformAction ? 1.0 : 0.5,
            child: child,
          ),
        );
      },
    );
  }
}