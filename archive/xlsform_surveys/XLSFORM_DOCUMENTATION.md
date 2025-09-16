# XLSForm Survey Workbooks

This directory contains two XLSForm-compliant Excel workbooks that replicate the surveys from the Gauteng Wellbeing Mapper mobile app:

## Files Created

1. **`Biweekly_Wellbeing_Survey_XLSForm.xlsx`** - The recurring biweekly wellbeing survey
2. **`Initial_Survey_XLSForm_XLSForm.xlsx`** - The one-time initial demographic survey

## XLSForm Structure

Each workbook contains three worksheets following the XLSForm standard:

### survey worksheet
- Contains the form structure with columns: type, name, label, hint, required, appearance, relevant, constraint, etc.
- Defines question types (text, integer, select_one, select_multiple, image, geopoint, etc.)
- Includes logic for conditional questions and validation

### choices worksheet  
- Contains answer options for multiple choice questions
- Organized by list_name, name, and label columns
- Supports different choice sets for different research sites (Gauteng vs Barcelona)

### settings worksheet
- Contains form metadata like title, form_id, version, and instance naming

## Question Types Included

- **Text input**: Age, suburb, diary entries
- **Integer input**: Sleep hours with validation (0-24)
- **Single choice (radio buttons)**: Gender, education, building type, etc.
- **Multiple choice (checkboxes)**: Ethnicity, household items, location sharing preferences
- **Rating scales**: Wellbeing ratings (Excellent to Poor)
- **Likert scales**: Agreement scales (Strongly Agree to Strongly Disagree)  
- **Image capture**: Photo diary functionality
- **Geolocation**: Current location capture
- **Grouping**: Digital diary section grouping

## Key Features

- **Conditional logic**: Questions appear based on research site (Gauteng vs Barcelona)
- **Data validation**: Age constraints, sleep hour limits
- **Optional questions**: Most questions are optional to reduce survey abandonment
- **Privacy controls**: Location data sharing preferences
- **Localization**: Different question sets for different research sites

## Usage with KoboToolkit

These workbooks can be directly uploaded to KoboToolkit or other XLSForm-compatible platforms:

1. Upload the Excel file to your form building platform
2. The platform will parse the three worksheets and create the interactive form
3. Deploy for data collection via web, mobile, or tablet interfaces

## Notes

- All questions are marked as optional (`required: no`) to match the app's behavior after recent updates
- The forms maintain the same question flow and logic as the mobile app
- Location data sharing options reflect the app's privacy-focused approach
- Both Gauteng and Barcelona research site variations are included where applicable

## Correspondence to Mobile App

These XLSForms accurately replicate:
- All question text and help text from the mobile app
- Choice options for different research sites  
- Question ordering and grouping
- Optional vs required field settings
- Data validation rules
- Conditional question display logic

The forms can be used for web-based data collection that mirrors the mobile app experience or for integration with other survey platforms that support the XLSForm standard.
