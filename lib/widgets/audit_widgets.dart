import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audit_provider.dart';

// Audit mode indicator
class AuditIndicator extends StatelessWidget {
  const AuditIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuditProvider>(
      builder: (context, audit, child) {
        if (!audit.isAuditMode) return const SizedBox.shrink();
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          color: Colors.red,
          child: const Text(
            'AUDIT MODE ACTIVE - READ ONLY',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}

// Audit-safe action wrapper
class AuditSafeAction extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;

  const AuditSafeAction({super.key, required this.child, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuditProvider>(
      builder: (context, audit, _) {
        return GestureDetector(
          onTap: audit.canEdit() ? onPressed : () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Action blocked: Audit mode active')),
            );
          },
          child: Opacity(opacity: audit.canEdit() ? 1.0 : 0.5, child: child),
        );
      },
    );
  }
}

// Audit mode toggle dialog
class AuditToggleDialog extends StatefulWidget {
  const AuditToggleDialog({super.key});

  @override
  State<AuditToggleDialog> createState() => _AuditToggleDialogState();
}

class _AuditToggleDialogState extends State<AuditToggleDialog> {
  final _pinController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Toggle Audit Mode'),
      content: TextField(
        controller: _pinController,
        decoration: const InputDecoration(labelText: 'Admin PIN'),
        obscureText: true,
        keyboardType: TextInputType.number,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final success = await context.read<AuditProvider>().toggleAuditMode(_pinController.text);
            Navigator.pop(context);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(success ? 'Audit mode toggled' : 'Invalid PIN')),
            );
          },
          child: const Text('Toggle'),
        ),
      ],
    );
  }
}