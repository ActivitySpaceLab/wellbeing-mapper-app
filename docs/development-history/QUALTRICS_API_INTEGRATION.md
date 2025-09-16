# Qualtrics API Integration

This document explains the new Qualtrics API integration that replaces the unreliable webview JavaScript injection approach.

## Overview

The new architecture uses Qualtrics REST API to sync survey responses that users enter on hardcoded offline-capable survey forms. This approach provides:

- ✅ Reliable offline capability 
- ✅ No hidden field visibility issues
- ✅ Guaranteed data capture to Qualtrics
- ✅ Better error handling and retry logic
- ✅ Immediate sync attempts with fallback to background sync

## Architecture

### QualtricsApiService (`lib/services/qualtrics_api_service.dart`)
- **Purpose**: Direct API integration with Qualtrics for survey response creation
- **Key Methods**:
  - `syncInitialSurvey()` - Sync completed initial survey to Qualtrics
  - `syncBiweeklySurvey()` - Sync completed biweekly survey to Qualtrics
  - `syncPendingSurveys()` - Bulk sync all unsynced surveys
- **Error Handling**: Graceful fallback when API calls fail

### Database Integration (`lib/db/survey_database.dart`)
- **New Methods Added**:
  - `getUnsyncedInitialSurveys()` - Get initial surveys not yet synced
  - `getUnsyncedRecurringSurveys()` - Get biweekly surveys not yet synced
  - `markInitialSurveySynced()` - Mark initial survey as synced
  - `markRecurringSurveySynced()` - Mark biweekly survey as synced

### Survey Submission Integration
- **Initial Survey** (`lib/ui/initial_survey_screen.dart`): Immediate sync attempt after local save
- **Biweekly Survey** (`lib/ui/recurring_survey_screen.dart`): Immediate sync attempt after local save
- **Background Sync** (`lib/services/data_upload_service.dart`): Periodic bulk sync of pending surveys

## Configuration Required

### 1. Qualtrics API Token
Replace `YOUR_QUALTRICS_API_TOKEN_HERE` in `qualtrics_api_service.dart` with your actual API token:
```dart
static const String _apiToken = 'your_actual_token_here';
```

### 2. Survey IDs
Update the survey IDs to match your Qualtrics surveys:
```dart
static const String _initialSurveyId = 'SV_your_initial_survey_id';
static const String _biweeklySurveyId = 'SV_your_biweekly_survey_id';
```

### 3. Question ID Mapping
Update the question ID mappings in `_mapInitialSurveyToQualtrics()` and `_mapBiweeklySurveyToQualtrics()` to match your Qualtrics survey question IDs:
```dart
// Example mappings - replace with your actual question IDs
data['QID1'] = GlobalData.userUUID; // Participant ID
data['QID2'] = survey['age'].toString(); // Age question
data['QID3'] = ethnicity.join(','); // Ethnicity question
// ... etc
```

## Usage

### Automatic Sync
Surveys are automatically synced to Qualtrics when submitted:
1. User completes survey in offline form
2. Survey saved to local database
3. Immediate sync attempt to Qualtrics
4. If sync fails, survey queued for background sync

### Manual Background Sync
To trigger background sync of all pending surveys:
```dart
await DataUploadService.syncPendingSurveysToQualtrics();
```

### Individual Survey Sync
To sync specific surveys:
```dart
await QualtricsApiService.syncInitialSurvey(surveyData);
await QualtricsApiService.syncBiweeklySurvey(surveyData);
```

## Data Flow

1. **Survey Completion**: User completes hardcoded offline survey form
2. **Local Storage**: Survey data saved to SQLite with `synced = 0`
3. **Immediate Sync**: Attempt to sync to Qualtrics API
4. **Success**: Mark survey as `synced = 1` in database
5. **Failure**: Survey remains `synced = 0` for background retry
6. **Background Sync**: Periodic sync of all `synced = 0` surveys

## Benefits Over Previous Approach

### Before (WebView JavaScript Injection)
- ❌ Hidden fields visible to users
- ❌ Data not appearing in Qualtrics responses  
- ❌ Unreliable iframe detection
- ❌ Complex field manipulation logic
- ❌ Poor offline capability

### After (REST API Integration)
- ✅ No user-visible field issues
- ✅ Guaranteed data capture
- ✅ Simple, reliable API calls
- ✅ Robust offline-first architecture
- ✅ Better error handling and retry logic

## Testing

To test the integration:
1. Configure API credentials and question IDs
2. Submit a survey in the app
3. Check Qualtrics backend for the response
4. Verify data mapping is correct
5. Test offline behavior by disabling network

## Troubleshooting

### Common Issues
1. **API Token Invalid**: Check Qualtrics API token permissions
2. **Survey ID Wrong**: Verify survey IDs match your Qualtrics surveys
3. **Question ID Mismatch**: Map question IDs to match your survey structure
4. **Network Issues**: Surveys will queue locally and sync when connectivity returns

### Debug Logging
The service includes comprehensive debug logging:
- ✅ Successful sync operations
- ❌ Failed sync attempts with error details
- 🔄 Background sync status updates
