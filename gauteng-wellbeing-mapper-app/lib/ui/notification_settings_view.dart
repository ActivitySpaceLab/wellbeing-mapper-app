import 'package:flutter/material.dart';
import 'dart:io';
import '../services/notification_service.dart';
import '../services/app_mode_service.dart';

/// Screen for managing notification settings and viewing notification statistics
class NotificationSettingsView extends StatefulWidget {
  @override
  _NotificationSettingsViewState createState() => _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView> {
  Map<String, dynamic> _notificationStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationStats();
  }

  Future<void> _loadNotificationStats() async {
    try {
      final stats = await NotificationService.getNotificationStats();
      setState(() {
        _notificationStats = stats;
        _isLoading = false;
      });
    } catch (error) {
      print('Error loading notification stats: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Never';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatNextNotification(DateTime? nextDate) {
    if (nextDate == null) return 'Not scheduled';
    final now = DateTime.now();
    final difference = nextDate.difference(now);
    
    if (difference.isNegative) {
      return 'Overdue';
    } else if (difference.inDays > 0) {
      return 'In ${difference.inDays} days';
    } else if (difference.inHours > 0) {
      return 'In ${difference.inHours} hours';
    } else {
      return 'Soon';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Survey Notifications',
            style: TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        backgroundColor: Colors.blueGrey,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  SizedBox(height: 20),
                  _buildStatsCard(),
                  SizedBox(height: 20),
                  _buildActionsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'About Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Wellbeing Mapper automatically reminds you to participate in surveys every 2 weeks. '
              'These surveys help researchers understand human mobility patterns and improve the app.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(height: 8),
            Text(
              'The app uses both device notifications and in-app dialogs to ensure you don\'t miss survey opportunities. '
              'Device notifications work even when the app is closed.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone_android, size: 16, color: Colors.green),
                SizedBox(width: 4),
                Text('Device notifications', style: TextStyle(fontSize: 12, color: Colors.green[700])),
                SizedBox(width: 16),
                Icon(Icons.chat_bubble, size: 16, color: Colors.blue),
                SizedBox(width: 4),
                Text('In-app dialogs', style: TextStyle(fontSize: 12, color: Colors.blue[700])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final notificationCount = _notificationStats['notificationCount'] ?? 0;
    final lastNotificationDate = _notificationStats['lastNotificationDate'] as DateTime?;
    final nextNotificationDate = _notificationStats['nextNotificationDate'] as DateTime?;
    final hasPendingPrompt = _notificationStats['hasPendingPrompt'] ?? false;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Notification Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildStatRow('Total Notifications', notificationCount.toString()),
            _buildStatRow('Last Notification', _formatDate(lastNotificationDate)),
            _buildStatRow('Next Notification', _formatNextNotification(nextNotificationDate)),
            _buildStatRow('Pending Prompt', hasPendingPrompt ? 'Yes' : 'No'),
            _buildStatRow('Notification Interval', '14 days'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings_outlined, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Testing Tools - Only show in beta builds
            if (AppModeService.isBetaBuild) ...[
              Text(
                'Testing Tools',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.phone_android),
                  label: Text('Test Device Notification'),
                  onPressed: () => _testDeviceNotification(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              // iOS-specific simple test
              if (Platform.isIOS) ...[
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.phone_iphone),
                    label: Text('Test Simple iOS Notification'),
                    onPressed: () => _testSimpleIOSNotification(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.bolt),
                    label: Text('Test Immediate iOS Notification'),
                    onPressed: () => _testImmediateIOSNotification(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.chat_bubble),
                  label: Text('Test In-App Notification'),
                  onPressed: () => _testInAppNotification(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.security),
                  label: Text('Check Notification Permissions'),
                  onPressed: () => _checkPermissions(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
            
            // Testing Interval Configuration - Only show in beta builds
            if (AppModeService.isBetaBuild) ...[
              Text(
                'Testing Configuration',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              if (_notificationStats['isTestingMode'] == true) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'TESTING MODE ACTIVE',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Notifications set to ${_notificationStats['testingIntervalMinutes']} minute interval',
                        style: TextStyle(color: Colors.orange.shade700),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.schedule),
                  label: Text(_notificationStats['isTestingMode'] == true 
                      ? 'Change Testing Interval' 
                      : 'Set Testing Interval'),
                  onPressed: () => _showTestingIntervalDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _notificationStats['isTestingMode'] == true 
                        ? Colors.orange : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              if (_notificationStats['isTestingMode'] == true) ...[
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.restore),
                    label: Text('Revert to Production (14 days)'),
                    onPressed: () => _clearTestingInterval(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
              SizedBox(height: 16),
            ],
            
            // Management Buttons
            Text(
              'Management',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.restore),
                label: Text('Reset Notification Schedule'),
                onPressed: () => _resetNotificationSchedule(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.cancel),
                label: Text('Disable Notifications'),
                onPressed: () => _disableNotifications(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Testing Interval Configuration
            Text(
              'Testing Configuration',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            if (_notificationStats['isTestingMode'] == true) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'TESTING MODE ACTIVE',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Notifications set to ${_notificationStats['testingIntervalMinutes']} minute interval',
                      style: TextStyle(color: Colors.orange.shade700),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.schedule),
                label: Text(_notificationStats['isTestingMode'] == true 
                    ? 'Change Testing Interval' 
                    : 'Set Testing Interval'),
                onPressed: () => _showTestingIntervalDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _notificationStats['isTestingMode'] == true 
                      ? Colors.orange : Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            if (_notificationStats['isTestingMode'] == true) ...[
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.restore),
                  label: Text('Revert to Production (14 days)'),
                  onPressed: () => _clearTestingInterval(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _resetNotificationSchedule() async {
    final confirmed = await _showConfirmDialog(
      'Reset Notification Schedule',
      'This will reset your notification schedule and statistics. Are you sure?',
    );

    if (confirmed) {
      try {
        await NotificationService.resetNotificationSchedule();
        _showSnackBar('Notification schedule reset');
        _loadNotificationStats();
      } catch (error) {
        _showSnackBar('Error resetting notification schedule: $error');
      }
    }
  }

  Future<void> _testDeviceNotification() async {
    try {
      print('[UI] Testing device notification...');
      await NotificationService.testDeviceNotification();
      
      // Platform-specific success messages
      if (Platform.isIOS) {
        _showSnackBar('iOS notification scheduled for 5 seconds! Minimize the app now, then tap the notification to test navigation to survey.');
      } else {
        _showSnackBar('Device notification sent! Tap the notification to test navigation to survey.');
      }
    } catch (error) {
      print('[UI] Error testing device notification: $error');
      
      // Show detailed error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Notification Test Failed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('The device notification test failed with error:'),
                SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
                SizedBox(height: 12),
                Text('Troubleshooting steps:'),
                Text('1. Check notification permissions'),
                Text('2. Restart the app'),
                if (Platform.isIOS)
                  Text('3. Check iOS Settings → Notifications → Wellbeing Mapper'),
                if (Platform.isAndroid)
                  Text('3. Check Android Settings → Apps → Wellbeing Mapper → Notifications'),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _testInAppNotification() async {
    try {
      await NotificationService.testInAppNotification(context);
      _showSnackBar('In-app notification shown');
    } catch (error) {
      _showSnackBar('Error showing in-app notification: $error');
    }
  }

  Future<void> _testSimpleIOSNotification() async {
    try {
      print('[UI] Testing simple iOS notification...');
      await NotificationService.testSimpleIOSNotification();
      _showSnackBar('iOS notification scheduled for 5 seconds! Minimize the app now to see it appear.');
    } catch (error) {
      print('[UI] Error testing simple iOS notification: $error');
      
      // Show detailed error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Simple iOS Notification Test Failed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('The simple iOS notification test failed:'),
                SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
                SizedBox(height: 12),
                Text('This test schedules a notification and tries immediate fallback.'),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _testImmediateIOSNotification() async {
    try {
      print('[UI] Testing immediate iOS notification...');
      await NotificationService.testImmediateIOSNotification();
      _showSnackBar('Immediate iOS notification sent! It should appear right away for debugging tap handler.');
    } catch (error) {
      print('[UI] Error testing immediate iOS notification: $error');
      
      // Show detailed error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Immediate iOS Notification Test Failed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('The immediate iOS notification test failed:'),
                SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
                SizedBox(height: 12),
                Text('This test sends an immediate notification to test tap handling.'),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _checkPermissions() async {
    try {
      final hasPermissions = await NotificationService.checkNotificationPermissions();
      final diagnostics = await NotificationService.getDiagnostics();
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Notification Permissions'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Device Notifications: ${hasPermissions ? "✅ Enabled" : "❌ Disabled"}'),
                SizedBox(height: 8),
                Text('Platform: ${diagnostics['systemInfo']['platform']}'),
                SizedBox(height: 8),
                Text('System Initialized: ${diagnostics['notificationSystemInitialized'] ? "✅" : "❌"}'),
                SizedBox(height: 8),
                if (!hasPermissions)
                  Text(
                    'Please enable notifications in your device settings for the best research experience.',
                    style: TextStyle(color: Colors.orange[700]),
                  ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    } catch (error) {
      _showSnackBar('Error checking permissions: $error');
    }
  }

  Future<void> _disableNotifications() async {
    final confirmed = await _showConfirmDialog(
      'Disable Notifications',
      'This will disable all survey notifications. You can re-enable them later. Are you sure?',
    );

    if (confirmed) {
      try {
        await NotificationService.disableNotifications();
        _showSnackBar('Notifications disabled');
        _loadNotificationStats();
      } catch (error) {
        _showSnackBar('Error disabling notifications: $error');
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Show dialog to set testing interval
  Future<void> _showTestingIntervalDialog() async {
    final TextEditingController controller = TextEditingController();
    final currentInterval = _notificationStats['testingIntervalMinutes'];
    if (currentInterval != null) {
      controller.text = currentInterval.toString();
    }

    final result = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Set Testing Interval'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Set notification interval for testing purposes:'),
                  SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Minutes',
                      hintText: 'e.g., 1 for 1 minute',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Common testing intervals:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildQuickIntervalChip(controller, 1, '1 min'),
                      _buildQuickIntervalChip(controller, 5, '5 min'),
                      _buildQuickIntervalChip(controller, 15, '15 min'),
                      _buildQuickIntervalChip(controller, 60, '1 hour'),
                    ],
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      'Production interval is 14 days (20,160 minutes). Testing mode allows you to test notifications much faster.',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final minutes = int.tryParse(controller.text);
                if (minutes != null && minutes > 0) {
                  Navigator.of(context).pop(minutes);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid number of minutes')),
                  );
                }
              },
              child: Text('Set Interval'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      try {
        await NotificationService.setTestingInterval(result);
        _showSnackBar('Testing interval set to $result minutes');
        _loadNotificationStats();
      } catch (error) {
        _showSnackBar('Error setting testing interval: $error');
      }
    }
  }

  Widget _buildQuickIntervalChip(TextEditingController controller, int minutes, String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        controller.text = minutes.toString();
      },
      backgroundColor: Colors.blue.shade100,
    );
  }

  /// Clear testing interval and revert to production
  Future<void> _clearTestingInterval() async {
    final confirmed = await _showConfirmDialog(
      'Revert to Production Interval',
      'This will change the notification interval back to 14 days (production setting). Are you sure?',
    );

    if (confirmed) {
      try {
        await NotificationService.clearTestingInterval();
        _showSnackBar('Reverted to production interval (14 days)');
        _loadNotificationStats();
      } catch (error) {
        _showSnackBar('Error reverting to production interval: $error');
      }
    }
  }
}
