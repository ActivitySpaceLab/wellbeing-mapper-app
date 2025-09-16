# Actual Qualtrics Mappings from App Source Code

This document contains the **actual** mappings used by the app to sync data to Qualtrics, extracted directly from the source code in `lib/services/qualtrics_api_service.dart`.

## Initial Survey Mapping (27 Questions)

Based on `_mapInitialSurveyToQualtrics()` function and confirmed by actual Qualtrics export data (Q1-Q27):

**Note**: The app code tries to send 34 questions, but the Qualtrics survey only accepts 27. Questions QID28-QID34 are being dropped.

| QID | App Field | Question/Description |
|-----|-----------|---------------------|
| QID1 → Q1 | participant_uuid | Participant UUID (hidden) - uses GlobalData.userUUID |
| QID2 → Q2 | age | Age |
| QID3 → Q3 | suburb | Suburb or community in Gauteng |
| QID4 → Q4 | ethnicity | Race/ethnicity (JSON array converted to comma-separated) |
| QID5 → Q5 | gender | Gender identity |
| QID6 → Q6 | sexuality | Sexual orientation |
| QID7 → Q7 | birth_place | Place of birth |
| QID8 → Q8 | building_type | Building type |
| QID9 → Q9 | household_items | Household items (JSON array converted to comma-separated) |
| QID10 → Q10 | education | Education level |
| QID11 → Q11 | climate_activism | Climate activism involvement |
| QID12 → Q12 | employment_status | Employment status |
| QID13 → Q13 | income | Income |
| QID14 → Q14 | activities | Activities in last two weeks (JSON array converted to comma-separated) |
| QID15 → Q15 | living_arrangement | Living arrangement |
| QID16 → Q16 | relationship_status | Relationship status |
| QID17 → Q17 | general_health | General health (1-5) |
| QID18 → Q18 | cheerful_spirits | WHO-5: Cheerful spirits (0-5) |
| QID19 → Q19 | calm_relaxed | WHO-5: Calm and relaxed (0-5) |
| QID20 → Q20 | active_vigorous | WHO-5: Active and vigorous (0-5) |
| QID21 → Q21 | woke_up_fresh | WHO-5: Woke up fresh and rested (0-5) |
| QID22 → Q22 | daily_life_interesting | WHO-5: Daily life filled with interesting things (0-5) |
| QID23 → Q23 | cooperate_with_people | Personal characteristic: I cooperate with people (1-5) |
| QID24 → Q24 | improving_skills | Personal characteristic: Improving qualifications/skills important (1-5) |
| QID25 → Q25 | social_situations | Personal characteristic: Know how to behave in social situations (1-5) |
| QID26 → Q26 | family_support | Personal characteristic: Family have supported me (1-5) |
| QID27 → Q27 | family_knows_me | Personal characteristic: Family knows me |

### Missing Data (Questions QID28-QID34 are sent by app but not captured in Qualtrics):
- QID28: `access_to_food` - Personal characteristic: Access to food
- QID29: `people_enjoy_time` - Personal characteristic: People enjoy time with me  
- QID30: `talk_to_family` - Personal characteristic: Can talk to family
- QID31: `friends_support` - Personal characteristic: Friends support me
- QID32: `belong_in_community` - Personal characteristic: Belong in community
- QID33: `locationJson` - Encrypted location data (hidden)
- QID34: `submitted_at` - Submission timestamp (hidden)

## Biweekly Survey Mapping (19 Questions)

Based on `_mapBiweeklySurveyToQualtrics()` function:

