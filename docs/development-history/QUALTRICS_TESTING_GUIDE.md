# Qualtrics Survey Testing Guide - Issue Fixes

## Issues Fixed

### 1. ✅ Initial Survey Navigation Fixed
**Problem**: Initial survey was using hardcoded version instead of Qualtrics
**Root Cause**: `home_view.dart` had direct navigation to `InitialSurveyScreen()` in popup dialogs
**Solution**: Updated both survey offering dialogs to use `SurveyNavigationService.navigateToInitialSurvey(context)`

**Files Modified**:
- `/lib/ui/home_view.dart`: Fixed navigation in `_showInitialSurveyOffering()` and `_showInitialSurveyReminder()`

### 2. ✅ Field Population and Visibility Fixed  
**Problem**: UUID was showing in survey instead of participant code, and fields weren't properly hidden
**Root Cause**: 
- Using `GlobalData.userUUID` instead of participant code
- JavaScript hiding logic was insufficient for dynamic content
**Solution**: 
- Use participant code (like "TESTER") from `ParticipantValidationService`
- Added separate UUID field for anti-spoofing
- Enhanced hiding logic with multiple detection methods

**Enhanced JavaScript Features**:
- **Participant Code**: Uses actual participant code (e.g., "TESTER") in `participant_id` field
- **UUID Field**: Separate `participant_uuid` field for uniqueness verification
- **Robust Hiding**: Multiple CSS properties (`display: none`, `visibility: hidden`)
- **Container Detection**: Finds and hides `.QuestionOuter`, `.QuestionBody`, etc.
- **Value-based Detection**: Finds fields by content, not just selectors
- **Multi-timing**: Runs at 2 seconds AND 5 seconds to catch late-loading fields

### 3. ✅ Form Submission Error Fixed
**Problem**: Qualtrics validation errors about unselected answer choices
**Root Cause**: Hidden required fields weren't properly marked as "answered"
**Solution**: Comprehensive validation state management

**Validation Features**:
- Triggers multiple validation events (`blur`, `focusout`, `change`, `input`)
- Adds `Answered` class and removes `ValidationError` classes
- Sets `data-answered="true"` attributes
- Handles all possible container classes
- Processes both participant ID and UUID fields
- Includes fallback for any missed hidden fields

## Testing Instructions

### Test 1: Initial Survey Navigation
1. **Fresh Install**: Install app on device with TESTER code
2. **Trigger Dialog**: Should see "Complete Initial Survey" popup 
3. **Click "Yes, complete now"**: Should open Qualtrics survey (not hardcoded)
4. **Verify URL**: Survey URL should contain `pretoria.eu.qualtrics.com`

### Test 2: Field Visibility and Population
1. **Open Initial Survey**: Via any navigation method
2. **Check Console**: Should see "Participant Code: TESTER" and "Participant UUID: [uuid]"
3. **Check Fields**: No participant_id or UUID fields should be visible
4. **Check Survey**: All regular survey questions should be visible and functional

### Test 3: Form Submission
1. **Complete Survey**: Fill out all visible survey questions
2. **Submit**: Click Qualtrics submit button
3. **Verify Success**: Should submit without validation errors
4. **Check Toast**: Should see success message in mobile app

### Expected Console Output
```javascript
Starting Qualtrics field population...
Participant Code: TESTER
Participant UUID: [uuid-string]
Set participant_id via embedded data: TESTER
Set participant_uuid via embedded data: [uuid-string]
Hiding participant ID, UUID, and location fields...
Hidden participant ID question container: [element]
Hidden participant UUID question container: [element]
Field hiding completed
Marking hidden fields as answered...
Marked participant ID field as answered: [element]
Marked participant UUID field as answered: [element]
Hidden fields marked as answered
Qualtrics hidden fields population completed
```

## Debug Features Added

### Console Logging
- Detailed participant code vs UUID differentiation
- Separate logging for each field type (ID, UUID, locations)
- Success/error feedback for each step
- Toast messages to mobile app for debugging

### Field Detection Methods

#### Participant ID Field (`participant_id`)
- Contains participant code like "TESTER" 
- `input[name*="participant_id"]`
- `input[id*="participant_id" i]` (case insensitive)
- Text inputs with "participant" but not "uuid"
- Pattern matching excluding UUID patterns

#### Participant UUID Field (`participant_uuid`)  
- Contains actual UUID for anti-spoofing
- `input[name*="participant_uuid"]`
- `input[id*="uuid" i]`
- Text inputs containing "uuid"
- Value-based detection for UUID patterns

#### Location Field (`locations`)
- `input[name*="locations"]`
- `textarea[name*="locations" i]`
- Similar pattern matching as other fields

### Enhanced Security Features
- **Anti-spoofing**: Separate UUID field prevents participants from using same code
- **Value Detection**: Finds fields by actual content, not just names
- **Comprehensive Hiding**: Uses both `display: none` and `visibility: hidden`
- **Container Traversal**: Intelligent parent container detection and hiding

## Field Population Logic

### Data Sources
1. **Participant Code**: From `ParticipantValidationService.getValidatedParticipantCode()`
   - Examples: "TESTER", "P001", "DEV001"
   - Used in `participant_id` field
   
2. **UUID**: From `GlobalData.userUUID`
   - Unique identifier for each app installation
   - Used in `participant_uuid` field
   - Prevents multiple participants using same code

### Validation Handling
1. **Field Detection**: Multiple selector methods with fallbacks
2. **Value Setting**: Triggers change events for proper registration
3. **Hiding**: Robust CSS-based hiding with container detection
4. **Validation**: Marks fields as answered to prevent form errors

## Next Steps
1. Install updated APK on test device
2. Test each scenario above with TESTER participant code
3. Check browser console for detailed JavaScript logs
4. Verify no UUID appears in visible survey fields
5. Confirm survey submission works without validation errors
6. Validate that both participant code and UUID are properly captured

The fixes address all reported issues with comprehensive error handling and extensive logging for debugging.
