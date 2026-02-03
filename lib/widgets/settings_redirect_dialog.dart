import 'package:flutter/material.dart';

class SettingsRedirectDialog extends StatelessWidget {
  final String permissionName;
  final String feature;

  const SettingsRedirectDialog({
    super.key,
    required this.permissionName,
    required this.feature,
  });

  factory SettingsRedirectDialog.microphone() {
    return const SettingsRedirectDialog(
      permissionName: 'Microphone',
      feature: 'Voice Features',
    );
  }

  factory SettingsRedirectDialog.notification() {
    return const SettingsRedirectDialog(
      permissionName: 'Notification',
      feature: 'Notifications',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Permission Required'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.settings,
            size: 48,
            color: Colors.orange,
          ),
          SizedBox(height: 16),
          Text(
            'To use $feature, please enable $permissionName permission in Settings.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Open Settings'),
        ),
      ],
    );
  }
}