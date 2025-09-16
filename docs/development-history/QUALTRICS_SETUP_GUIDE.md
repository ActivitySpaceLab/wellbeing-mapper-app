# Qualtrics Survey Setup Guide

## Current Status
✅ **FIXED**: Updated survey URLs to working test surveys
✅ **FIXED**: Internet connectivity checking implemented
✅ **Ready for Testing**: App now requires internet connection for surveys

## Immediate Testing
The app now uses these working test survey URLs:
- **Initial Survey**: `https://pretoria.eu.qualtrics.com/jfe/form/SV_byJSMxWDA88icbY`
- **Biweekly Survey**: `https://pretoria.eu.qualtrics.com/jfe/form/SV_3aNJIQJXHPCyaOi`

**Internet Required**: The app now checks for internet connectivity before loading surveys and shows a clear dialog if no connection is available.

## Setting Up Your Own Qualtrics Surveys

### Step 1: Create Qualtrics Account
1. Go to [Qualtrics.com](https://www.qualtrics.com)
2. Sign up for an account (University of Pretoria may have institutional access)
3. Create a new project

### Step 2: Create Initial Survey
1. **Create New Survey** → Choose "Survey" → Start from scratch
2. **Add Questions** for your initial demographic survey:
   - Age range
   - Gender
   - Location/suburb
   - Other demographic questions
3. **Add Hidden Fields** (CRITICAL):
   - Add a "Text Entry" question
   - Question Text: "Participant ID" 
   - Advanced Options → Question ID → Set to match `participant_id`
   - Advanced Options → Make this question hidden from respondents
   - Add another "Text Entry" question for "Participant UUID"
   - Question ID → Set to match `participant_uuid`
   - Make this hidden as well

### Step 3: Create Biweekly Survey  
1. **Create New Survey** for recurring wellbeing questions
2. **Add Questions**:
   - Wellbeing scale (1-10)
   - Stress level
   - Life satisfaction
   - Location-specific questions
3. **Add Hidden Fields**:
   - `participant_id` (same as initial survey)
   - `participant_uuid` (same as initial survey)  
   - `locations` field for encrypted location data

### Step 4: Configure Hidden Fields
For each hidden field:
1. **Question Type**: Text Entry → Single Line
2. **Question Text**: Use descriptive name (won't be shown)
3. **Advanced Options**:
   - ✅ "Force Response" OFF (important!)
   - ✅ "Request Response" OFF 
   - ✅ "Hide this question" ON
4. **Question ID**: Set to exact field names:
   - `participant_id`
   - `participant_uuid` 
   - `locations` (biweekly only)

### Step 5: Publish Surveys
1. **Preview** each survey to test
2. **Publish** surveys (important - unpublished surveys show "Survey Not Found")
3. **Copy Survey URLs** from the "Distribute" tab

### Step 6: Update App URLs
Replace the URLs in `/lib/services/qualtrics_survey_service.dart`:

```dart
// Replace these with YOUR survey URLs
static const String _initialSurveyUrl = 'https://your-institution.qualtrics.com/jfe/form/SV_YourInitialSurveyID';
static const String _biweeklySurveyUrl = 'https://your-institution.qualtrics.com/jfe/form/SV_YourBiweeklySurveyID';
```

### Step 7: Test Integration
1. Build and install updated app
2. Test with TESTER participant code
3. Check browser console for field population logs
4. Verify hidden fields receive data but aren't visible
5. Test survey submission

## Hidden Field Verification

### Check Hidden Fields Work
1. **Preview Survey** in Qualtrics
2. **View Source** in browser (F12 → Elements)
3. **Search for field names**: Look for `participant_id`, `participant_uuid`, `locations`
4. **Verify they exist** but are styled with `display: none` or similar

### Test Data Capture
1. **Submit test survey** through app
2. **Check Qualtrics Results** 
3. **Verify data appears** in participant_id and other hidden fields
4. **Confirm no visible confusion** for users

## Troubleshooting

### "Survey Not Found" Error
- ✅ **Survey is published** (not just saved as draft)
- ✅ **URL is correct** (copy from Qualtrics "Distribute" tab)
- ✅ **Survey is active** (not expired or limited responses)

### Hidden Fields Not Working
- ✅ **Field names match exactly** (`participant_id`, `participant_uuid`, `locations`)
- ✅ **Fields are marked as hidden** in Qualtrics
- ✅ **"Force Response" is OFF** for hidden fields
- ✅ **JavaScript console shows** field population logs

### Validation Errors on Submission
- ✅ **Hidden fields are not required** 
- ✅ **Force Response is OFF** for hidden fields
- ✅ **All visible fields are completed** by user

## Field Names Reference

Make sure these exact field names are used in Qualtrics:

| Field Name | Purpose | Survey Type | Example Value |
|------------|---------|-------------|---------------|
| `participant_id` | Participant code | Both | "TESTER" |
| `participant_uuid` | Unique identifier | Both | "123e4567-e89b-..." |
| `locations` | Encrypted location data | Biweekly only | Encrypted JSON |

## Security Notes

- **Hidden fields are not secure** - they prevent user confusion but data is visible in browser source
- **Real security comes from encryption** - location data is encrypted before insertion
- **Participant codes should be non-identifying** - use codes like "P001", not names
- **UUIDs provide uniqueness** - prevents multiple people using same participant code

## Next Steps
1. ✅ **Test current app** with working URLs (should work now)
2. **Create your Qualtrics surveys** following this guide
3. **Update URLs** in the app code
4. **Test end-to-end** with your surveys
5. **Deploy to production** once verified

The app is now ready for testing with working survey URLs!
