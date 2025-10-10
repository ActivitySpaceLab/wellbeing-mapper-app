# Testing the App Mode Switching Bug Fix

## Quick Test Steps

### 1. Build and Run the App
```bash
cd gauteng-wellbeing-mapper-app
fvm flutter run
```

### 2. Test the Bug Fix

**Before Testing:**
- Make sure you're starting in Private mode
- Have some location tracking data already recorded (so you can see if tracks disappear)

**Test Sequence:**
1. **Open the app** - should be in Private mode initially
2. **Start location tracking** (if not already tracking) using the switch in top-right
3. **Record some location data** by walking around a bit or just leaving the app running
4. **Check the map has tracks** - you should see blue lines/dots showing your movement
5. **Open the side menu** (hamburger icon) - verify it shows "Current Mode: Private"
6. **Tap "App Mode"** → **"Change Mode"**
7. **Select "App Testing Mode"** → **"Switch Mode"** → **Confirm**
8. **Complete the consent form** (this will be in testing mode - orange colored)
9. **Tap "Continue to App"** when consent is complete

**Expected Results After Fix:**
- ✅ **App mode should be "App Testing"** in the side menu (not "Private")
- ✅ **Map tracks should still be visible** (blue lines/dots should remain)
- ✅ **Research features should be available** in the menu (Initial Survey, Wellbeing Survey, etc.)

## Debug Information

If the issue persists, check these logs:

### In Android Studio / VS Code Debug Console:
Look for these log messages:
```
[ConsentForm] Set app mode to appTesting after consent completion
[ConsentForm] Testing mode consent completed - returning to change mode screen
```

### If You Don't See These Messages:
The consent form might not be receiving the `isTestingMode: true` flag properly.

### Alternative Test Method:
If the change mode flow doesn't work, try this direct approach:

1. Go to **side menu** → **"App Mode"**  
2. **Force close and restart the app**
3. Check if the mode is now "App Testing"

## Expected Log Output

When working correctly, you should see logs like:
```
[ChangeModeScreen] Switching to appTesting mode
[ConsentForm] Saved research participant settings for testing mode
[ConsentForm] Set app mode to appTesting after consent completion  
[ConsentForm] Testing mode consent completed - returning to change mode screen
[ChangeModeScreen] Successfully switched to App Testing Mode
```

## If Still Not Working

Please check:
1. **Run `flutter clean && flutter pub get`** to ensure clean build
2. **Check if you're using the latest code** (pull from git)
3. **Look at the debug console output** and share any error messages
4. **Try the privacy protection test** to ensure app mode service is working:
   ```bash
   flutter test test/services/data_privacy_protection_test.dart -v
   ```

## What Fixed

The issue was that:
1. **Consent form wasn't setting the app mode** after completion  
2. **Navigation was wrong** - consent form was replacing the entire navigation stack instead of returning success to the change mode screen
3. **Change mode screen reverted the mode** when it didn't receive a success result

Both issues are now fixed in the consent form completion flow.
