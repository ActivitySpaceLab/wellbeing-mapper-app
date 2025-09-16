# Space Mapper Recurring Notification Feature

## Overview

I've successfully implemented a recurring notification system for the Space Mapper Flutter app that prompts users to respond to surveys every 2 weeks. The implementation leverages the existing background processing infrastructure and integrates seamlessly with the app's webview survey system.

## Feature Highlights

### ✅ **2-Week Recurring Schedule**
- Automatically prompts users every 14 days
- Uses existing `background_fetch` plugin for scheduling
- Survives app termination and device restarts

### ✅ **Smart Dialog System**
- Shows in-app dialog when user opens app with pending notification
- Includes "Participate" button that opens survey webview
- "Maybe Later" option to dismiss until next cycle

### ✅ **Background Processing**
- Leverages existing background_fetch infrastructure 
- Minimal battery impact with hourly timing checks
- No additional dependencies required

### ✅ **User Control**
- Notification settings screen accessible from side menu
- Statistics showing notification history and next reminder
- Options to disable, reset, or manually trigger notifications

## Implementation Details

### Files Created/Modified

#### New Files:
1. **`lib/services/notification_service.dart`**
   - Core notification scheduling and management
   - Background task handling
   - User preference storage

2. **`lib/ui/notification_settings_view.dart`**
   - User interface for notification preferences
   - Statistics display and management options
   - Manual testing capabilities

#### Modified Files:
1. **`lib/main.dart`**
   - Integrated notification service initialization
   - Added notification headless task handler

2. **`lib/ui/home_view.dart`**
   - Added pending notification check on app startup
   - Shows survey dialog when notifications are due

3. **`lib/ui/side_drawer.dart`**
   - Added "Survey Notifications" menu item

4. **`lib/models/route_generator.dart`**
   - Added route for notification settings screen

5. **`docs/DEVELOPER_GUIDE.md`**
   - Comprehensive documentation of notification system

## How It Works

### Background Scheduling
```dart
// Runs every hour in background
BackgroundFetch.scheduleTask(TaskConfig(
  taskId: 'com.wellbeingmapper.survey_notification',
  delay: 3600000, // 1 hour
  periodic: true,
  // ... configuration
));
```

### Notification Flow
1. **Background Check**: Every hour, checks if 14+ days have passed since last notification
2. **Set Pending Flag**: If due, sets a flag in SharedPreferences
3. **App Launch Check**: When app opens, checks for pending notifications
4. **Show Dialog**: Displays survey participation dialog if pending
5. **Navigate to Survey**: "Participate" button opens existing webview system

### User Experience
- **Seamless Integration**: Uses existing survey webview infrastructure
- **Non-Intrusive**: Only shows dialog when app is opened, no push notifications
- **User Control**: Full settings screen for managing preferences
- **Statistics**: Users can see notification history and next reminder date

## Technical Advantages

### ✅ **Minimal Dependencies**
- Uses existing `background_fetch` plugin
- No additional notification libraries required
- Lightweight implementation

### ✅ **Cross-Platform**
- Works on both iOS and Android
- Uses Flutter's built-in dialog system
- Leverages existing background processing

### ✅ **Battery Efficient**
- Piggybacks on existing background tasks
- Hourly checks with minimal processing
- No constant monitoring required

### ✅ **Privacy Focused**
- No push notification servers required
- All data stored locally
- Respects user preferences

## User Interface

### Survey Dialog
When a notification is due, users see:
```
┌─────────────────────────────────┐
│     Survey Participation        │
├─────────────────────────────────┤
│ Help improve research by        │
│ participating in our survey!    │
│ Your contributions help         │
│ scientists understand human     │
│ mobility patterns.              │
├─────────────────────────────────┤
│  [Maybe Later]  [Participate]   │
└─────────────────────────────────┘
```

### Settings Screen
Accessible via side menu → "Survey Notifications":
- **Statistics**: Total notifications, last/next dates
- **Actions**: Manual trigger, reset schedule, disable
- **Information**: Explanation of notification system

## Testing

### Manual Testing
1. Go to Settings → Survey Notifications
2. Tap "Trigger Survey Prompt Now" to test dialog
3. Tap "Reset Notification Schedule" to test fresh user experience
4. Check statistics to verify tracking

### Background Testing
The system runs automatically in the background. To verify:
1. Check SharedPreferences for notification timestamps
2. Verify background tasks are scheduled
3. Test app launch with pending notifications

## Future Enhancements

The current implementation provides a solid foundation that can be extended with:
- Push notifications for better engagement
- Customizable notification intervals
- A/B testing for different notification strategies
- Rich notification content with action buttons

## Integration Success

The notification system seamlessly integrates with Space Mapper's existing infrastructure:
- ✅ Uses existing background processing
- ✅ Leverages existing webview survey system
- ✅ Follows app's navigation patterns
- ✅ Maintains privacy-focused approach
- ✅ Provides comprehensive user control

This implementation successfully fulfills the requirement for a recurring notification system that prompts users every 2 weeks to respond to surveys via the app's webview, while maintaining the app's architecture principles and user experience standards.