| QID | App Field | Question/Description |
|-----|-----------|---------------------|
| QID1 | participant_uuid | Participant UUID (hidden) - uses GlobalData.userUUID |
| QID2 | activities | Activities in last two weeks (JSON array converted to comma-separated) |
| QID3 | living_arrangement | Living arrangement |
| QID4 | relationship_status | Relationship status |
| QID5 | general_health | General health (1-5) |
| QID6 | cheerful_spirits | WHO-5: Have you been in good spirits? (0-5) |
| QID7 | calm_relaxed | WHO-5: Have you felt calm and relaxed? (0-5) |
| QID8 | active_vigorous | WHO-5: Have you felt active and vigorous? (0-5) |
| QID9 | woke_up_fresh | WHO-5: Did you wake up feeling fresh and rested? (0-5) |
| QID10 | daily_life_interesting | WHO-5: Has your daily life been filled with things that interest you? (0-5) |
| QID11 | cooperate_with_people | Personal characteristic: I cooperate with people (1-5) |
| QID12 | improving_skills | Personal characteristic: Improving qualifications/skills important (1-5) |
| QID13 | social_situations | Personal characteristic: Know how to behave in social situations (1-5) |
| QID14 | family_support | Personal characteristic: Family have supported me (1-5) |
| QID15 | environmental_challenges | Environmental challenges experienced (text) |
| QID16 | challenges_stress_level | Stress level from challenges |
| QID17 | coping_help | What helped cope with challenges (text) |
| QID18 | locationJson | Encrypted location data (hidden) |
| QID19 | submitted_at | Submission timestamp (hidden) |

## Consent Form Mapping (16 Questions)

Based on `_mapConsentToQualtrics()` function:

| QID | App Field | Question/Description |
|-----|-----------|---------------------|
| QID1 | participant_code | Participant Code |
| QID2 | participant_uuid | Participant UUID (hidden) - uses GlobalData.userUUID |
| QID3 | informed_consent | I GIVE MY CONSENT to participate in this pilot study (1=yes, 0=no) |
| QID4 | data_processing_consent | I GIVE MY CONSENT for my personal data to be processed by Qualtrics (1=yes, 0=no) |
| QID5 | race_ethnicity_consent | I GIVE MY CONSENT to being asked about by race/ethnicity (1=yes, 0=no) |
| QID6 | health_consent | I GIVE MY CONSENT to being asked about my health (1=yes, 0=no) |
| QID7 | sexual_orientation_consent | I GIVE MY CONSENT to being asked about my sexual orientation (1=yes, 0=no) |
| QID8 | location_mobility_consent | I GIVE MY CONSENT to being asked about my location and mobility (1=yes, 0=no) |
| QID9 | data_transfer_consent | I GIVE MY CONSENT to transferring my personal data to countries outside South Africa (1=yes, 0=no) |
| QID10 | public_reporting_consent | I GIVE MY CONSENT to researchers reporting what I contribute publicly without my full name (1=yes, 0=no) |
| QID11 | data_sharing_researchers_consent | I GIVE MY CONSENT to what I contribute being shared with national and international researchers (1=yes, 0=no) |
| QID12 | further_research_consent | I GIVE MY CONSENT to what I contribute being used for further research or teaching purposes (1=yes, 0=no) |
| QID13 | public_repository_consent | I GIVE MY CONSENT to what I contribute being placed in a public repository in deidentified form (1=yes, 0=no) |
| QID14 | followup_contact_consent | I GIVE MY CONSENT to being contacted about participation in possible follow-up studies (1=yes, 0=no) |
| QID15 | participant_signature | Participant signature |
| QID16 | consented_at | Consent timestamp |

## Key Notes

1. **All data is sent as `QID#_TEXT`** - The app uses simple text fields for maximum reliability
2. **JSON arrays are converted to comma-separated strings** - For fields like activities, household_items, ethnicity
3. **participant_uuid uses GlobalData.userUUID** - Not from the survey data itself
4. **Hidden fields** - location data and timestamps are included but not visible to participants
5. **Consent values are binary** - 1 for checked/yes, 0 for unchecked/no

## Survey IDs

- Initial Survey: `SV_8pudN8qTI6iQKY6`
- Biweekly Survey: `SV_aXmfOtAIRmIVdfU`
- Consent Survey: `SV_eWjaIVtwRLEMNGS`
