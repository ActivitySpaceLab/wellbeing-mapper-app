---
layout: default
title: Notification Feature Summary
nav_order: 6
---

# Wellbeing Mapper Enhanced Notification System

## Overview

The Wellbeing Mapper notification system has been significantly enhanced to improve research reliability and participant engagement. The system now uses a **dual-notification approach** combining device-level notifications with in-app dialogs, ensuring participants don't miss survey opportunities even when the app is closed.

## Major Enhancements (Latest Update)

### ✅ **Device-Level Notifications**
- **NEW**: Added `flutter_local_notifications` package for system-level notifications
- Notifications now appear even when the app is completely closed
- Platform-specific implementation for Android and iOS
- Automatic permission handling with graceful fallbacks

### ✅ **Dual Notification Strategy**
- **Device Notifications**: Immediate system notifications with survey reminders
- **In-App Dialogs**: Traditional dialogs when app is opened (backup system)
- **Maximum Reliability**: Ensures participants are notified through multiple channels

### ✅ **Enhanced Testing Tools for Research Teams**
- **Test Device Notification**: Send immediate system notification for verification
- **Test In-App Notification**: Show traditional dialog for comparison
- **Permission Diagnostics**: Detailed status and troubleshooting information
- **Enhanced Statistics**: Platform info, permission status, system health

## Feature Highlights

### ✅ **2-Week Recurring Schedule**
- Automatically prompts users every 14 days
- Uses existing `background_fetch` plugin for scheduling
- Survives app termination and device restarts
- **NEW**: Device notifications work even when app is closed

### ✅ **Smart Notification System**
- **Device Notifications**: System-level notifications with tap-to-open functionality
- **In-App Dialogs**: Shows when user opens app with pending notification
- Includes "Participate" button that opens survey webview
- "Maybe Later" option to dismiss until next cycle

### ✅ **Robust Background Processing**
- Leverages existing background_fetch infrastructure 
- Minimal battery impact with hourly timing checks
- **NEW**: Cross-platform notification delivery
- No additional dependencies beyond flutter_local_notifications

### ✅ **Enhanced User Control**
- Notification settings screen accessible from side menu
- **NEW**: Comprehensive testing tools for research verification
- Statistics showing notification history and next reminder
- **NEW**: Permission status and diagnostics
- Options to disable, reset, or manually trigger notifications

## Implementation Details

### Files Created/Modified

#### Enhanced Files:
1. **`lib/services/notification_service.dart`**
   - Core notification scheduling and management
   - **NEW**: Device-level notification support via flutter_local_notifications
   - **NEW**: Platform-specific permission handling (Android/iOS)
   - **NEW**: Comprehensive testing methods for research teams
   - **NEW**: Enhanced diagnostics and monitoring
   - Background task handling and user preference storage

2. **`lib/ui/notification_settings_view.dart`**
   - User interface for notification preferences
   - **NEW**: Device notification testing buttons
   - **NEW**: Permission status and diagnostics display
   - **NEW**: Enhanced testing tools for research verification
   - Statistics display and management options

3. **`pubspec.yaml`**
   - **NEW**: Added flutter_local_notifications: ^18.0.1 dependency
   - Enables cross-platform device notification support
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

### Enhanced Notification Flow
1. **Background Check**: Every hour, checks if 14+ days have passed since last notification
2. **Dual Notification Trigger**: If due, sends both device notification AND sets pending flag
3. **Device Notification**: Immediate system notification appears even if app is closed
4. **App Launch Check**: When app opens, checks for pending notifications (backup system)
5. **Show Dialog**: Displays survey participation dialog if pending (fallback)
6. **Navigate to Survey**: "Participate" button opens existing webview system

### User Experience Improvements
- **Never Miss Notifications**: Device notifications work even when app is closed
- **Seamless Integration**: Uses existing survey webview infrastructure
- **Multiple Touchpoints**: Both device notifications and in-app dialogs ensure engagement
- **Research-Friendly**: Enhanced testing tools for research team verification

### Testing Workflow for Research Teams
1. **Open App** → Settings → Survey Notifications
2. **Test Device Notifications**: Verify system-level notifications work
3. **Check Permissions**: Ensure proper notification permissions are granted
4. **Monitor Diagnostics**: View detailed system status and troubleshooting info
5. **Verify Functionality**: Use test buttons to confirm all notification types work
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
