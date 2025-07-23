import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:background_fetch/background_fetch.dart';

/// Service for managing recurring survey notifications
/// Implements a 2-week recurring notification system that prompts users to respond to surveys
class NotificationService {
  static const String _lastNotificationKey = 'last_survey_notification';
  static const String _notificationCountKey = 'survey_notification_count';
  static const String _notificationTaskId = 'com.wellbeingmapper.survey_notification';
  static const String _pendingSurveyKey = 'pending_survey_prompt';
  static const int _notificationIntervalDays = 14; // 2 weeks

  /// Initialize the notification service
  static Future<void> initialize() async {
    await _scheduleNotificationTask();
    print('[NotificationService] Initialized successfully');
  }

  /// Schedule the background task for checking notification timing
  static Future<void> _scheduleNotificationTask() async {
    try {
      // Schedule a recurring background task to check if notification should be shown
      await BackgroundFetch.scheduleTask(TaskConfig(
        taskId: _notificationTaskId,
        delay: 3600000, // Check every hour (in milliseconds)
        periodic: true,
        forceAlarmManager: true,
        stopOnTerminate: false,
        enableHeadless: true,
        requiredNetworkType: NetworkType.NONE,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ));
      
      print('[NotificationService] Scheduled notification task');
    } catch (error) {
      print('[NotificationService] Error scheduling task: $error');
    }
  }

  /// Check if it's time to show a survey notification
  static Future<void> checkNotificationTiming() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      final int? lastNotificationTimestamp = prefs.getInt(_lastNotificationKey);
      final DateTime now = DateTime.now();
      
      bool shouldShowNotification = false;
      
      if (lastNotificationTimestamp == null) {
        // First time - show notification after app has been used for at least a week
        final String? userUUID = prefs.getString("user_uuid");
        if (userUUID != null) {
          // User has been using the app, schedule first notification
          shouldShowNotification = true;
        }
      } else {
        final DateTime lastNotification = 
            DateTime.fromMillisecondsSinceEpoch(lastNotificationTimestamp);
        final Duration timeSinceLastNotification = now.difference(lastNotification);
        
        // Show notification if it's been 2 weeks or more
        if (timeSinceLastNotification.inDays >= _notificationIntervalDays) {
          shouldShowNotification = true;
        }
      }
      
      if (shouldShowNotification) {
        await _setPendingSurveyPrompt();
        await prefs.setInt(_lastNotificationKey, now.millisecondsSinceEpoch);
        
        // Increment notification count
        final int count = prefs.getInt(_notificationCountKey) ?? 0;
        await prefs.setInt(_notificationCountKey, count + 1);
        
        print('[NotificationService] Survey prompt scheduled. Count: ${count + 1}');
      }
    } catch (error) {
      print('[NotificationService] Error checking notification timing: $error');
    }
  }

  /// Set a flag that a survey prompt should be shown when the app opens
  static Future<void> _setPendingSurveyPrompt() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingSurveyKey, true);
    await prefs.setInt('${_pendingSurveyKey}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  /// Check if there's a pending survey prompt to show
  static Future<bool> hasPendingSurveyPrompt() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pendingSurveyKey) ?? false;
  }

  /// Clear the pending survey prompt flag
  static Future<void> clearPendingSurveyPrompt() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingSurveyKey);
    await prefs.remove('${_pendingSurveyKey}_timestamp');
  }

  /// Show survey prompt dialog
  static Future<void> showSurveyPromptDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Survey Participation'),
          content: const Text(
            'Help improve research by participating in our survey! '
            'Your contributions help scientists understand human mobility patterns.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Maybe Later'),
              onPressed: () {
                Navigator.of(context).pop();
                clearPendingSurveyPrompt();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Participate'),
              onPressed: () {
                Navigator.of(context).pop();
                clearPendingSurveyPrompt();
                // Navigate to survey
                _navigateToSurvey(context);
              },
            ),
          ],
        );
      },
    );
  }

  /// Navigate to the survey webview
  static void _navigateToSurvey(BuildContext context) {
    // Navigate to available projects or active projects page
    // This depends on the app's current state
    Navigator.of(context).pushNamed('/participate_in_a_project');
  }

  /// Get notification statistics
  static Future<Map<String, dynamic>> getNotificationStats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    final int? lastNotificationTimestamp = prefs.getInt(_lastNotificationKey);
    final int notificationCount = prefs.getInt(_notificationCountKey) ?? 0;
    final bool hasPending = prefs.getBool(_pendingSurveyKey) ?? false;
    
    DateTime? lastNotificationDate;
    DateTime? nextNotificationDate;
    
    if (lastNotificationTimestamp != null) {
      lastNotificationDate = DateTime.fromMillisecondsSinceEpoch(lastNotificationTimestamp);
      nextNotificationDate = lastNotificationDate.add(Duration(days: _notificationIntervalDays));
    }
    
    return {
      'notificationCount': notificationCount,
      'lastNotificationDate': lastNotificationDate,
      'nextNotificationDate': nextNotificationDate,
      'intervalDays': _notificationIntervalDays,
      'hasPendingPrompt': hasPending,
    };
  }

  /// Reset notification schedule (for testing or user preference)
  static Future<void> resetNotificationSchedule() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastNotificationKey);
    await prefs.remove(_notificationCountKey);
    await prefs.remove(_pendingSurveyKey);
    await prefs.remove('${_pendingSurveyKey}_timestamp');
    print('[NotificationService] Notification schedule reset');
  }

  /// Cancel all scheduled notifications
  static Future<void> cancelAllNotifications() async {
    await BackgroundFetch.stop(_notificationTaskId);
    await resetNotificationSchedule();
    print('[NotificationService] All notifications cancelled');
  }

  /// Enable notifications (for user preference)
  static Future<void> enableNotifications() async {
    await _scheduleNotificationTask();
    print('[NotificationService] Notifications enabled');
  }

  /// Disable notifications (for user preference)
  static Future<void> disableNotifications() async {
    await cancelAllNotifications();
    print('[NotificationService] Notifications disabled');
  }
}

/// Headless task handler for notification checking
/// This runs in the background even when the app is terminated
Future<void> notificationHeadlessTask(String taskId) async {
  print('[NotificationService] Headless task executed: $taskId');
  
  if (taskId == NotificationService._notificationTaskId) {
    await NotificationService.checkNotificationTiming();
  }
  
  BackgroundFetch.finish(taskId);
}
