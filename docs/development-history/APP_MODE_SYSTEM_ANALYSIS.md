# App Mode System Analysis - Data Upload Issue Investigation

**Date**: October 2, 2025  
**Purpose**: Comprehensive analysis of app mode selection, storage, and data upload logic to identify why data uploads stopped on September 30th.

## 🏗️ App Mode Architecture Overview

### Core Components

1. **AppMode Enum** (`lib/models/app_mode.dart`)
2. **AppModeService** (`lib/services/app_mode_service.dart`) 
3. **ParticipationSelectionScreen** (`lib/ui/participation_selection_screen.dart`)
4. **ChangeModeScreen** (`lib/ui/change_mode_screen.dart`)
5. **EncryptedSurveyService** (`lib/services/encrypted_survey_service.dart`)

---

## 📋 Mode Definitions

### AppMode Enum
```dart
enum AppMode {
  private,      // Personal use, no data sharing
  research,     // Real research participation, data uploaded
  appTesting,   // Testing features, no real data uploads
}
```

### Mode Properties (Critical for Data Upload)
```dart
// CRITICAL: Only research mode sends data to research servers
bool get sendsDataToResearch {
  return this == AppMode.research;  // ONLY research mode!
}

bool get hasResearchFeatures {
  return this == AppMode.research || this == AppMode.appTesting;
}
```

---

## 🔧 Build Flavor Logic (POTENTIAL ISSUE #1)

### AppModeService Build Detection
```dart
static const String appFlavor = String.fromEnvironment('APP_FLAVOR', defaultValue: 'production');
static bool get isBetaBuild => appFlavor == 'beta';
static bool get isProductionBuild => appFlavor == 'production';
```

### Available Modes by Build Type
```dart
static List<AppMode> getAvailableModes() {
  if (isBetaBuild) {
    // Beta builds: [private, appTesting] - NO RESEARCH MODE!
    return [AppMode.private, AppMode.appTesting];
  } else {
    // Production builds: [private, research]  
    return [AppMode.private, AppMode.research];
  }
}
```

**🚨 POTENTIAL ISSUE**: If builds since Sept 30th are being detected as "beta" instead of "production", research mode becomes unavailable!

---

## 💾 Mode Storage and Persistence

### Storage Location
- **Key**: `'app_mode'` in SharedPreferences
- **Values**: `'private'`, `'research'`, `'appTesting'`

### Mode Validation on Load
```dart
static Future<AppMode> getCurrentMode() async {
  final prefs = await SharedPreferences.getInstance();
  final modeString = prefs.getString(_modeKey);
  
  if (modeString == null) {
    return AppMode.private; // Default to private
  }
  
  // Parse stored mode
  AppMode requestedMode = parseMode(modeString);
  
  // CRITICAL VALIDATION: Check if mode is available in current build
  if (isTestMode || getAvailableModes().contains(requestedMode)) {
    return requestedMode;
  } else {
    // If stored mode not available, fall back to private
    return AppMode.private;  // ← THIS COULD BE THE BUG!
  }
}
```

**🚨 POTENTIAL ISSUE**: If users had `research` mode stored, but new builds are detected as "beta", the mode gets reset to `private`!

---

## 🔄 Mode Selection Process

### Initial App Setup (ParticipationSelectionScreen)

1. **Load Available Modes**
   ```dart
   void _loadAvailableModes() {
     _availableModes = AppModeService.getAvailableModes();
     
     // Ensure selected mode is available
     if (!_availableModes.any((mode) => mode.toString().split('.').last == _selectedMode)) {
       _selectedMode = _availableModes.first.toString().split('.').last;
     }
   }
   ```

2. **Validate Stored Mode** (Added Recently)
   ```dart
   Future<void> _validateStoredMode() async {
     final currentMode = await AppModeService.getCurrentMode();
     final currentModeString = currentMode.toString().split('.').last;
     
     // Check if stored mode is available in current build
     if (!_availableModes.any((mode) => mode.toString().split('.').last == currentModeString)) {
       print('[ParticipationSelection] Stored mode $currentModeString not available in current build, clearing...');
       await AppModeService.clearModeData();  // ← CLEARS USER'S MODE!
       _selectedMode = 'private'; // Reset to default
     }
   }
   ```

3. **Mode Selection and Save**
   ```dart
   void _handleContinue() async {
     final selectedAppMode = _availableModes.firstWhere(
       (mode) => mode.toString().split('.').last == _selectedMode,
       orElse: () => AppMode.private,
     );
     
     if (selectedAppMode == AppMode.private) {
       await AppModeService.setCurrentMode(AppMode.private);
       // No consent needed, go to main app
     } else if (selectedAppMode == AppMode.research) {
       await AppModeService.setCurrentMode(AppMode.research);
       // Go through consent process
     }
   }
   ```

---

## 🔒 Data Upload Logic (EncryptedSurveyService)

### Upload Decision Flow
```dart
static Future<void> syncPendingSurveys() async {
  final currentMode = await AppModeService.getCurrentMode();
  
  // Check 1: App Testing Mode (simulate, don't upload)
  if (currentMode == AppMode.appTesting) {
    print('App Testing Mode: Simulating sync without sending real data');
    return; // EXIT - no upload
  }
  
  // Check 2: Mode allows data uploads
  if (!await AppModeService.sendsDataToResearch()) {
    print('❌ Data upload not available in current app mode');
    return; // EXIT - no upload  
  }
  
  // Check 3: Valid participant UUID
  final participantUuid = GlobalData.userUUID;
  if (participantUuid.isEmpty) {
    print('❌ No participant UUID found, skipping survey sync');
    return; // EXIT - no upload
  }
  
  // Check 4: Valid consent record
  final consent = await db.getLatestDataSharingConsent(participantUuid);
  if (consent == null) {
    print('❌ No consent found, skipping survey sync (consent required)');
    return; // EXIT - no upload
  }
  
  // ALL CHECKS PASSED - Proceed with upload
  print('✅ Consent found, proceeding with survey sync');
}
```

