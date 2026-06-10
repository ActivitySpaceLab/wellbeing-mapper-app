# Qualtrics Survey Mapping Guide
## Updated: August 11, 2025

This document provides the complete mapping between app survey data and Qualtrics survey questions using simple text field approach for maximum reliability.

## Survey URLs (Published and Active)
- **Initial Survey**: https://pretoria.eu.qualtrics.com/jfe/form/SV_8pudN8qTI6iQKY6
- **Biweekly Survey**: https://pretoria.eu.qualtrics.com/jfe/form/SV_aXmfOtAIRmIVdfU  
- **Consent Survey**: https://pretoria.eu.qualtrics.com/jfe/form/SV_eu4OVw6dpbWY5hQ

## Survey IDs (for API)
- **Initial Survey ID**: `SV_8pudN8qTI6iQKY6`
- **Biweekly Survey ID**: `SV_aXmfOtAIRmIVdfU`
- **Consent Survey ID**: `SV_eu4OVw6dpbWY5hQ`

---

## Initial Survey Mapping
**Survey ID**: `SV_8pudN8qTI6iQKY6`

| App Field | Qualtrics QID | Description | Data Type |
|-----------|---------------|-------------|-----------|
| `participant_uuid` | QID1 | Participant UUID (Hidden) | Text |
| `age` | QID2 | Age | Text |
| `suburb` | QID3 | Suburb/community in Gauteng | Text |
| `race_ethnicity` | QID4 | Race/ethnicity | Text |
| `gender_identity` | QID5 | Gender identity | Text |
| `sexual_orientation` | QID6 | Sexual orientation | Text |
| `place_of_birth` | QID7 | Place of birth | Text |
| `building_type` | QID8 | Building type | Text |
| `household_items` | QID9 | Household items (JSON array as text) | Text |
| `education` | QID10 | Education level | Text |
| `climate_activism` | QID11 | Climate activism involvement | Text |
| `employment_status` | QID12 | Employment status | Text |
| `income` | QID13 | Income level | Text |
| `activities` | QID14 | Activities in last two weeks (JSON array as text) | Text |
| `living_arrangement` | QID15 | Living arrangement | Text |
| `relationship_status` | QID16 | Relationship status | Text |
| `general_health` | QID17 | General health rating | Text |
| `cheerful_spirits` | QID18 | WHO-5: I have felt cheerful in good spirits | Text |
| `calm_relaxed` | QID19 | WHO-5: I have felt calm and relaxed | Text |
| `active_vigorous` | QID20 | WHO-5: I have felt active and vigorous | Text |
| `woke_up_fresh` | QID21 | WHO-5: I woke up feeling fresh and rested | Text |
| `daily_life_interesting` | QID22 | WHO-5: My daily life has been filled with things that interest me | Text |
| `cooperate_with_people` | QID23 | I cooperate with people around me | Text |
| `improving_skills` | QID24 | Getting and improving my qualifications or skills is important to me | Text |
| `social_situations` | QID25 | I know how to behave in different social situations | Text |
| `family_support` | QID26 | My family have usually supported me throughout life | Text |
| `family_knows_me` | QID27 | There are people in my family who really know me | Text |
| `access_to_food` | QID28 | I have access to food I need | Text |
| `people_enjoy_time` | QID29 | There are people who enjoy spending time with me | Text |
| `talk_to_family` | QID30 | I can talk to my family about problems | Text |
| `friends_support` | QID31 | I have friends who can give me support | Text |
| `belong_in_community` | QID32 | I feel like I belong in my community | Text |
| `locationJson` | QID33 | Encrypted location data (Hidden) | Text |
| `submitted_at` | QID34 | Submission timestamp (Hidden) | Text |

---

## Biweekly Survey Mapping
**Survey ID**: `SV_aXmfOtAIRmIVdfU`

