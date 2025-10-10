import 'package:flutter/material.dart';
import 'package:wellbeing_mapper/theme/south_african_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingHelper {
  static const String _onboardingKey = 'has_seen_onboarding';
  
  static Future<bool> shouldShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_onboardingKey) ?? false);
  }
  
  static Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }
  
  static void showQuickTour(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.waving_hand, color: SouthAfricanTheme.accentYellow),
            SizedBox(width: 8),
            Text('Welcome!'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Let\'s quickly show you around:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              _buildTourItem(Icons.toggle_on, 'Yellow switch = location tracking ON'),
              _buildTourItem(Icons.gps_fixed, 'GPS button = get current location'),
              _buildTourItem(Icons.add_circle, 'Blue "Survey" button = take wellbeing survey'),
              _buildTourItem(Icons.menu, 'Menu = access all app features'),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SouthAfricanTheme.softYellow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Tip: Open the menu and tap "Help & Guide" for detailed instructions!',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              markOnboardingComplete();
            },
            child: Text('Got it!'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              markOnboardingComplete();
              Navigator.of(context).pushNamed('/help');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SouthAfricanTheme.primaryBlue,
              foregroundColor: SouthAfricanTheme.pureWhite,
            ),
            child: Text('Show Full Guide'),
          ),
        ],
      ),
    );
  }
  
  static Widget _buildTourItem(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: SouthAfricanTheme.primaryBlue),
          SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
