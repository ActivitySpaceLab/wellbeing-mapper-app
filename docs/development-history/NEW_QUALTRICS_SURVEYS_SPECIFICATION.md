# New Qualtrics Surveys Specification
*Created: September 12, 2025*

## 🎯 **Survey Creation Plan**

We need to create 3 new Qualtrics surveys to replace the existing ones and capture all data that the app sends.

---

## 📋 **New Initial Survey (34 Questions)**

**Purpose**: Capture all initial survey data including the 7 missing questions
**Format**: All questions as text fields for maximum compatibility
**Questions**: QID1_TEXT through QID34_TEXT

### **Questions 1-27 (Currently Working)**
1. **QID1_TEXT**: Participant UUID (hidden field)
2. **QID2_TEXT**: Age
3. **QID3_TEXT**: Suburb or community in Gauteng
4. **QID4_TEXT**: Race/ethnicity (comma-separated)
5. **QID5_TEXT**: Gender identity
6. **QID6_TEXT**: Sexual orientation
7. **QID7_TEXT**: Place of birth
8. **QID8_TEXT**: Building type
9. **QID9_TEXT**: Household items (comma-separated)
10. **QID10_TEXT**: Education level
11. **QID11_TEXT**: Climate activism involvement
12. **QID12_TEXT**: Employment status
13. **QID13_TEXT**: Income
14. **QID14_TEXT**: Activities in last two weeks (comma-separated)
15. **QID15_TEXT**: Living arrangement
16. **QID16_TEXT**: Relationship status
17. **QID17_TEXT**: General health (1-5)
18. **QID18_TEXT**: WHO-5: Cheerful spirits (0-5)
19. **QID19_TEXT**: WHO-5: Calm and relaxed (0-5)
20. **QID20_TEXT**: WHO-5: Active and vigorous (0-5)
21. **QID21_TEXT**: WHO-5: Woke up fresh and rested (0-5)
22. **QID22_TEXT**: WHO-5: Daily life filled with interesting things (0-5)
23. **QID23_TEXT**: Personal: I cooperate with people (1-5)
24. **QID24_TEXT**: Personal: Improving qualifications/skills important (1-5)
25. **QID25_TEXT**: Personal: Know how to behave in social situations (1-5)
26. **QID26_TEXT**: Personal: Family have supported me (1-5)
27. **QID27_TEXT**: Personal: Family knows me (scale)

### **Questions 28-34 (Currently Missing - CRITICAL)**
28. **QID28_TEXT**: Personal: Access to food (scale)
29. **QID29_TEXT**: Personal: People enjoy time with me (scale)
30. **QID30_TEXT**: Personal: Talk to family about problems (scale)
31. **QID31_TEXT**: Personal: Friends support me (scale)
32. **QID32_TEXT**: Personal: Belong in community (scale)
33. **QID33_TEXT**: Encrypted location data (hidden field)
34. **QID34_TEXT**: Submission timestamp (hidden field)

**Survey Configuration**:
- All fields as text input (most flexible)
- Hidden fields for QID1, QID33, QID34
- Export format: Q1, Q2, Q3... (without _TEXT suffix)

---

## 📋 **New Biweekly Survey (19 Questions)**

**Purpose**: Clone existing working survey
**Format**: All questions as text fields
**Questions**: QID1_TEXT through QID19_TEXT
**Status**: Current survey works perfectly, just needs cloning

### **All 19 Questions**
1. **QID1_TEXT**: Participant UUID (hidden)
2. **QID2_TEXT**: Activities in last two weeks
3. **QID3_TEXT**: Living arrangement
4. **QID4_TEXT**: Relationship status
5. **QID5_TEXT**: General health (1-5)
6. **QID6_TEXT**: WHO-5: Have you been in good spirits? (0-5)
7. **QID7_TEXT**: WHO-5: Have you felt calm and relaxed? (0-5)
8. **QID8_TEXT**: WHO-5: Have you felt active and vigorous? (0-5)
9. **QID9_TEXT**: WHO-5: Did you wake up feeling fresh and rested? (0-5)
10. **QID10_TEXT**: WHO-5: Has your daily life been filled with things that interest you? (0-5)
11. **QID11_TEXT**: Personal: I cooperate with people (1-5)
12. **QID12_TEXT**: Personal: Improving qualifications/skills important (1-5)
13. **QID13_TEXT**: Personal: Know how to behave in social situations (1-5)
14. **QID14_TEXT**: Personal: Family have supported me (1-5)
15. **QID15_TEXT**: Environmental challenges experienced (text)
16. **QID16_TEXT**: Stress level from challenges
17. **QID17_TEXT**: What helped cope with challenges (text)
18. **QID18_TEXT**: Encrypted location data (hidden)
19. **QID19_TEXT**: Submission timestamp (hidden)

---

## 📋 **New Consent Survey (16 Questions)**

**Purpose**: Clone existing working survey
**Format**: All questions as text fields (1/0 for checkboxes)
**Questions**: QID1_TEXT through QID16_TEXT
**Status**: Current survey works perfectly, just needs cloning

### **All 16 Questions**
1. **QID1_TEXT**: Participant Code
2. **QID2_TEXT**: Participant UUID (hidden)
3. **QID3_TEXT**: I GIVE MY CONSENT to participate in this pilot study (1/0)
4. **QID4_TEXT**: I GIVE MY CONSENT for my personal data to be processed by Qualtrics (1/0)
5. **QID5_TEXT**: I GIVE MY CONSENT to being asked about by race/ethnicity (1/0)
6. **QID6_TEXT**: I GIVE MY CONSENT to being asked about my health (1/0)
7. **QID7_TEXT**: I GIVE MY CONSENT to being asked about my sexual orientation (1/0)
8. **QID8_TEXT**: I GIVE MY CONSENT to being asked about my location and mobility (1/0)
9. **QID9_TEXT**: I GIVE MY CONSENT to transferring my personal data to countries outside South Africa (1/0)
10. **QID10_TEXT**: I GIVE MY CONSENT to researchers reporting what I contribute publicly without my full name (1/0)
11. **QID11_TEXT**: I GIVE MY CONSENT to what I contribute being shared with national and international researchers (1/0)
12. **QID12_TEXT**: I GIVE MY CONSENT to what I contribute being used for further research or teaching purposes (1/0)
13. **QID13_TEXT**: I GIVE MY CONSENT to what I contribute being placed in a public repository in deidentified form (1/0)
14. **QID14_TEXT**: I GIVE MY CONSENT to being contacted about participation in possible follow-up studies (1/0)
15. **QID15_TEXT**: Participant signature
16. **QID16_TEXT**: Consent timestamp

---

## 🔧 **Implementation Notes**

### **Critical Requirements**:
1. **All questions must be text fields** (not multiple choice, dropdowns, etc.)
2. **Question IDs must match exactly**: QID1_TEXT, QID2_TEXT, etc.
3. **Export format**: Must export as Q1, Q2, Q3... (without _TEXT suffix)
4. **Hidden fields**: QID1, QID33, QID34 for initial; QID2, QID18, QID19 for biweekly; QID2 for consent

### **Testing Requirements**:
- Test data submission for all question types
- Verify export format matches expected Q1, Q2, Q3... pattern
- Confirm no data loss for any of the 34 initial survey questions
- Validate encrypted location data and timestamp handling

### **Survey URLs**:
After creation, we'll need the new survey URLs to update the app constants.
