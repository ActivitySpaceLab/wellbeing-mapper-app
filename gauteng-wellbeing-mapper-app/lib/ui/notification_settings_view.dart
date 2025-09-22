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

}
