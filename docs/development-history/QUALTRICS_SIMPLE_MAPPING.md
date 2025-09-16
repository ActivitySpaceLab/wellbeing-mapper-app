# Gauteng Wellbeing Mapper - Qualtrics Survey Mapping

## Overview
This document provides the definitive mapping between the Flutter app's survey data and the simplified Qualtrics surveys. All Qualtrics questions are text fields for maximum reliability.

## Survey Structure

### Initial Survey (Wave 1 Only + All Waves Questions)
**Survey ID:** [TO BE UPDATED AFTER CREATION]  
**URL:** [TO BE UPDATED AFTER CREATION]

### Biweekly Survey (All Waves Questions Only)
**Survey ID:** [TO BE UPDATED AFTER CREATION]  
**URL:** [TO BE UPDATED AFTER CREATION]

### Consent Form
**Survey ID:** [TO BE UPDATED AFTER CREATION]  
**URL:** [TO BE UPDATED AFTER CREATION]

## Question Mapping

### Initial Survey Questions

| QID | App Field | Question Text | Expected Values |
|-----|-----------|---------------|-----------------|
| QID1 | participant_uuid | Participant UUID (hidden) | UUID string |
| QID2 | participant_code | Participant Code | String |
| QID3 | age | Age | Number |
| QID4 | suburb | Suburb or community in Gauteng | String |
| QID5 | race_ethnicity | Race/ethnicity | Black, Coloured, Indian, White, Other, Prefer not to say |
| QID6 | gender_identity | Gender identity | Male, Female, Transmale, Transfemale, Non-binary, Prefer not to say |
| QID7 | sexual_orientation | Sexual orientation | Heterosexual/straight, Lesbian, Gay, Bisexual, Queer, Other, Prefer not to say |
| QID8 | place_of_birth | Place of birth | South Africa, Other African country, Other country, Prefer not to say |
| QID9 | building_type | Building type | A brick house, A townhouse in a complex, An RDP house, A flat or apartment, A backyard room, Informal dwelling, Other |
| QID10 | household_items | Household items (comma-separated) | radio, television, refrigerator, microwave, internet access, computer, cellular smartphone, car, electric cooling devices |
| QID11 | education | Education level | Less than high school, High school, TVET college, Bachelor's degree, Professional degree, Post-graduate degree, Prefer not to say |
| QID12 | climate_activism | Climate activism involvement | all the time, often, sometimes, occasionally, never |
| QID13 | activities | Activities in last two weeks (comma-separated) | Unemployed looking for work, Unemployed not looking, Temporary/seasonal labour, Part-time employed, Full-time employed, Self employed, Skills development course, Student, Retired, Homemaker, Caring for children/ill relatives, Volunteered, Exercised, Vacation, Other |
| QID14 | living_arrangement | Living arrangement | alone, others |
| QID15 | relationship_status | Relationship status | Single, In a committed relationship/married, Separated, Divorced, Widowed |
| QID16 | general_health | General health (1-5) | 1=Excellent, 2=Very good, 3=Good, 4=Fair, 5=Poor |
| QID17 | cheerful_spirits | Cheerful spirits (0-5) | 0=At no time, 1=Some of the time, 2=Less than half, 3=More than half, 4=Most of the time, 5=All of the time |
| QID18 | calm_relaxed | Calm and relaxed (0-5) | 0=At no time, 1=Some of the time, 2=Less than half, 3=More than half, 4=Most of the time, 5=All of the time |
| QID19 | active_vigorous | Active and vigorous (0-5) | 0=At no time, 1=Some of the time, 2=Less than half, 3=More than half, 4=Most of the time, 5=All of the time |
| QID20 | woke_up_fresh | Woke up fresh and rested (0-5) | 0=At no time, 1=Some of the time, 2=Less than half, 3=More than half, 4=Most of the time, 5=All of the time |
| QID21 | daily_life_interesting | Daily life filled with interesting things (0-5) | 0=At no time, 1=Some of the time, 2=Less than half, 3=More than half, 4=Most of the time, 5=All of the time |
| QID22 | cooperate_with_people | I cooperate with people (1-5) | 1=Not at all, 2=A little, 3=Somewhat, 4=Quite a bit, 5=A lot |
| QID23 | improving_skills | Improving qualifications/skills important (1-5) | 1=Not at all, 2=A little, 3=Somewhat, 4=Quite a bit, 5=A lot |
| QID24 | social_situations | Know how to behave in social situations (1-5) | 1=Not at all, 2=A little, 3=Somewhat, 4=Quite a bit, 5=A lot |
| QID25 | family_support | Family have supported me (1-5) | 1=Not at all, 2=A little, 3=Somewhat, 4=Quite a bit, 5=A lot |
| QID26 | location_data | Encrypted location data (hidden) | Encrypted JSON string |
| QID27 | submitted_at | Submission timestamp (hidden) | ISO 8601 datetime string |

