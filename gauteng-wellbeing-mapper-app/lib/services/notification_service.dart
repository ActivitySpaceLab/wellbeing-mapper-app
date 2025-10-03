import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../main.dart' show navigatorKey;
import 'app_mode_service.dart';

/// Service for managing recurring survey notifications
/// Implements a 2-week recurring notification system that prompts users to respond to surveys
/// Now includes both in-app dialogs and device-level notifications for robustness
class NotificationService {
  static const String _lastNotificationKey = 'last_survey_notification';
  static const String _notificationCountKey = 'survey_notification_count';
  static const String _nextNotificationDateKey = 'next_notification_date'; // Persist next date
  static const String _notificationTaskId = 'com.wellbeingmapper.survey_notification';
  static const String _pendingSurveyKey = 'pending_survey_prompt';
  static const String _testingIntervalKey = 'testing_notification_interval_minutes';
  static const int _notificationIntervalDays = 14; // 2 weeks - default for production
  
  // Device notification settings
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _notificationsInitialized = false;
  static String? _pendingNotificationPayload;

  /// Initialize the notification service
  static Future<void> initialize() async {
    // Initialize timezone data
    try {
      tz_data.initializeTimeZones();
    } catch (e) {
      print('[NotificationService] Error initializing timezones: $e');
    }
    
    // Check if app was launched from a notification
    await _checkAppLaunchFromNotification();
    
    await _initializeLocalNotifications();
    await _scheduleNotificationTask();
    print('[NotificationService] Initialized successfully with device notifications');
  }

  /// Check if the app was launched from a notification
  static Future<void> _checkAppLaunchFromNotification() async {
    try {
      print('[NotificationService] ===== CHECKING APP LAUNCH FROM NOTIFICATION =====');
      final NotificationAppLaunchDetails? notificationAppLaunchDetails =
          await _localNotifications.getNotificationAppLaunchDetails();
      
      print('[NotificationService] Launch details available: ${notificationAppLaunchDetails != null}');
      
      if (notificationAppLaunchDetails?.didNotificationLaunchApp == true) {
        _pendingNotificationPayload = notificationAppLaunchDetails!.notificationResponse?.payload;
        print('[NotificationService] App WAS launched from notification');
        print('[NotificationService] Notification response: ${notificationAppLaunchDetails.notificationResponse}');
        print('[NotificationService] Payload: $_pendingNotificationPayload');
      } else {
        print('[NotificationService] App was NOT launched from notification');
      }
      print('[NotificationService] ===== END LAUNCH CHECK =====');
    } catch (e) {
      print('[NotificationService] Error checking app launch details: $e');
    }
  }

  /// Get pending notification payload and clear it
  static String? getPendingNotificationPayload() {
    print('[NotificationService] Getting pending payload: $_pendingNotificationPayload');
    final payload = _pendingNotificationPayload;
    _pendingNotificationPayload = null;
    return payload;
  }

