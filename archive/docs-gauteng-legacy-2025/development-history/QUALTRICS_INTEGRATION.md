# Qualtrics Survey Integration

This document explains the new Qualtrics survey integration that replaces the hardcoded Flutter survey forms.

## Overview

The app now supports both legacy KoboToolbox surveys and new Qualtrics surveys through a unified webview interface. This allows for seamless transition from hardcoded surveys to web-based surveys.

## Architecture

### Key Components

1. **QualtricsSurveyService** (`lib/services/qualtrics_survey_service.dart`)
   - Manages Qualtrics survey URLs and JavaScript injection
   - Handles hidden field population for participant ID and location data
   - Provides survey completion detection

2. **SurveyNavigationService** (`lib/services/survey_navigation_service.dart`)
   - Provides unified interface for survey navigation
   - Feature flag to switch between hardcoded and Qualtrics surveys
   - Handles routing with appropriate parameters

3. **MyWebView** (`lib/ui/web_view.dart`)
   - Enhanced to support both KoboToolbox and Qualtrics surveys
   - JavaScript injection for hidden fields
   - Survey completion detection and navigation

4. **Route Generator** (`lib/models/route_generator.dart`)
   - New routes for Qualtrics surveys:
     - `/qualtrics_initial_survey`
     - `/qualtrics_biweekly_survey`

## Configuration

### URLs
```dart
static const String _initialSurveyUrl = 'https://pretoria.eu.qualtrics.com/jfe/form/SV_byJSMxWDA88icbY';
static const String _biweeklySurveyUrl = 'https://pretoria.eu.qualtrics.com/jfe/form/SV_3aNJIQJXHPCyaOi';
```

### Hidden Field Names
```dart
static const String _participantIdField = 'participant_id';
static const String _locationJsonField = 'locations';
```

### Feature Flag
```dart
static const bool useQualtricsSurveys = true; // Set to false for legacy surveys
```

## Hidden Field Population

The system automatically populates Qualtrics hidden fields with:

### Initial Survey
- **Participant ID**: User's UUID from `GlobalData.userUUID`

### Biweekly Survey
- **Participant ID**: User's UUID from `GlobalData.userUUID`
- **Location JSON**: Location history data as JSON string

## JavaScript Integration

The system uses multiple approaches to populate Qualtrics fields due to the dynamic nature of Qualtrics HTML generation:

### 1. Qualtrics Embedded Data API (Primary Method)
```javascript
Qualtrics.SurveyEngine.setEmbeddedData('participant_id', participantUUID);
Qualtrics.SurveyEngine.setEmbeddedData('locations', locationJSON);
```

### 2. Direct DOM Manipulation (Fallback)
- Searches for inputs by name, id, class, and data attributes
- Tries multiple selector patterns:
  - `input[name*="participant_id"]`
  - `input[id*="participant_id" i]` (case-insensitive)
  - `input[class*="participant_id" i]`
  - `input[data-field="participant_id"]`
  - Hidden inputs and text areas

### 3. Intelligent Field Discovery
- Scans all text inputs for fields containing keywords like "participant" or "location"
- Handles Qualtrics-generated field IDs that may not match the survey builder IDs

### 4. Multiple Timing Attempts
- Initial attempt after 2 seconds
- Secondary attempt after 5 seconds  
- Accounts for Qualtrics dynamic loading and rendering

## Survey Completion Detection

The system detects survey completion through:
- Qualtrics completion page indicators (`.EndOfSurvey`, `#EndOfSurvey`)
- URL changes containing 'complete' or 'thank'
- Page content containing 'Thank you'

## Navigation

All survey navigation now goes through `SurveyNavigationService`:

```dart
// Navigate to initial survey
SurveyNavigationService.navigateToInitialSurvey(context);

// Navigate to biweekly survey with location data
SurveyNavigationService.navigateToBiweeklySurvey(context, locationJson: locationData);
```

## Implementation Status

✅ **Completed:**
- Service architecture setup
- WebView enhancements
- Route generation
- Navigation service integration
- Survey list screen integration
- Qualtrics survey URLs configured
- Hidden field names configured with robust injection methods

🧪 **Ready for Testing:**
- Qualtrics survey integration with multiple field detection methods
- JavaScript injection with comprehensive error handling and logging

## Next Steps

1. ✅ **Get Qualtrics URLs**: Completed - URLs updated with actual survey links
2. ✅ **Get Hidden Field Names**: Completed - Field names configured with robust detection
3. **Test Integration**: Test the surveys in the app and check browser console for field population logs
4. **Verify Data Collection**: Ensure participant ID and location data are properly captured in Qualtrics responses
5. **Update Feature Flag**: Set `useQualtricsSurveys = true` when ready for production use

## Migration Plan

The system is designed for gradual migration:

1. **Phase 1**: Keep `useQualtricsSurveys = false` (current hardcoded surveys)
2. **Phase 2**: Test with `useQualtricsSurveys = true` and real Qualtrics URLs
3. **Phase 3**: Remove legacy survey screens once Qualtrics integration is confirmed working
4. **Phase 4**: Remove feature flag and legacy code

## Error Handling

The system includes comprehensive error handling:
- JavaScript injection failures are logged but don't crash the app
- Missing survey URLs fall back to placeholder behavior
- Network issues are handled by the webview component
- Completion detection failures are logged for debugging