### Biweekly Survey Questions

| QID | App Field | Question Text | Expected Values |
|-----|-----------|---------------|-----------------|
| QID1 | participant_uuid | Participant UUID (hidden) | UUID string |
| QID2 | activities | Activities in last two weeks (comma-separated) | Same as initial survey QID13 |
| QID3 | living_arrangement | Living arrangement | alone, others |
| QID4 | relationship_status | Relationship status | Single, In a committed relationship/married, Separated, Divorced, Widowed |
| QID5 | general_health | General health (1-5) | 1=Excellent, 2=Very good, 3=Good, 4=Fair, 5=Poor |
| QID6 | cheerful_spirits | Cheerful spirits (0-5) | 0=At no time, 1=Some of the time, 2=Less than half, 3=More than half, 4=Most of the time, 5=All of the time |
| QID7 | calm_relaxed | Calm and relaxed (0-5) | 0=At no time, 1=Some of the time, 2=Less than half, 3=More than half, 4=Most of the time, 5=All of the time |
| QID8 | active_vigorous | Active and vigorous (0-5) | 0=At no time, 1=Some of the time, 2=Less than half, 3=More than half, 4=Most of the time, 5=All of the time |
| QID9 | woke_up_fresh | Woke up fresh and rested (0-5) | 0=At no time, 1=Some of the time, 2=Less than half, 3=More than half, 4=Most of the time, 5=All of the time |
| QID10 | daily_life_interesting | Daily life filled with interesting things (0-5) | 0=At no time, 1=Some of the time, 2=Less than half, 3=More than half, 4=Most of the time, 5=All of the time |
| QID11 | cooperate_with_people | I cooperate with people (1-5) | 1=Not at all, 2=A little, 3=Somewhat, 4=Quite a bit, 5=A lot |
| QID12 | improving_skills | Improving qualifications/skills important (1-5) | 1=Not at all, 2=A little, 3=Somewhat, 4=Quite a bit, 5=A lot |
| QID13 | social_situations | Know how to behave in social situations (1-5) | 1=Not at all, 2=A little, 3=Somewhat, 4=Quite a bit, 5=A lot |
| QID14 | family_support | Family have supported me (1-5) | 1=Not at all, 2=A little, 3=Somewhat, 4=Quite a bit, 5=A lot |
| QID15 | environmental_challenges | Environmental challenges experienced | Free text |
| QID16 | challenges_stress_level | Stress level from challenges (1-5) | 1=Not stressful at all, 2=Slightly stressful, 3=Moderately stressful, 4=Very stressful, 5=Extremely stressful |
| QID17 | coping_help | What helped cope with challenges | Free text |
| QID18 | location_data | Encrypted location data (hidden) | Encrypted JSON string |
| QID19 | submitted_at | Submission timestamp (hidden) | ISO 8601 datetime string |

### Consent Form Questions

| QID | App Field | Question Text | Expected Values |
|-----|-----------|---------------|-----------------|
| QID1 | participant_code | Participant Code | String |
| QID2 | participant_uuid | Participant UUID | UUID string |
| QID3 | informed_consent | Informed consent (1=yes, 0=no) | 1 or 0 |
| QID4 | data_processing | Data processing consent (1=yes, 0=no) | 1 or 0 |
| QID5 | location_data | Location data consent (1=yes, 0=no) | 1 or 0 |
| QID6 | survey_data | Survey data consent (1=yes, 0=no) | 1 or 0 |
| QID7 | data_retention | Data retention consent (1=yes, 0=no) | 1 or 0 |
| QID8 | data_sharing | Data sharing consent (1=yes, 0=no) | 1 or 0 |
| QID9 | voluntary_participation | Voluntary participation consent (1=yes, 0=no) | 1 or 0 |
| QID10 | participant_signature | Participant signature | String |
| QID11 | consented_at | Consent timestamp | ISO 8601 datetime string |

## Implementation Notes

1. **All questions are text fields** for maximum reliability and flexibility
2. **QID numbering is sequential** starting from QID1 for each survey
3. **Multi-select questions** (like activities, household items) are stored as comma-separated values
4. **Scale questions** store numeric values as strings (e.g., "0", "1", "2", etc.)
5. **Hidden fields** (UUID, timestamps, location data) are included but not visible to participants
6. **Data validation** should be performed in the Flutter app before sending to Qualtrics

## Data Processing

When sending data from Flutter to Qualtrics:
1. Convert multi-select arrays to comma-separated strings
2. Ensure numeric scales are converted to strings
3. Include hidden fields (UUID, timestamps, encrypted location data)
4. Use sequential QID mapping as defined above

This approach ensures:
- ✅ **Reliability**: Simple text fields reduce API errors
- ✅ **Flexibility**: Can handle any data type as text
- ✅ **Clarity**: Clear mapping between app fields and QIDs
- ✅ **Maintenance**: Easy to debug and modify
- ✅ **Speed**: Fast development and testing