---

## 🐛 Identified Issues and Root Causes

### Issue 1: Build Flavor Detection
**Problem**: The `APP_FLAVOR` environment variable might not be set correctly during builds since Sept 30th.

**Evidence**: 
- Build script uses `--flavor production` but doesn't set `APP_FLAVOR` environment variable
- If `APP_FLAVOR` defaults to 'production' but something changed in build process...

**Impact**: 
- If detected as beta build: research mode unavailable
- Users get forced into private/appTesting modes
- No data uploads possible

### Issue 2: Mode Validation Clearing User Data
**Problem**: The recently added `_validateStoredMode()` method aggressively clears user mode data.

**Evidence**: 
```dart
// This code clears user's stored research mode!
if (!_availableModes.any((mode) => mode.toString().split('.').last == currentModeString)) {
  await AppModeService.clearModeData();  // ← DESTRUCTIVE!
  _selectedMode = 'private';
}
```

**Impact**:
- Users who were in research mode get reset to private mode
- All their mode preferences lost
- They don't know why uploads stopped

### Issue 3: Mode Loop in UI
**Problem**: Multiple competing mode validation systems cause conflicts.

**Evidence**:
- `_loadAvailableModes()` changes selected mode
- `_validateStoredMode()` clears stored mode  
- UI state gets confused about current vs selected mode

**Impact**:
- User gets stuck in mode selection screen
- Infinite loops between modes
- Can't complete mode selection

### Issue 4: Consent Record Dependencies
**Problem**: Data uploads require both correct mode AND valid consent records.

**Evidence**:
- Even with research mode, uploads fail if consent record missing
- Consent records might be getting cleared or corrupted
- UUID dependencies create additional failure points

---

## 🔍 Debugging Recommendations

### 1. Check Build Flavor Detection
```dart
// Add this logging to verify build flavor
print('[DEBUG] APP_FLAVOR environment: ${String.fromEnvironment('APP_FLAVOR')}');
print('[DEBUG] appFlavor: ${AppModeService.appFlavor}');
print('[DEBUG] isBetaBuild: ${AppModeService.isBetaBuild}');
print('[DEBUG] Available modes: ${AppModeService.getAvailableModes()}');
```

### 2. Check Mode Storage State
```dart
// Add this to see what's actually stored
final prefs = await SharedPreferences.getInstance();
print('[DEBUG] Stored mode: ${prefs.getString('app_mode')}');
print('[DEBUG] Current mode: ${await AppModeService.getCurrentMode()}');
print('[DEBUG] Mode validation: ${AppModeService.getAvailableModes().contains(currentMode)}');
```

### 3. Check Consent and UUID State  
```dart
// Add this to see consent/UUID issues
print('[DEBUG] GlobalData.userUUID: ${GlobalData.userUUID}');
print('[DEBUG] UUID length: ${GlobalData.userUUID.length}');
final consent = await db.getLatestDataSharingConsent(GlobalData.userUUID);
print('[DEBUG] Consent found: ${consent != null}');
```

---

## 🛠️ Proposed Fixes

### Fix 1: Ensure Correct Build Flavor
**Problem**: Build flavor detection
**Solution**: Explicitly set APP_FLAVOR in build scripts

```bash
# In build-release.sh, add:
export APP_FLAVOR=production
flutter build apk --flavor production --dart-define=APP_FLAVOR=production
```

### Fix 2: Less Aggressive Mode Validation
**Problem**: Mode validation clearing user data
**Solution**: Log and warn instead of clearing

```dart
// Replace destructive clearing with logging
if (!_availableModes.any((mode) => mode.toString().split('.').last == currentModeString)) {
  print('[ParticipationSelection] ⚠️ Stored mode $currentModeString not available in current build');
  print('[ParticipationSelection] Available modes: $_availableModes');
  print('[ParticipationSelection] This might indicate a build configuration issue');
  // Don't clear - just default the UI selection
  _selectedMode = 'private';
}
```

### Fix 3: Enhanced Debugging in Upload Service
**Problem**: Need visibility into upload failures
**Solution**: Already implemented enhanced logging

### Fix 4: Mode Consistency Check
**Problem**: Multiple mode validation systems
**Solution**: Centralize validation in AppModeService

---

## 🎯 Testing Strategy

### 1. Test Build Flavor Detection
1. Build with current process
2. Check logs for APP_FLAVOR value
3. Verify available modes include research mode

### 2. Test Mode Persistence
1. Set user to research mode
2. Restart app
3. Verify mode persists

### 3. Test Data Upload Flow
1. Use enhanced logging version
2. Submit survey in research mode
3. Check each failure point in logs

### 4. Test Mode Switching
1. Try switching between modes
2. Check for loops or stuck states
3. Verify consent flow works

---

## 🔑 Key Findings

**Most Likely Cause**: Build flavor detection changed around Sept 30th, causing:
1. Production builds detected as beta builds
2. Research mode becomes unavailable  
3. Users get reset to private mode
4. No data uploads possible

**Secondary Issues**:
- Aggressive mode validation clearing user preferences
- Mode selection UI getting confused
- Multiple validation systems competing

**Next Steps**:
1. Build debugging version with enhanced logging
2. Test on actual device to see logs
3. Verify build flavor detection working correctly
4. Check if users are actually in research mode