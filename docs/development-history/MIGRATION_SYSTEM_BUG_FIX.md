# Migration System Bug Fix - Critical Issue Resolution

## Issue Summary

**Problem**: The pilot migration system was incorrectly treating all app updates as pilot user migrations, causing unnecessary re-onboarding (participant code, consent, permissions, initial survey) for production users.

**Impact**: Production users who updated the app were forced to go through the complete onboarding process again, losing their existing app state and requiring new participant codes.

**Root Cause**: The migration system only checked app version to determine migration needs, but failed to properly mark migration as completed for production-to-production upgrades.

## Technical Details

### Bug Location
File: `lib/services/pilot_migration_service.dart`
Method: `checkMigrationStatus()`

### Problem Code
```dart
// User is upgrading from a previous production version
print('[PilotMigration] Production upgrade detected');
await _recordCurrentVersion();
return MigrationStatus.productionUpgrade;
```

### Issue
- When production users updated from one production version to another (e.g., 1.0.7+132 → 1.0.7+133)
- The system correctly identified it as a "production upgrade" 
- But it only recorded the current version without marking migration as completed
- On next app start, the migration check would run again, thinking migration was still needed

### Fix Applied
```dart
// User is upgrading from a previous production version
print('[PilotMigration] Production upgrade detected - no migration needed');
await prefs.setBool(_migrationCompletedKey, true); // Mark migration as completed
await _recordCurrentVersion();
return MigrationStatus.productionUpgrade;
```

## Migration Logic Overview

The migration system now correctly handles three scenarios:

### 1. Fresh Install
- No previous version recorded
- Sets current version and proceeds normally
- **Result**: Normal app startup, no migration

### 2. Pilot User Upgrade (< 1.0.7 → 1.0.7+)
- Previous version < 1.0.7 detected
- Preserves personal data (location tracks, happiness surveys)
- Clears research data (participation settings, consent)
- **Result**: User keeps personal data but must re-onboard for research

### 3. Production User Upgrade (1.0.7+ → 1.0.7+)
- Previous version ≥ 1.0.7 detected
- Marks migration as completed (NEW FIX)
- Records current version
- **Result**: Normal app startup, no migration needed

## Test Scenarios

### Test Code Available
- `PRODTEST` - New test code specifically for production testing
- `TESTER` - Original test code (still available)
- `TEST123` - Alternative test code
- `DEV001` - Development test code

### Testing Procedure
1. **Fresh Install Test**: Install app, verify normal startup
2. **Production Upgrade Test**: 
   - Install production version
   - Use PRODTEST code to complete onboarding
   - Install updated version
   - Verify no re-onboarding required
3. **Pilot Upgrade Test**: (Would require pilot version - not applicable now)

## Files Modified

1. **pilot_migration_service.dart**
   - Fixed production upgrade logic
   - Added migration completion flag for production upgrades

2. **participant_validation_service.dart**
   - Added PRODTEST code for production testing

## Build Outputs

- **Fixed APK**: `build_outputs/wellbeing-mapper-android-v1.0.7-migration-fix.apk`
- **Size**: 85MB
- **Version**: 1.0.7+132 with migration fix

## Testing Status

✅ **Build Successful**: APK builds without errors
✅ **Fresh Install**: Works correctly - no migration triggered
✅ **App Functionality**: All UX fixes preserved (debug sounds disabled, map controls added)
⏳ **Production Upgrade**: Ready for testing (install → onboard → update → verify no re-onboarding)

## Critical Notes for Team Testing

1. **Use PRODTEST code**: This clearly identifies testing vs pilot users
2. **Test upgrade scenario**: Install → complete onboarding → update → verify state preserved
3. **Check logs**: Migration system provides detailed debug output
4. **Verify no re-onboarding**: Updated app should preserve all user state

## Next Steps

1. ✅ Build fixed APK
2. ⏳ Test production upgrade scenario thoroughly
3. ⏳ Build iOS version with same fix
4. ⏳ Create GitHub pre-release with both builds
5. ⏳ Distribute to team for comprehensive testing

## Migration System Debug Output

The system now provides clear debug information:
```
[PilotMigration] Checking migration status...
[PilotMigration] Migration completed flag: [true/false]
[PilotMigration] Previous version: [version or null]
[PilotMigration] Current version: 1.0.7+132
[PilotMigration] [Fresh install/Pilot user upgrade/Production upgrade] detected
```

This fix ensures production users can update the app seamlessly without losing their progress or being forced to re-onboard.