| App Field | Qualtrics QID | Description | Data Type |
|-----------|---------------|-------------|-----------|
| `participant_uuid` | QID1 | Participant UUID (Hidden) | Text |
| `activities` | QID2 | Activities in last two weeks (JSON array as text) | Text |
| `living_arrangement` | QID3 | Living arrangement | Text |
| `relationship_status` | QID4 | Relationship status | Text |
| `general_health` | QID5 | General health rating | Text |
| `cheerful_spirits` | QID6 | WHO-5: I have felt cheerful in good spirits | Text |
| `calm_relaxed` | QID7 | WHO-5: I have felt calm and relaxed | Text |
| `active_vigorous` | QID8 | WHO-5: I have felt active and vigorous | Text |
| `woke_up_fresh` | QID9 | WHO-5: I woke up feeling fresh and rested | Text |
| `daily_life_interesting` | QID10 | WHO-5: My daily life has been filled with things that interest me | Text |
| `cooperate_with_people` | QID11 | I cooperate with people around me | Text |
| `improving_skills` | QID12 | Getting and improving my qualifications or skills is important to me | Text |
| `social_situations` | QID13 | I know how to behave in different social situations | Text |
| `family_support` | QID14 | My family have usually supported me throughout life | Text |
| `family_knows_me` | QID15 | There are people in my family who really know me | Text |
| `access_to_food` | QID16 | I have access to food I need | Text |
| `people_enjoy_time` | QID17 | There are people who enjoy spending time with me | Text |
| `talk_to_family` | QID18 | I can talk to my family about problems | Text |
| `friends_support` | QID19 | I have friends who can give me support | Text |
| `belong_in_community` | QID20 | I feel like I belong in my community | Text |
| `family_stands_by_me` | QID21 | My family stands by me during difficult times | Text |
| `friends_stand_by_me` | QID22 | My friends stand by me during difficult times | Text |
| `treated_fairly` | QID23 | I feel that I am treated fairly by others | Text |
| `opportunities_responsibility` | QID24 | I have opportunities to show how responsible I am | Text |
| `secure_with_family` | QID25 | I feel secure when I am with my family | Text |
| `opportunities_abilities` | QID26 | I have opportunities to show my abilities | Text |
| `enjoy_cultural_traditions` | QID27 | I enjoy my community's traditions | Text |
| `environmental_challenges` | QID28 | Environmental challenges experienced recently | Text |
| `challenges_stress_level` | QID29 | How stressful were these challenges | Text |
| `coping_help` | QID30 | Who or what helped you manage these challenges | Text |
| `locationJson` | QID31 | Encrypted location data (Hidden) | Text |
| `submitted_at` | QID32 | Submission timestamp (Hidden) | Text |

---

## Consent Survey Mapping
**Survey ID**: `SV_eu4OVw6dpbWY5hQ`

Based on the Planet4Health Consent Form 2025 PILOT blueprint, the consent survey should capture:

| App Field | Qualtrics QID | Description | Data Type |
|-----------|---------------|-------------|-----------|
| `participant_code` | QID1 | Participant code | Text |
| `participant_uuid` | QID2 | Participant UUID (Hidden) | Text |
| `informed_consent` | QID3 | I give my consent to participate in this pilot study | Text (1=Yes, 0=No) |
| `data_processing_consent` | QID4 | I give my consent for my personal data to be processed by Qualtrics | Text (1=Yes, 0=No) |
| `race_ethnicity_consent` | QID5 | I give my consent to being asked about by race/ethnicity | Text (1=Yes, 0=No) |
| `health_consent` | QID6 | I give my consent to being asked about my health | Text (1=Yes, 0=No) |
| `sexual_orientation_consent` | QID7 | I give my consent to being asked about my sexual orientation | Text (1=Yes, 0=No) |
| `location_mobility_consent` | QID8 | I give my consent to being asked about my location and mobility | Text (1=Yes, 0=No) |
| `data_transfer_consent` | QID9 | I give my consent to transferring my personal data to countries outside Italy | Text (1=Yes, 0=No) |
| `public_reporting_consent` | QID10 | I give my consent to researchers reporting what I contribute publicly without my full name | Text (1=Yes, 0=No) |
| `data_sharing_researchers_consent` | QID11 | I give my consent to what I contribute being shared with national and international researchers | Text (1=Yes, 0=No) |
| `further_research_consent` | QID12 | I give my consent to what I contribute being used for further research or teaching purposes | Text (1=Yes, 0=No) |
| `public_repository_consent` | QID13 | I give my consent to what I contribute being placed in a public repository in deidentified form | Text (1=Yes, 0=No) |
| `followup_contact_consent` | QID14 | I give my consent to being contacted about participation in possible follow-up studies | Text (1=Yes, 0=No) |
| `participant_signature` | QID15 | Participant signature/name | Text |
| `consented_at` | QID16 | Consent timestamp | Text |

---

## Implementation Notes

### Simple Text Field Approach
All questions use simple text fields in Qualtrics to avoid complex question type matching issues. This ensures:
- **Reliability**: No question type mismatches
- **Flexibility**: Any data format can be stored
- **Speed**: Quick setup and testing
- **Debugging**: Easy to see exactly what data was sent

### Data Formats
- **JSON Arrays**: Stored as comma-separated text (e.g., "Work,Exercise,Socializing")
- **Numeric Scales**: Stored as text numbers (e.g., "4", "5")
- **Boolean Values**: Stored as "1" (true) or "0" (false)
- **Timestamps**: ISO 8601 format (e.g., "2025-08-11T16:30:00.000Z")
- **Location Data**: Encrypted JSON as text

### Testing Commands
```bash
# Test initial survey submission
dart test_initial_survey_simple.dart

# Test biweekly survey submission  
dart test_biweekly_survey_simple.dart

# Test consent survey submission
dart test_consent_survey_simple.dart
```

### API Endpoints
- **Base URL**: `https://pretoria.eu.qualtrics.com/API/v3`
- **Create Response**: `POST /surveys/{surveyId}/responses`
- **API Token**: `[SECURE] - Set in environment variable QUALTRICS_API_TOKEN`

---

## Status: ✅ READY FOR PRODUCTION
- All surveys published and active
- Simple text field mapping implemented
- App updated with new survey IDs
- Ready for data submission testing
