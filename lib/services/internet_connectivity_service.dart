import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class InternetConnectivityService {
  /// Check if device has internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      // Try to reach a reliable host with a timeout
      final response = await http.get(
        Uri.parse('https://www.google.com'),
        headers: {'Cache-Control': 'no-cache'},
      ).timeout(Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      print('[Connectivity] Error checking internet connection: $e');
      return false;
    }
  }
  
  /// Show internet required dialog
  static void showInternetRequiredDialog(BuildContext context, {
    required String surveyType,
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('Internet Connection Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The $surveyType survey requires an internet connection to load from Qualtrics.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'Please connect to Wi-Fi or mobile data and try again.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Survey responses must be submitted directly to Qualtrics for research data collection.',
                      style: TextStyle(fontSize: 13, color: Colors.amber[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onRetry != null) onRetry();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Check Connection & Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  /// Check connection with loading indicator
  static Future<bool> checkConnectionWithLoading(BuildContext context) async {
    bool hasConnection = false;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Checking internet connection...'),
          ],
        ),
      ),
    );
    
    hasConnection = await hasInternetConnection();
    Navigator.of(context).pop(); // Close loading dialog
    
    return hasConnection;
  }
}
