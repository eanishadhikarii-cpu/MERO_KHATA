import 'package:flutter/material.dart';

class PinInputDialog extends StatefulWidget {
  final String title;
  final bool isSetup;

  const PinInputDialog({
    super.key,
    required this.title,
    this.isSetup = false,
  });

  @override
  State<PinInputDialog> createState() => _PinInputDialogState();
}

class _PinInputDialogState extends State<PinInputDialog> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pinController,
            decoration: InputDecoration(
              labelText: 'PIN',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
            ),
            obscureText: _obscureText,
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
          
          if (widget.isSetup) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPinController,
              decoration: const InputDecoration(
                labelText: 'Confirm PIN',
                border: OutlineInputBorder(),
              ),
              obscureText: _obscureText,
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final pin = _pinController.text.trim();
            
            if (pin.isEmpty) {
              _showMessage('Please enter PIN');
              return;
            }
            
            if (pin.length < 4) {
              _showMessage('PIN must be at least 4 digits');
              return;
            }
            
            if (widget.isSetup) {
              final confirmPin = _confirmPinController.text.trim();
              if (pin != confirmPin) {
                _showMessage('PINs do not match');
                return;
              }
            }
            
            Navigator.pop(context, pin);
          },
          child: Text(widget.isSetup ? 'Set PIN' : 'Verify'),
        ),
      ],
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }
}