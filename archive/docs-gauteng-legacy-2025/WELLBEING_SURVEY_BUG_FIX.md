# Wellbeing Survey Response Bug Fix

## Issue Description
**Problem**: The wellbeing map was interpreting "Yes" responses as "No" and vice versa, causing inverted wellbeing scores.

**Root Cause**: Mismatch between survey UI option indices and scoring logic.

## Technical Details

### Survey UI Structure
```dart
static const List<String> yesNoOptions = [
  'Yes',    // Index 0
  'No',     // Index 1
];
```

### Previous (Incorrect) Flow
1. User selects "Yes" → UI stores index `0`
2. Service receives `0` and stores it directly as wellbeing score
3. Scoring logic: `0` = bad wellbeing, `1` = good wellbeing
4. **Result**: "Yes" responses scored as 0 points (bad), "No" responses scored as 1 point (good)

### Fixed Flow
1. User selects "Yes" → UI stores index `0`
2. Service receives `0` and converts: `0 (Yes) → 1 point`, `1 (No) → 0 points`
3. Scoring logic: `0` = bad wellbeing, `1` = good wellbeing
4. **Result**: "Yes" responses correctly score as 1 point (good), "No" responses score as 0 points (bad)

## Code Changes

### Modified File: `lib/services/wellbeing_survey_service.dart`

**Added conversion logic in `createResponse()` method:**
```dart
// Convert option indices to scoring values: 0 (Yes) -> 1 point, 1 (No) -> 0 points
int convertOptionToScore(int optionIndex) => optionIndex == 0 ? 1 : 0;

return WellbeingSurveyResponse(
  // ... 
  cheerfulSpirits: convertOptionToScore(cheerfulSpirits),
  calmRelaxed: convertOptionToScore(calmRelaxed),
  activeVigorous: convertOptionToScore(activeVigorous),
  wokeRested: convertOptionToScore(wokeRested),
  interestingLife: convertOptionToScore(interestingLife),
  // ...
);
```

## Verification

### Testing Steps
1. Take a wellbeing survey with all "Yes" answers
2. Check wellbeing map - should show **green circle with score 5**
3. Take a wellbeing survey with all "No" answers  
4. Check wellbeing map - should show **red circle with score 0**
5. Tap on map points to verify detail dialog shows correct Yes/No responses

### Expected Results
- **All "Yes" responses** → Score: 5/5 (Excellent) → Green color
- **All "No" responses** → Score: 0/5 (Very Low) → Red color
- **Mixed responses** → Score: 1-4/5 → Orange/Amber/Light Green colors

## Impact

### Data Integrity
- **New surveys**: Fixed immediately with this update
- **Existing surveys**: May have inverted scores in database
  - Option 1: Accept historical inversion (document in research)
  - Option 2: Create migration script to flip existing data
  - Option 3: Clear existing survey data (if acceptable for research)

### User Experience
- Wellbeing map now correctly reflects actual survey responses
- Color coding properly represents user's mental state
- Research data will be accurate for future analysis

## Recommendation
Test the fix thoroughly on both iOS and Android devices to ensure the conversion works correctly across platforms.

---
**Status**: ✅ Fixed in code, ready for testing
