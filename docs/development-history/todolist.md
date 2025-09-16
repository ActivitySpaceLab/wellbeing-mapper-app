# TODO list

✅ **RESOLVED: Google Play USE_EXACT_ALARM Permission Issue**

**Problem**: Google Play Developer Console error: "Your app uses the USE_EXACT_ALARM permission. If your app's core functionality is not 'calendar' or 'alarm clock', you're not eligible to use this permission and must remove it from your app, across all tracks."

**Solution**: Successfully switched from exact to inexact alarms for biweekly survey notifications:
- ✅ Removed `USE_EXACT_ALARM` and `SCHEDULE_EXACT_ALARM` permissions from AndroidManifest.xml
- ✅ Changed all `AndroidScheduleMode.exactAllowWhileIdle` to `AndroidScheduleMode.inexactAllowWhileIdle` in notification_service.dart
- ✅ This is perfect for biweekly surveys since exact timing is not required - notifications just need to appear within the day

**Impact**: App now complies with Google Play policies while maintaining full biweekly survey notification functionality. The inexact timing is actually better for user experience as notifications will appear at optimal times rather than potentially inconvenient exact moments.