  /// Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    if (_notificationsInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
          defaultPresentAlert: true,
          defaultPresentSound: true,
          defaultPresentBadge: true,
          notificationCategories: [
            DarwinNotificationCategory(
              'survey_reminder_category',
              actions: <DarwinNotificationAction>[
                DarwinNotificationAction.plain(
                  'open_survey',
                  'Open Survey',
                  options: <DarwinNotificationActionOption>{
                    DarwinNotificationActionOption.foreground,
                  },
                ),
              ],
              options: <DarwinNotificationCategoryOption>{
                DarwinNotificationCategoryOption.allowInCarPlay,
              },
            ),
            DarwinNotificationCategory(
              'survey_test_category',
              actions: <DarwinNotificationAction>[
                DarwinNotificationAction.plain(
                  'open_survey_test',
                  'Open Survey Test',
                  options: <DarwinNotificationActionOption>{
                    DarwinNotificationActionOption.foreground,
                  },
                ),
              ],
              options: <DarwinNotificationCategoryOption>{
                DarwinNotificationCategoryOption.allowInCarPlay,
              },
            ),
          ],
        );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    bool initialized = await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
    ) ?? false;

    if (initialized) {
      _notificationsInitialized = true;
      print('[NotificationService] Local notifications initialized successfully');
      
      // Create Android notification channel
      if (Platform.isAndroid) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'wellbeing_survey_channel',
          'Wellbeing Survey Notifications',
          description: 'Notifications for wellbeing survey reminders',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        );
        
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            _localNotifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidPlugin != null) {
          await androidPlugin.createNotificationChannel(channel);
          print('[NotificationService] Android notification channel created');
          
          // Request notification permissions for Android 13+
          final bool? permissionGranted = await androidPlugin.requestNotificationsPermission();
          print('[NotificationService] Android notification permission granted: $permissionGranted');
        }
      }
      
      // Request permissions explicitly on iOS
      if (Platform.isIOS) {
        final bool? permissionGranted = await _localNotifications
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
              critical: false,
            );
        print('[NotificationService] iOS permission granted: $permissionGranted');
      }
    } else {
      print('[NotificationService] Failed to initialize local notifications');
    }
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    print('[NotificationService] ===== NOTIFICATION TAPPED =====');
    print('[NotificationService] Payload: ${response.payload}');
    print('[NotificationService] Notification ID: ${response.id}');
    print('[NotificationService] Action ID: ${response.actionId}');
    
    _handleNotificationNavigation(response);
    print('[NotificationService] ===== END NOTIFICATION TAP =====');
  }

  /// Handle background notification tap (when app is not running)
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    print('[NotificationService] ===== BACKGROUND NOTIFICATION TAPPED =====');
    print('[NotificationService] Payload: ${response.payload}');
    print('[NotificationService] Notification ID: ${response.id}');
    print('[NotificationService] Action ID: ${response.actionId}');
    
    // Store the payload for when the app starts up
    _pendingNotificationPayload = response.payload;
    print('[NotificationService] Stored payload for app startup: ${response.payload}');
    print('[NotificationService] ===== END BACKGROUND NOTIFICATION TAP =====');
  }

  /// Common navigation handling for both foreground and background taps
  static void _handleNotificationNavigation(NotificationResponse response) {
    // Navigate to the wellbeing survey when notification is tapped
    try {
      final NavigatorState? navigator = navigatorKey.currentState;
      print('[NotificationService] Navigator available: ${navigator != null}');
      print('[NotificationService] Payload matches survey route: ${response.payload == '/wellbeing_survey'}');
      
      if (navigator != null && response.payload == '/wellbeing_survey') {
        print('[NotificationService] Attempting navigation to wellbeing survey...');
        
        // First try a simple push - this works better when app is already open
        try {
          navigator.pushNamed('/wellbeing_survey');
          print('[NotificationService] Simple navigation command sent successfully');
        } catch (e) {
          print('[NotificationService] Simple navigation failed, trying pushNamedAndRemoveUntil: $e');
          // If simple push fails, try the more aggressive approach
          navigator.pushNamedAndRemoveUntil(
            '/wellbeing_survey',
            (route) => route.isFirst, // Keep only the first route (home/initial)
          );
          print('[NotificationService] Aggressive navigation command sent');
        }
      } else {
        print('[NotificationService] Navigation conditions not met');
        if (navigator == null) {
          print('[NotificationService] - Navigator is null');
        }
        if (response.payload != '/wellbeing_survey') {
          print('[NotificationService] - Payload mismatch: expected "/wellbeing_survey", got "${response.payload}"');
        }
        print('[NotificationService] Setting pending survey prompt as fallback');
        // If navigation is not available, set a pending prompt flag
        _setPendingSurveyPrompt();
      }
    } catch (e) {
      print('[NotificationService] Error in notification tap handler: $e');
      print('[NotificationService] Stack trace: ${StackTrace.current}');
      // Fallback: set pending prompt
      _setPendingSurveyPrompt();
    }
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
      
      final int? nextNotificationTimestamp = prefs.getInt(_nextNotificationDateKey);
      final DateTime now = DateTime.now();
      
      bool shouldShowNotification = false;
      
      if (nextNotificationTimestamp != null) {
        final DateTime nextNotificationDate = DateTime.fromMillisecondsSinceEpoch(nextNotificationTimestamp);
        
        // Show notification if we've reached or passed the scheduled time
        if (now.isAfter(nextNotificationDate) || now.isAtSameMomentAs(nextNotificationDate)) {
          shouldShowNotification = true;
        }
      } else {
        // No next notification date set - check if we should initialize one based on consent
        final String? consentTimestampStr = prefs.getString('consent_timestamp');
        if (consentTimestampStr != null) {
          try {
            final DateTime consentDate = DateTime.parse(consentTimestampStr);
            final Duration effectiveInterval = await getEffectiveNotificationInterval();
            final DateTime nextNotificationDate = _calculateNextNotificationFromConsent(consentDate, effectiveInterval);
            await prefs.setInt(_nextNotificationDateKey, nextNotificationDate.millisecondsSinceEpoch);
            print('[NotificationService] Initialized notification schedule from consent date for existing user');
          } catch (e) {
            print('[NotificationService] Error parsing consent timestamp: $e');
          }
        }
      }
      
      if (shouldShowNotification) {
        await _setPendingSurveyPrompt();
        await prefs.setInt(_lastNotificationKey, now.millisecondsSinceEpoch);
        
        // Calculate and set the NEXT notification date based on consent date
        final String? consentTimestampStr = prefs.getString('consent_timestamp');
        final Duration effectiveInterval = await getEffectiveNotificationInterval();
        DateTime nextNotificationDate;
        
        if (consentTimestampStr != null) {
          try {
            final DateTime consentDate = DateTime.parse(consentTimestampStr);
            nextNotificationDate = _calculateNextNotificationFromConsent(consentDate, effectiveInterval);
          } catch (e) {
            print('[NotificationService] Error parsing consent timestamp for next notification: $e');
            nextNotificationDate = now.add(effectiveInterval);
          }
        } else {
          nextNotificationDate = now.add(effectiveInterval);
        }
        await prefs.setInt(_nextNotificationDateKey, nextNotificationDate.millisecondsSinceEpoch);
        
        // Increment notification count
        final int count = prefs.getInt(_notificationCountKey) ?? 0;
        await prefs.setInt(_notificationCountKey, count + 1);
        
        print('[NotificationService] Survey prompt scheduled. Count: ${count + 1}');
        print('[NotificationService] Next notification scheduled for: $nextNotificationDate');
      }
    } catch (error) {
      print('[NotificationService] Error checking notification timing: $error');
    }
  }

  /// Set a flag that a survey prompt should be shown when the app opens
  /// Also shows a device notification for better visibility
  static Future<void> _setPendingSurveyPrompt() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingSurveyKey, true);
    await prefs.setInt('${_pendingSurveyKey}_timestamp', DateTime.now().millisecondsSinceEpoch);
    
    // Show device notification for better visibility
    await _showDeviceNotification();
  }

  /// Show a device-level notification
  static Future<void> _showDeviceNotification() async {
    try {
      print('[NotificationService] Preparing to show device notification...');
      await _initializeLocalNotifications();
      
      if (!_notificationsInitialized) {
        throw Exception('Notifications not initialized');
      }
      
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'wellbeing_survey_channel',
            'Wellbeing Survey Notifications',
            channelDescription: 'Notifications for wellbeing survey reminders',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            icon: '@mipmap/launcher_icon',
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            badgeNumber: 1,
            threadIdentifier: 'survey_reminder',
            categoryIdentifier: 'survey_reminder_category',
            interruptionLevel: InterruptionLevel.active,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      print('[NotificationService] Showing notification with ID: $notificationId');
      
      await _localNotifications.show(
        notificationId,
        'Wellbeing Survey Reminder',
        'Help researchers by participating in your biweekly wellbeing survey! Tap to contribute to important research.',
        platformChannelSpecifics,
        payload: '/wellbeing_survey',
      );
      
      print('[NotificationService] Device notification shown successfully with ID: $notificationId');
      
      // Additional check - get pending notifications to verify it was scheduled
      final pendingNotifications = await _localNotifications.pendingNotificationRequests();
      print('[NotificationService] Pending notifications count: ${pendingNotifications.length}');
      
    } catch (error) {
      print('[NotificationService] Error showing device notification: $error');
      print('[NotificationService] Error details: ${error.toString()}');
      rethrow; // Re-throw so the UI can show the error
    }
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
    // Navigate to the biweekly wellbeing survey screen
    Navigator.of(context).pushNamed('/wellbeing_survey');
  }

  /// Get notification statistics
  static Future<Map<String, dynamic>> getNotificationStats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    final int? lastNotificationTimestamp = prefs.getInt(_lastNotificationKey);
    final int? nextNotificationTimestamp = prefs.getInt(_nextNotificationDateKey);
    final int notificationCount = prefs.getInt(_notificationCountKey) ?? 0;
    final bool hasPending = prefs.getBool(_pendingSurveyKey) ?? false;
    final int? testingMinutes = await getTestingInterval();
    
    // Get consent timestamp as the baseline
    final String? consentTimestampStr = prefs.getString('consent_timestamp');
    DateTime? consentDate;
    DateTime? lastNotificationDate;
    DateTime? nextNotificationDate;
    Duration effectiveInterval = await getEffectiveNotificationInterval();
    
    if (consentTimestampStr != null) {
      try {
        consentDate = DateTime.parse(consentTimestampStr);
      } catch (e) {
        print('[NotificationService] Error parsing consent timestamp: $e');
      }
    }
    
    // Calculate next notification date based on consent date + 14-day intervals
    if (nextNotificationTimestamp != null) {
      // Use persisted next notification date
      nextNotificationDate = DateTime.fromMillisecondsSinceEpoch(nextNotificationTimestamp);
    } else if (consentDate != null) {
      // Calculate next notification based on consent date + 14-day intervals
      nextNotificationDate = _calculateNextNotificationFromConsent(consentDate, effectiveInterval);
      await prefs.setInt(_nextNotificationDateKey, nextNotificationDate.millisecondsSinceEpoch);
      print('[NotificationService] Calculated next notification from consent date: $nextNotificationDate');
    }
    
    if (lastNotificationTimestamp != null) {
      lastNotificationDate = DateTime.fromMillisecondsSinceEpoch(lastNotificationTimestamp);
    }
    
    return {
      'notificationCount': notificationCount,
      'lastNotificationDate': lastNotificationDate,
      'nextNotificationDate': nextNotificationDate,
      'consentDate': consentDate,
      'intervalDays': _notificationIntervalDays,
      'hasPendingPrompt': hasPending,
      'testingIntervalMinutes': testingMinutes,
      'effectiveInterval': effectiveInterval,
      'isTestingMode': testingMinutes != null,
    };
  }

  /// Calculate the next notification date based on consent date + 14-day intervals
  static DateTime _calculateNextNotificationFromConsent(DateTime consentDate, Duration interval) {
    final now = DateTime.now();
    
    // Start from consent date
    DateTime nextDate = consentDate.add(interval);
    
    // Keep adding intervals until we find the next future date
    while (nextDate.isBefore(now) || nextDate.isAtSameMomentAs(now)) {
      nextDate = nextDate.add(interval);
    }
    
    print('[NotificationService] Calculated next notification from consent date $consentDate: $nextDate');
    return nextDate;
  }

  /// Reset notification schedule (for testing or user preference)
  static Future<void> resetNotificationSchedule() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastNotificationKey);
    await prefs.remove(_notificationCountKey);
    await prefs.remove(_nextNotificationDateKey);
    await prefs.remove(_pendingSurveyKey);
    await prefs.remove('${_pendingSurveyKey}_timestamp');
    print('[NotificationService] Notification schedule reset - will recalculate from consent date');
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

  // === TESTING INTERVAL CONFIGURATION ===
  
  /// Set custom testing interval in minutes (for development/testing)
  /// Only available in beta builds
  static Future<void> setTestingInterval(int minutes) async {
    // Prevent testing intervals in production builds
    if (AppModeService.isProductionBuild) {
      print('[NotificationService] Testing intervals are not available in production builds');
      return;
    }
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_testingIntervalKey, minutes);
    print('[NotificationService] Testing interval set to $minutes minutes');
    
    // Clear the last notification timestamp to ensure immediate testing
    await prefs.remove(_lastNotificationKey);
    print('[NotificationService] Cleared last notification timestamp for testing');
    
    // For testing mode, schedule a direct notification instead of relying only on background task
    await _scheduleDirectTestingNotification(minutes);
    
    // Also reschedule background task with more frequent checks for testing
    await _rescheduleBackgroundTaskForTesting(minutes);
    
    // Also manually trigger a check immediately
    await checkNotificationTiming();
  }

  /// Schedule a direct notification for testing (bypasses background task delays)
  static Future<void> _scheduleDirectTestingNotification(int minutes) async {
    try {
      print('[NotificationService] Scheduling direct testing notification in $minutes minutes');
      
      // Cancel any existing testing notifications first
      await _localNotifications.cancel(999);
      
      final tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(minutes: minutes));
      
      // For very short intervals, schedule multiple notifications to ensure reliability
      if (minutes <= 5) {
        // Schedule several notifications at the interval for rapid testing
        for (int i = 1; i <= 5; i++) {
          final nextNotificationTime = tz.TZDateTime.now(tz.local).add(Duration(minutes: minutes * i));
          
          await _localNotifications.zonedSchedule(
            999 + i, // Use unique IDs for each notification
            'Wellbeing Survey Reminder - Testing',
            'Time for your wellbeing survey! (Testing Mode - #$i)',
            nextNotificationTime,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'survey_reminders',
                'Survey Reminders',
                channelDescription: 'Reminders to complete wellbeing surveys',
                importance: Importance.high,
                priority: Priority.high,
                showWhen: true,
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
                interruptionLevel: InterruptionLevel.active,
              ),
            ),
            payload: '/wellbeing_survey', // Add the payload for proper navigation
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
          
          print('[NotificationService] Scheduled testing notification #$i for: $nextNotificationTime');
        }
      } else {
        // For longer intervals, schedule just one
        await _localNotifications.zonedSchedule(
          999, // Use ID 999 for testing notifications
          'Wellbeing Survey Reminder - Testing',
          'Time for your wellbeing survey! (Testing Mode)',
          scheduledDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'survey_reminders',
              'Survey Reminders',
              channelDescription: 'Reminders to complete wellbeing surveys',
              importance: Importance.high,
              priority: Priority.high,
              showWhen: true,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              interruptionLevel: InterruptionLevel.active,
            ),
          ),
          payload: '/wellbeing_survey', // Add the payload for proper navigation
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        
        print('[NotificationService] Direct testing notification scheduled for: $scheduledDate');
      }
    } catch (error) {
      print('[NotificationService] Error scheduling direct testing notification: $error');
    }
  }

  /// Get current testing interval in minutes (null if using production interval)
  /// Returns null in production builds to force production intervals
  static Future<int?> getTestingInterval() async {
    // Always return null for production builds - force production intervals
    if (AppModeService.isProductionBuild) {
      return null;
    }
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_testingIntervalKey);
  }

  /// Clear testing interval (revert to production 14-day interval)
  /// Only available in beta builds
  static Future<void> clearTestingInterval() async {
    // Only allow clearing in beta builds
    if (AppModeService.isProductionBuild) {
      print('[NotificationService] Testing interval clearing is not available in production builds');
      return;
    }
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_testingIntervalKey);
    print('[NotificationService] Reverted to production interval (14 days)');
    
    // Cancel any scheduled testing notifications (IDs 999-1004)
    for (int i = 999; i <= 1004; i++) {
      await _localNotifications.cancel(i);
    }
    print('[NotificationService] Cancelled all testing notifications');
    
    // Reschedule background task back to normal frequency
    await _scheduleNotificationTask();
  }

  /// Reschedule background task with more frequent checks for testing
  static Future<void> _rescheduleBackgroundTaskForTesting(int testingMinutes) async {
    try {
      // Stop the current background task
      await BackgroundFetch.stop(_notificationTaskId);
      
      // Calculate check frequency: check twice as often as the notification interval
      // but at least every 30 seconds for very short intervals
      int checkIntervalSeconds = (testingMinutes * 60) ~/ 2;
      if (checkIntervalSeconds < 30) {
        checkIntervalSeconds = 30; // Minimum 30 seconds
      }
      
      print('[NotificationService] Rescheduling background task for testing: check every ${checkIntervalSeconds}s for ${testingMinutes}min interval');
      
      // Schedule more frequent background task for testing
      await BackgroundFetch.scheduleTask(TaskConfig(
        taskId: _notificationTaskId,
        delay: checkIntervalSeconds * 1000, // Convert to milliseconds
        periodic: true,
        forceAlarmManager: true,
        enableHeadless: true,
        startOnBoot: true,
        requiredNetworkType: NetworkType.NONE,
      ));
      
      print('[NotificationService] Rescheduled notification task for testing');
    } catch (error) {
      print('[NotificationService] Error rescheduling task for testing: $error');
    }
  }

  /// Get the effective notification interval (either testing or production)
  static Future<Duration> getEffectiveNotificationInterval() async {
    final testingMinutes = await getTestingInterval();
    if (testingMinutes != null) {
      return Duration(minutes: testingMinutes);
    }
    return Duration(days: _notificationIntervalDays);
  }

  /// Check for pending survey prompt and show it if needed
  static Future<bool> checkAndShowPendingSurveyPrompt(BuildContext context) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool hasPending = prefs.getBool(_pendingSurveyKey) ?? false;
      
      if (hasPending) {
        print('[NotificationService] Found pending survey prompt, showing dialog');
        
        // Clear the pending flag
        await prefs.remove(_pendingSurveyKey);
        await prefs.remove('${_pendingSurveyKey}_timestamp');
        
        // Show the survey prompt dialog
        await showSurveyPromptDialog(context);
        return true;
      }
      
      return false;
    } catch (error) {
      print('[NotificationService] Error checking pending survey prompt: $error');
      return false;
    }
  }

  // === TESTING METHODS FOR RESEARCH TEAM ===
  
  /// Test device notification immediately (for research team testing)
  static Future<void> testDeviceNotification() async {
    // Only allow testing notifications in beta builds
    if (AppModeService.isProductionBuild) {
      print('[NotificationService] Test device notifications are not available in production builds');
      return;
    }
    
    print('[NotificationService] Starting test device notification...');
    
    // Enhanced iOS-specific diagnostics
    if (Platform.isIOS) {
      print('[NotificationService] === iOS NOTIFICATION DEBUG START ===');
      
      // Check if the plugin is available
      final iosPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      print('[NotificationService] iOS plugin available: ${iosPlugin != null}');
      
      if (iosPlugin != null) {
        // Get detailed permission status BEFORE requesting
        final initialPermissionStatus = await iosPlugin.checkPermissions();
        print('[NotificationService] Initial iOS permissions: $initialPermissionStatus');
        print('[NotificationService] Initial isEnabled: ${initialPermissionStatus?.isEnabled}');
        
        // Try requesting permissions with explicit options
        print('[NotificationService] Requesting iOS permissions...');
        final newPermissions = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical: false,
        );
        print('[NotificationService] iOS permission request result: $newPermissions');
        
        // Check permissions again after request
        final finalPermissionStatus = await iosPlugin.checkPermissions();
        print('[NotificationService] Final iOS permissions: $finalPermissionStatus');
        print('[NotificationService] Final isEnabled: ${finalPermissionStatus?.isEnabled}');
      }
      print('[NotificationService] === iOS NOTIFICATION DEBUG END ===');
    }
    
    // First check if we have permissions
    final hasPermissions = await checkNotificationPermissions();
    print('[NotificationService] Has permissions: $hasPermissions');
    
    if (!hasPermissions) {
      print('[NotificationService] No permissions - cannot send notification');
      throw Exception('Notification permissions not granted. Please check device settings.');
    }
    
    // Ensure notifications are initialized
    await _initializeLocalNotifications();
    print('[NotificationService] Notifications initialized: $_notificationsInitialized');
    
    if (!_notificationsInitialized) {
      print('[NotificationService] Notifications not initialized - cannot send');
      throw Exception('Notification system not initialized');
    }
    
    // For iOS, schedule the notification for 5 seconds to avoid foreground suppression
    if (Platform.isIOS) {
      try {
        print('[NotificationService] iOS detected - scheduling notification for 5 seconds...');
        
        final scheduledDate = DateTime.now().add(Duration(seconds: 5));
        
        const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
          badgeNumber: 1,
          threadIdentifier: 'survey_reminder',
          categoryIdentifier: 'survey_reminder_category',
          interruptionLevel: InterruptionLevel.active,
        );
        
        const NotificationDetails platformChannelSpecifics = NotificationDetails(
          iOS: iosDetails,
        );
        
        final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        
        await _localNotifications.zonedSchedule(
          notificationId,
          'Wellbeing Survey Reminder',
          'Help researchers by participating in your biweekly wellbeing survey! Tap to contribute to important research.',
          tz.TZDateTime.from(scheduledDate, tz.local),
          platformChannelSpecifics,
          payload: '/wellbeing_survey',
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        
        print('[NotificationService] iOS notification scheduled for $scheduledDate with ID: $notificationId');
        
        // Check pending notifications
        final pendingRequests = await _localNotifications.pendingNotificationRequests();
        print('[NotificationService] Pending notifications after scheduling: ${pendingRequests.length}');
        
      } catch (e) {
        print('[NotificationService] Error scheduling iOS notification: $e');
        rethrow;
      }
    } else {
      // For Android, send immediately as it handles foreground notifications better
      try {
        print('[NotificationService] Android detected - sending immediate notification...');
        await _showDeviceNotification();
        print('[NotificationService] Android notification sent successfully');
      } catch (e) {
        print('[NotificationService] Error sending Android notification: $e');
        rethrow;
      }
    }
  }

  /// Test in-app dialog notification immediately (for research team testing)
  /// Only available in beta builds
  static Future<void> testInAppNotification(BuildContext context) async {
    // Only allow testing notifications in beta builds
    if (AppModeService.isProductionBuild) {
      print('[NotificationService] Test in-app notifications are not available in production builds');
      return;
    }
    
    await showSurveyPromptDialog(context);
    print('[NotificationService] Test in-app notification shown');
  }

  /// Test immediate iOS notification (for debugging tap handler)
  static Future<void> testImmediateIOSNotification() async {
    // Only allow testing notifications in beta builds
    if (AppModeService.isProductionBuild) {
      print('[NotificationService] Test immediate iOS notifications are not available in production builds');
      return;
    }
    
    print('[NotificationService] Starting immediate iOS notification test...');
    
    if (!Platform.isIOS) {
      throw Exception('This test is only for iOS');
    }
    
    // First check if we have permissions
    final hasPermissions = await checkNotificationPermissions();
    print('[NotificationService] Has permissions: $hasPermissions');
    
    if (!hasPermissions) {
      throw Exception('Notification permissions not granted');
    }
    
    // Ensure notifications are initialized
    await _initializeLocalNotifications();
    
    if (!_notificationsInitialized) {
      throw Exception('Notification system not initialized');
    }
    
    try {
      // Schedule notification for 3 seconds in the future
      // This gives time for user to background the app and ensures delivery
      final scheduledTime = tz.TZDateTime.now(tz.local).add(Duration(seconds: 3));
      
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        badgeNumber: 1,
        threadIdentifier: 'survey_test',
        categoryIdentifier: 'survey_test_category',
        interruptionLevel: InterruptionLevel.critical, // Force it to show
      );
      
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        iOS: iosDetails,
      );

      final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      await _localNotifications.zonedSchedule(
        notificationId,
        'TAP TEST - Survey Navigation',
        'Background the app now! This notification will appear in 3 seconds. Tap to test navigation to survey screen!',
        scheduledTime,
        platformChannelSpecifics,
        payload: '/wellbeing_survey',
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      
      print('[NotificationService] Scheduled iOS notification for 3 seconds with ID: $notificationId');
      print('[NotificationService] Payload set to: /wellbeing_survey');
      print('[NotificationService] IMPORTANT: Background the app NOW to see the notification!');
      
    } catch (e) {
      print('[NotificationService] Error sending immediate iOS notification: $e');
      rethrow;
    }
  }

  /// Test complete notification flow (device notification + in-app dialog setup)
  static Future<void> testCompleteNotificationFlow(BuildContext context) async {
    await _setPendingSurveyPrompt();
    // Also show the dialog immediately for testing
    await Future.delayed(Duration(seconds: 1));
    await showSurveyPromptDialog(context);
    print('[NotificationService] Complete notification flow tested');
  }

  /// Force reinitialize notifications (useful for iOS troubleshooting)
  static Future<void> forceReinitializeNotifications() async {
    print('[NotificationService] Force reinitializing notifications...');
    
    // Reset the initialization flag
    _notificationsInitialized = false;
    
    // Reinitialize
    await _initializeLocalNotifications();
    
    print('[NotificationService] Force reinitialization completed. Status: $_notificationsInitialized');
  }

  /// iOS-specific simple notification test
  /// Only available in beta builds
  static Future<void> testSimpleIOSNotification() async {
    // Only allow testing notifications in beta builds
    if (AppModeService.isProductionBuild) {
      print('[NotificationService] Test iOS notifications are not available in production builds');
      return;
    }
    
    if (!Platform.isIOS) {
      throw Exception('This test is only for iOS');
    }
    
    print('[NotificationService] Testing simple iOS notification...');
    
    // Force reinitialize first
    await forceReinitializeNotifications();
    
    // Get iOS plugin
    final iosPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    
    if (iosPlugin == null) {
      throw Exception('iOS notifications plugin not available');
    }
    
    // Check permissions one more time
    final permissions = await iosPlugin.checkPermissions();
    print('[NotificationService] iOS permissions before simple test: $permissions');
    
    if (permissions?.isEnabled != true) {
      // Try requesting permissions one more time
      final requested = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      print('[NotificationService] iOS permission request in simple test: $requested');
      
      if (requested != true) {
        throw Exception('iOS notifications not permitted. Please enable in iOS Settings > Notifications > Wellbeing Mapper');
      }
    }
    
    // Try scheduling a notification for 5 seconds in the future
    // This helps test if the issue is foreground vs background
    final scheduledDate = DateTime.now().add(Duration(seconds: 5));
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      threadIdentifier: 'scheduled_test',
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      iOS: iosDetails,
    );
    
    final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    try {
      print('[NotificationService] Scheduling iOS notification for ${scheduledDate.toString()}...');
      
      await _localNotifications.zonedSchedule(
        notificationId,
        'Scheduled Test',
        'This notification was scheduled for 5 seconds - minimize the app to see it!',
        tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails,
        payload: '/wellbeing_survey',
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      
      print('[NotificationService] Scheduled iOS notification with ID: $notificationId for $scheduledDate');
      
      // Check pending notifications
      final pendingRequests = await _localNotifications.pendingNotificationRequests();
      print('[NotificationService] Pending notifications after scheduling: ${pendingRequests.length}');
      
      if (pendingRequests.isNotEmpty) {
        for (var request in pendingRequests) {
          print('[NotificationService] Pending: ID=${request.id}, title=${request.title}');
        }
      }
      
    } catch (e) {
      print('[NotificationService] Error scheduling iOS notification: $e');
      
      // Fall back to immediate notification
      print('[NotificationService] Falling back to immediate notification...');
      await _localNotifications.show(
        notificationId + 1,
        'Immediate Test',
        'This is an immediate iOS notification test - minimize the app!',
        notificationDetails,
      );
      print('[NotificationService] Immediate iOS notification sent with ID: ${notificationId + 1}');
    }
  }

  /// Check notification permissions and request if needed
  static Future<bool> checkNotificationPermissions() async {
    try {
      await _initializeLocalNotifications();
      
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
            _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidPlugin == null) {
          print('[NotificationService] Android plugin not available');
          return false;
        }
        
        // Check if notifications are enabled
        final bool? enabled = await androidPlugin.areNotificationsEnabled();
        print('[NotificationService] Android notifications enabled: $enabled');
        
        if (enabled == false) {
          // Request notification permissions for Android 13+
          final bool? permissionGranted = await androidPlugin.requestNotificationsPermission();
          print('[NotificationService] Android permission request result: $permissionGranted');
          return permissionGranted ?? false;
        }
        
        return enabled ?? false;
      } else if (Platform.isIOS) {
        // Check current permission status
        final permissionStatus = await _localNotifications
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.checkPermissions();
        
        print('[NotificationService] iOS permission status: $permissionStatus');
        
        // Check if we have alert permissions (main requirement)
        bool hasPermissions = permissionStatus?.isEnabled == true;
        
        print('[NotificationService] iOS permissions enabled: $hasPermissions');
        
        // If we don't have permissions, request them
        if (!hasPermissions) {
          final bool? requestResult = await _localNotifications
              .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(
                alert: true,
                badge: true,
                sound: true,
              );
          print('[NotificationService] iOS permission request result: $requestResult');
          return requestResult ?? false;
        }
        
        return hasPermissions;
      }
      return true;
    } catch (error) {
      print('[NotificationService] Error checking notification permissions: $error');
      return false;
    }
  }

  /// Get detailed diagnostics for research team troubleshooting
  static Future<Map<String, dynamic>> getDiagnostics() async {
    final stats = await getNotificationStats();
    final permissions = await checkNotificationPermissions();
    
    Map<String, dynamic> diagnostics = {
      ...stats,
      'deviceNotificationsEnabled': permissions,
      'notificationSystemInitialized': _notificationsInitialized,
      'systemInfo': {
        'platform': Platform.isAndroid ? 'Android' : Platform.isIOS ? 'iOS' : 'Other',
        'currentTime': DateTime.now().toIso8601String(),
      }
    };
    
    // Add platform-specific diagnostics
    if (Platform.isIOS) {
      try {
        final iosPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        
        if (iosPlugin != null) {
          final permissionStatus = await iosPlugin.checkPermissions();
          diagnostics['iosPermissionDetails'] = {
            'isEnabled': permissionStatus?.isEnabled,
          };
        }
      } catch (e) {
        diagnostics['iosPermissionError'] = e.toString();
      }
    } else if (Platform.isAndroid) {
      try {
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidPlugin != null) {
          final enabled = await androidPlugin.areNotificationsEnabled();
          diagnostics['androidNotificationDetails'] = {
            'areNotificationsEnabled': enabled,
            'channelId': 'wellbeing_survey_channel',
          };
        }
      } catch (e) {
        diagnostics['androidPermissionError'] = e.toString();
      }
    }
    
    return diagnostics;
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
