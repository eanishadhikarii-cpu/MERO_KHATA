import 'package:flutter/material.dart';
import '../services/permission_service.dart';
import '../widgets/permission_explanation_dialog.dart';
import '../widgets/settings_redirect_dialog.dart';

class PermissionManager {
  static final PermissionManager _instance = PermissionManager._internal();
  factory PermissionManager() => _instance;
  PermissionManager._internal();

  final PermissionService _permissionService = PermissionService();

  // Request microphone permission with full flow
  Future<bool> requestMicrophonePermission(BuildContext context) async {
    // Check if already granted
    if (await _permissionService.hasMicrophonePermission()) {
      return true;
    }

    // Show explanation dialog first
    final shouldProceed = await _showExplanationDialog(
      context,
      PermissionExplanationDialog.microphone(
        onContinue: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );

    if (!shouldProceed) {
      _showSnackBar(context, 'Voice features are disabled. You can enable them later in Settings.');
      return false;
    }

    // Request system permission
    final result = await _permissionService.requestMicrophonePermission();

    if (result.isGranted) {
      _showSnackBar(context, 'Voice permission enabled successfully', isSuccess: true);
      return true;
    } else if (result.isPermanentlyDenied) {
      await _showSettingsRedirectDialog(context, SettingsRedirectDialog.microphone());
      return false;
    } else {
      _showRetryDialog(context, 'microphone', () => requestMicrophonePermission(context));
      return false;
    }
  }

  // Request notification permission with full flow
  Future<bool> requestNotificationPermission(BuildContext context) async {
    // Check if already granted
    if (await _permissionService.hasNotificationPermission()) {
      return true;
    }

    // Show explanation dialog first
    final shouldProceed = await _showExplanationDialog(
      context,
      PermissionExplanationDialog.notification(
        onContinue: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );

    if (!shouldProceed) {
      _showSnackBar(context, 'Notifications are disabled. You can enable them later in Settings.');
      return false;
    }

    // Request system permission
    final result = await _permissionService.requestNotificationPermission();

    if (result.isGranted) {
      _showSnackBar(context, 'Notification permission enabled successfully', isSuccess: true);
      return true;
    } else if (result.isPermanentlyDenied) {
      await _showSettingsRedirectDialog(context, SettingsRedirectDialog.notification());
      return false;
    } else {
      _showRetryDialog(context, 'notification', () => requestNotificationPermission(context));
      return false;
    }
  }

  // Check permissions on app resume
  Future<Map<String, bool>> checkPermissionsOnResume() async {
    return await _permissionService.checkAllPermissions();
  }

  // Show explanation dialog
  Future<bool> _showExplanationDialog(BuildContext context, Widget dialog) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => dialog,
    );
    return result ?? false;
  }

  // Show settings redirect dialog
  Future<void> _showSettingsRedirectDialog(BuildContext context, Widget dialog) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => dialog,
    );
  }

  // Show retry dialog for temporary denials
  void _showRetryDialog(BuildContext context, String permissionType, VoidCallback onRetry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Needed'),
        content: Text('$permissionType features won\'t work without permission access.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Show snackbar message
  void _showSnackBar(BuildContext context, String message, {bool isSuccess = false}) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Check if voice features are available
  Future<bool> canUseVoiceFeatures() async {
    return await _permissionService.hasMicrophonePermission();
  }

  // Check if notifications are available
  Future<bool> canUseNotifications() async {
    return await _permissionService.hasNotificationPermission();
  }
}