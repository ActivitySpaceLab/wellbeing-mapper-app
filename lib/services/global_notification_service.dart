import 'package:flutter/material.dart';

/// Global notification service for showing messages across the app
class GlobalNotificationService {
  static final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = 
      GlobalKey<ScaffoldMessengerState>();
  
  /// Get the global scaffold messenger key
  static GlobalKey<ScaffoldMessengerState> get scaffoldMessengerKey => _scaffoldMessengerKey;
  
  /// Show success message
  static void showSuccess(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
      duration: Duration(seconds: 4),
    );
  }
  
  /// Show error message
  static void showError(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.red,
      icon: Icons.error,
      duration: Duration(seconds: 5),
    );
  }
  
  /// Show warning message
  static void showWarning(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.orange,
      icon: Icons.warning,
      duration: Duration(seconds: 4),
    );
  }
  
  /// Show info message
  static void showInfo(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.blue,
      icon: Icons.info,
      duration: Duration(seconds: 3),
    );
  }
  
  /// Internal method to show snack bar
  static void _showSnackBar({
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
  }) {
    final scaffoldMessenger = _scaffoldMessengerKey.currentState;
    if (scaffoldMessenger != null) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text(message, style: TextStyle(color: Colors.white))),
            ],
          ),
          backgroundColor: backgroundColor,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
    } else {
      // Fallback - print to console if no scaffold messenger available
      debugPrint('[GlobalNotification] $message');
    }
  }
}