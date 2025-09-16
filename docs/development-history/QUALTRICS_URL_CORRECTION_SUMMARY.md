# Qualtrics Survey URL Correction Summary

## Issue Identified
The app was using **incorrect survey URLs/IDs** that don't match the published Qualtrics surveys, which explains why data isn't appearing in the Qualtrics platform.

## Correct Survey URLs (Updated)
✅ **Initial Survey**: https://pretoria.eu.qualtrics.com/jfe/form/SV_bsb8iq0UiATXRJQ  
✅ **Biweekly Survey**: https://pretoria.eu.qualtrics.com/jfe/form/SV_eUJstaSWQeKykBM  
✅ **Consent Survey**: https://pretoria.eu.qualtrics.com/jfe/form/SV_4I7j91aabspz5YO  

## Files Updated

### Core API Services (Data Submission)
1. **`lib/services/qualtrics_api_service.dart`** ✅
   - ✅ Initial Survey ID: `SV_bsb8iq0UiATXRJQ` (correct)
   - ✅ Biweekly Survey ID: `SV_eUJstaSWQeKykBM` (correct)
   - ✅ Consent Survey ID: `SV_4I7j91aabspz5YO` (fixed from `SV_9o66CMEItVlFbdc`)

2. **`lib/services/qualtrics_api_service_v2.dart`** ✅
   - ✅ Initial Survey ID: `SV_bsb8iq0UiATXRJQ` (fixed from `SV_byJSMxWDA88icbY`)
   - ✅ Biweekly Survey ID: `SV_eUJstaSWQeKykBM` (fixed from `SV_3aNJIQJXHPCyaOi`)

### URL Generation Services
3. **`lib/models/route_generator.dart`** ✅
   - ✅ Initial Survey URL: fixed from `SV_byJSMxWDA88icbY` to `SV_bsb8iq0UiATXRJQ`
   - ✅ Biweekly Survey URL: fixed from `SV_3aNJIQJXHPCyaOi` to `SV_eUJstaSWQeKykBM`
   - ✅ Added Consent Survey URL: `SV_4I7j91aabspz5YO`

4. **`lib/services/survey_navigation_service.dart`** ✅
   - ✅ Initial Survey URL: fixed from `SV_02r8X8ePu0b2WNw` to `SV_bsb8iq0UiATXRJQ`
   - ✅ Biweekly Survey URL: fixed from `SV_88oXgY81cCwIxvw` to `SV_eUJstaSWQeKykBM`
   - ✅ Consent Survey URL: fixed from `SV_eYdj4iL3W8ydWJ0` to `SV_4I7j91aabspz5YO`

5. **`lib/services/qualtrics_survey_service.dart`** ✅
   - ✅ Initial Survey URL: fixed from `SV_byJSMxWDA88icbY` to `SV_bsb8iq0UiATXRJQ`
   - ✅ Biweekly Survey URL: fixed from `SV_3aNJIQJXHPCyaOi` to `SV_eUJstaSWQeKykBM`

6. **`lib/services/qualtrics_survey_service_new.dart`** ✅
   - ✅ Initial Survey URL: fixed from `SV_byJSMxWDA88icbY` to `SV_bsb8iq0UiATXRJQ`
   - ✅ Biweekly Survey URL: fixed from `SV_3aNJIQJXHPCyaOi` to `SV_eUJstaSWQeKykBM`

## Files Still Containing Old URLs (Debug/Setup Files)
These files are for debugging and setup purposes and can be updated separately:
- `lib/qualtrics_setup_guide.dart` (contains old test survey IDs)
- `lib/test_qualtrics_sync.dart` (test file)
- `test_qualtrics_sync.dart` (test file)
- `inspect_survey.dart` (debug tool)
- `lib/services/qualtrics_survey_creator.dart` (survey creation tool)

## Expected Result
After these corrections:
1. **Data submission should now reach the correct Qualtrics surveys**
2. **Survey responses should appear in the Qualtrics platform**
3. **All three survey types (Initial, Biweekly, Consent) point to the correct surveys**

## Testing Recommendation
1. Test completing an initial survey in the app
2. Test completing a biweekly survey in the app
3. Check the Qualtrics platform for new responses in surveys:
   - Initial: SV_bsb8iq0UiATXRJQ
   - Biweekly: SV_eUJstaSWQeKykBM
   - Consent: SV_4I7j91aabspz5YO

---
*Date: August 11, 2025*  
*Status: URLs Corrected - Ready for Testing*
