import 'package:flutter/material.dart';
import '../services/notification_service.dart';

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
                  'About Survey Notifications',
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
              'When a notification is due, you\'ll see a dialog when you open the app asking if you\'d like to participate.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.refresh),
                label: Text('Trigger Survey Prompt Now'),
                onPressed: () => _triggerSurveyPrompt(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 12),
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
            SizedBox(height: 12),
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
          ],
        ),
      ),
    );
  }

  Future<void> _triggerSurveyPrompt() async {
    try {
      await NotificationService.showSurveyPromptDialog(context);
      _showSnackBar('Survey prompt triggered');
    } catch (error) {
      _showSnackBar('Error triggering survey prompt: $error');
    }
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
}
