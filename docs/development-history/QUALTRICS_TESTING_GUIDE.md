# Qualtrics Survey Testing Guide

## Quick Test Setup

### 1. Bypass Participant Code Validation
Use any of these test codes to get past the validation screen:
- **`TESTER`** (recommended for testing)
- **`TEST123`**
- **`DEV001`**

*Note: These codes are hardcoded for testing purposes and will be removed in production.*

### 2. Navigate to Surveys
1. Complete app setup with test participant code
2. Go to side menu → "Survey History"
3. Test both survey types:
   - **Initial Survey**: Tap "Initial Survey" → "Not completed - tap to complete"
   - **Biweekly Survey**: Tap "New Survey" button

### 3. What to Look For

#### ✅ Success Indicators:
- **Green toast notification**: "Survey fields populated successfully"
- **Survey loads properly** in the webview
- **Location data is encrypted** before being inserted (for biweekly surveys)
- **Survey completes and returns to app** when you finish

#### ⚠️ Warning Indicators:
- **Orange toast notification**: "Field population issue - check survey setup"
- **Survey loads but participant ID/location not pre-filled**

#### ❌ Error Indicators:
- **Survey doesn't load at all**
- **App crashes when opening survey**
- **Survey loads but never returns to app after completion**

### 4. Testing Scenarios

#### Scenario A: Initial Survey Test
1. Use participant code: `TESTER`
2. Navigate to Survey History
3. Tap Initial Survey
4. **Expected**: Survey loads, green toast appears, participant ID field is pre-populated
5. Complete survey and verify it returns to app

#### Scenario B: Biweekly Survey Test (with Encrypted Location Data)
1. From Survey History, tap "New Survey"
2. **Expected**: Survey loads, green toast appears, participant ID populated, location data encrypted and populated
3. Complete survey and verify it returns to app
4. **Privacy Note**: Location data is automatically encrypted using RSA+AES hybrid encryption before being inserted

### 6. Debug Information

#### Location Data Protection
- **Automatic Encryption**: All location data is encrypted before being sent to Qualtrics
- **Hybrid Encryption**: Uses AES-256-GCM + RSA-PKCS1 for maximum security
- **Test Key**: Currently using a test public key for encryption
- **No Plaintext**: Raw location data never appears in survey forms

#### Mobile Testing (No Developer Tools)
- **Toast notifications** provide immediate feedback
- **App logs** can be viewed if running in debug mode
- **Survey completion** should automatically return to app

#### Desktop Testing (Optional)
If you run `flutter run -d chrome` for web testing:
1. Open browser developer tools (F12)
2. Check Console tab for detailed logs
3. Look for messages like:
   - "Starting Qualtrics field population..."
   - "Set participant_id via embedded data: [UUID]"
   - "Set location data in field X"

### 7. Generating Real Encryption Keys

#### For Production Use:
```bash
# Generate RSA key pair
openssl genrsa -out private_key.pem 2048
openssl rsa -in private_key.pem -pubout -out public_key.pem

# The public_key.pem content goes into the app
# The private_key.pem stays secure on your research servers
```

#### Current Test Key:
- Using placeholder test key for development
- Replace with real public key before production
- Update both `location_encryption_service.dart` and research site configs

### 8. Troubleshooting

#### Survey Doesn't Load
- Check internet connection
- Verify Qualtrics URLs are accessible
- Try toggling between hardcoded surveys: Set `useQualtricsSurveys = false` in `SurveyNavigationService`

#### Fields Not Populated
- Orange toast indicates partial success - survey loads but field injection had issues
- This is expected initially as we fine-tune the field detection
- Survey will still work, just without pre-filled data

#### Survey Doesn't Return to App
- Check if you're actually completing the survey (reaching thank you page)
- Some surveys might have required fields that prevent completion
- You may need to manually go back to the app

### 7. Switching Between Survey Types

#### Test with Qualtrics (Current Setting)
```dart
// In lib/services/survey_navigation_service.dart
static const bool useQualtricsSurveys = true;
```

#### Fallback to Hardcoded Surveys
```dart
// In lib/services/survey_navigation_service.dart
static const bool useQualtricsSurveys = false;
```

### 8. Production Preparation

When testing is complete:
1. **Remove test participant codes** from `participant_validation_service.dart`
2. **Set feature flag** to desired state (`true` for Qualtrics, `false` for hardcoded)
3. **Update field detection** if needed based on test results
4. **Remove toast notifications** if desired for cleaner user experience

---

*For technical issues, check the implementation in:*
- *`lib/services/qualtrics_survey_service.dart` - Field injection logic*
- *`lib/services/survey_navigation_service.dart` - Feature flag*
- *`lib/ui/web_view.dart` - Webview and feedback handling*
