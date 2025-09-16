# QSF Survey Export Documentation

## Overview
This document describes the QSF (Qualtrics Survey Format) export functionality for the Gauteng Wellbeing Mapper App surveys. QSF is the native format used by Qualtrics for importing and exporting surveys.

## Generated QSF Files

### 1. Biweekly_Wellbeing_Survey.qsf
- **File Size**: ~29KB
- **Purpose**: Biweekly wellbeing tracking survey
- **Questions**: 29 questions covering multiple wellbeing domains
- **Domains Covered**:
  - Sleep patterns (weeknight/weekend hours)
  - Physical activity frequency
  - Mental wellbeing rating
  - Physical wellbeing rating
  - Social wellbeing rating
  - Environmental wellbeing rating
  - Financial wellbeing rating
  - Community belonging and support
  - Neighborhood trust and safety
  - Green space access and quality
  - Location sharing preferences

### 2. Initial_Demographics_Survey.qsf
- **File Size**: ~21KB
- **Purpose**: Initial participant demographics and background
- **Questions**: 20 questions covering participant background
- **Information Collected**:
  - Age
  - Location (suburb for Gauteng participants)
  - Ethnicity (different options for Gauteng vs Barcelona)
  - Gender identity
  - Sexual orientation
  - Place of birth
  - Building type
  - Household items/socioeconomic indicators
  - Education level
  - Climate activism engagement
  - General health status

## QSF Structure

Each QSF file contains:

### Survey Metadata
```json
{
  "SurveyEntry": {
    "SurveyID": "survey_identifier",
    "SurveyName": "Human-readable survey name",
    "SurveyDescription": "Detailed description of survey purpose",
    "SurveyLanguage": "EN",
    "SurveyStatus": "Inactive"
  }
}
```

### Question Types Mapped
- **XLSForm → Qualtrics Mapping**:
  - `text` → Text Entry (TE)
  - `integer` → Text Entry with number validation (TE)
  - `select_one` → Multiple Choice Single Answer (MC/SAVR)
  - `select_multiple` → Multiple Choice Multiple Answer (MC/MAVR)
  - `note` → Display Text Block (DB)

### Choice Options
All select_one and select_multiple questions include their full choice lists with proper labels:

**Physical Activity Options**:
- Daily
- Most days (5-6 times per week)
- Some days (3-4 times per week)
- Few days (1-2 times per week)
- Never

**Wellbeing Rating Scale**:
- Excellent
- Very Good
- Good
- Fair
- Poor

**Agreement Scale**:
- Strongly Agree
- Agree
- Neither Agree nor Disagree
- Disagree
- Strongly Disagree

## Import Instructions for Qualtrics

### Step 1: Access Qualtrics
1. Log into your Qualtrics account
2. Navigate to your dashboard

### Step 2: Import Survey
1. Click "Create Project"
2. Select "Survey"
3. Choose "Import from file"
4. Upload the desired .qsf file:
   - `Biweekly_Wellbeing_Survey.qsf` for the biweekly survey
   - `Initial_Demographics_Survey.qsf` for the demographics survey

### Step 3: Review and Customize
After import, you should:
1. **Review question text** - Ensure all questions imported correctly
2. **Check validation rules** - Verify number ranges and constraints
3. **Test survey flow** - Preview the survey to ensure proper navigation
4. **Customize appearance** - Apply your organization's branding
5. **Set up survey options** - Configure anonymous responses, progress bar, etc.
6. **Review choice randomization** - Decide if answer choices should be randomized

### Step 4: Survey Configuration
Consider these Qualtrics-specific settings:
- **Anonymous Responses**: Recommended for research ethics
- **Survey Protection**: Password protection if needed
- **Response Options**: Allow back/forward navigation
- **Save and Continue**: Enable for longer surveys
- **Mobile Optimization**: Ensure responsive design

## Validation and Data Types

### Number Validation
- Age field: Should accept integers between 13-120
- Sleep hours: Should accept integers between 0-24

### Text Validation
- Suburb field: Free text entry for location
- Open-ended responses: No character limits applied

### Choice Validation
- Single-select questions: Only one choice allowed
- Multi-select questions: Multiple choices allowed (ethnicity questions)

## Data Export Considerations

When using these surveys in Qualtrics:

1. **Data Export Tags**: Each question has a meaningful export tag matching the original XLSForm name
2. **Response Format**: Responses will match the original choice values
3. **Date/Time**: Survey start and end times are automatically captured
4. **Response ID**: Qualtrics generates unique response IDs

## Multi-Site Configuration

The surveys include conditional logic for different research sites:
- **Gauteng-specific questions**: Suburb, ethnicity options, general health
- **Barcelona-specific questions**: Lives in Barcelona, different ethnicity options
- **Universal questions**: Age, gender, education, wellbeing ratings

## Quality Assurance

Before deploying imported surveys:
1. **Test all question types** - Ensure proper display and functionality
2. **Verify choice lists** - Check all options are present and correctly labeled
3. **Test on mobile** - Confirm responsive design works properly
4. **Preview flow** - Walk through entire survey experience
5. **Test data export** - Verify exported data matches expected format

## Technical Notes

- **Character Encoding**: QSF files use UTF-8 encoding
- **Question IDs**: Sequential (QID1, QID2, etc.) for easy reference
- **Block Structure**: Single block containing all questions
- **Language**: English (EN) set as default
- **Validation**: Number fields include appropriate validation rules

## Troubleshooting Common Issues

### Import Failures
- ✅ **JSON parse errors**: Fixed - Removed null values that caused "invalid character 'N'" errors
- Ensure .qsf file is valid JSON
- Check file size limits in Qualtrics
- Verify account permissions for survey creation

### Display Issues
- Review question text formatting
- Check for special characters in labels
- Verify choice option display

### Validation Problems
- Review number field constraints
- Check required field settings
- Test skip logic if applicable

## File Maintenance

The QSF files are generated from the CSV source files using `create_qsf_surveys.py`. To update:

1. Modify the source CSV files (survey_data.csv, choices_data.csv, settings_data.csv)
2. Run the conversion script: `python create_qsf_surveys.py`
3. New QSF files will be generated with current timestamp
4. Re-import into Qualtrics to apply changes

## Version History

- **v1.1** (August 2025): Fixed JSON parse error by removing null values that caused Qualtrics import failures
- **v1.0** (August 2025): Initial QSF export functionality
- Generated from XLSForm CSV data
- Support for both biweekly and initial surveys
- Full choice option mapping
- Validation rule preservation
