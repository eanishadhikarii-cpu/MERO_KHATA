import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // Check if microphone permission is granted
  Future<bool> hasMicrophonePermission() async {
    return await Permission.microphone.isGranted;
  }

  // Check if notification permission is granted
  Future<bool> hasNotificationPermission() async {
    return await Permission.notification.isGranted;
  }

  // Request microphone permission with proper flow
  Future<PermissionResult> requestMicrophonePermission() async {
    final status = await Permission.microphone.status;
    
    if (status.isGranted) {
      return PermissionResult.granted();
    }
    
    if (status.isPermanentlyDenied) {
      return PermissionResult.permanentlyDenied();
    }
    
    final result = await Permission.microphone.request();
    
    if (result.isGranted) {
      return PermissionResult.granted();
    } else if (result.isPermanentlyDenied) {
      return PermissionResult.permanentlyDenied();
    } else {
      return PermissionResult.denied();
    }
  }

  // Request notification permission
  Future<PermissionResult> requestNotificationPermission() async {
    final status = await Permission.notification.status;
    
    if (status.isGranted) {
      return PermissionResult.granted();
    }
    
    if (status.isPermanentlyDenied) {
      return PermissionResult.permanentlyDenied();
    }
    
    final result = await Permission.notification.request();
    
    if (result.isGranted) {
      return PermissionResult.granted();
    } else if (result.isPermanentlyDenied) {
      return PermissionResult.permanentlyDenied();
    } else {
      return PermissionResult.denied();
    }
  }

  // Open app settings
  Future<void> openSettings() async {
    await openAppSettings();
  }

  // Check permission status on app resume
  Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'microphone': await hasMicrophonePermission(),
      'notification': await hasNotificationPermission(),
    };
  }
}

class PermissionResult {
  final bool isGranted;
  final bool isDenied;
  final bool isPermanentlyDenied;
  final String message;

  PermissionResult._({
    required this.isGranted,
    required this.isDenied,
    required this.isPermanentlyDenied,
    required this.message,
  });

  factory PermissionResult.granted() => PermissionResult._(
    isGranted: true,
    isDenied: false,
    isPermanentlyDenied: false,
    message: 'Permission granted successfully',
  );

  factory PermissionResult.denied() => PermissionResult._(
    isGranted: false,
    isDenied: true,
    isPermanentlyDenied: false,
    message: 'Permission denied. Voice features won\'t work without microphone access.',
  );

  factory PermissionResult.permanentlyDenied() => PermissionResult._(
    isGranted: false,
    isDenied: true,
    isPermanentlyDenied: true,
    message: 'Permission permanently denied. Please enable it in Settings.',
  );
}