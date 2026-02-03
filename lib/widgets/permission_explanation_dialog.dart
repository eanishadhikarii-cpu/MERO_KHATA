import 'package:flutter/material.dart';

class PermissionExplanationDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  const PermissionExplanationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.onContinue,
    required this.onCancel,
  });

  factory PermissionExplanationDialog.microphone({
    required VoidCallback onContinue,
    required VoidCallback onCancel,
  }) {
    return PermissionExplanationDialog(
      title: '🎙️ Enable Voice Ledger',
      message: 'This app uses your microphone to understand voice commands like\\n\"रामको खातामा २००० हालियो\"\\n\\nYour voice is processed only on your phone and is never recorded or sent online.',
      icon: Icons.mic,
      onContinue: onContinue,
      onCancel: onCancel,
    );
  }

  factory PermissionExplanationDialog.notification({
    required VoidCallback onContinue,
    required VoidCallback onCancel,
  }) {
    return PermissionExplanationDialog(
      title: '🔔 Enable Notifications',
      message: 'This app sends notifications for:\\n• Voice command confirmations\\n• EMI payment reminders\\n• Low stock alerts\\n\\nAll notifications are processed locally on your device.',
      icon: Icons.notifications,
      onContinue: onContinue,
      onCancel: onCancel,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: Colors.blue[600],
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Message
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Privacy Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.green[600], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Privacy Protected: All data stays on your device',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Not Now',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}