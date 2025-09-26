# Survey Export Formats Summary

## Overview
The Gauteng Wellbeing Mapper App surveys are now available in multiple formats to support different survey platforms and research workflows.

## Available Formats

### 1. XLSForm Excel (.xlsx)
**Files:**
- `Biweekly_Wellbeing_Survey_XLSForm.xlsx` 
- `Initial_Survey_XLSForm.xlsx`

**Use Cases:**
- ODK (Open Data Kit) Collect
- KoBoToolbox
- SurveyCTO
- Ona.io
- Other XLSForm-compatible platforms

**Features:**
- Standard XLSForm structure (survey, choices, settings sheets)
- Full conditional logic and validation rules
- Multi-language support ready
- Skip patterns and constraints

### 2. QSF JSON (.qsf)
**Files:**
- `Biweekly_Wellbeing_Survey.qsf` (29,561 bytes, 29 questions)
- `Initial_Demographics_Survey.qsf` (20,976 bytes, 19 questions)

**Use Cases:**
- Qualtrics survey platform
- Direct import into Qualtrics accounts
- Survey sharing between Qualtrics users

**Features:**
- Native Qualtrics format
- Preserves question types and validation
- Includes choice lists and labels
- Survey metadata and flow preserved

### 3. CSV Data (.csv)
**Files:**
- `biweekly_survey_data.csv` + `biweekly_choices_data.csv` + `biweekly_settings_data.csv`
- `initial_survey_data.csv` + `initial_choices_data.csv` + `initial_settings_data.csv`

**Use Cases:**
- Custom survey platform development
- Data analysis and survey review
- Manual survey creation
- Source data for other formats

**Features:**
- Human-readable format
- Easy to edit and modify
- Version control friendly
- Platform-agnostic

## Survey Content

### Biweekly Wellbeing Survey (29 questions)
**Domains Covered:**
- Sleep patterns (weeknight/weekend hours)
- Physical activity frequency  
- Mental wellbeing rating
- Physical wellbeing rating
- Social wellbeing rating
- Environmental wellbeing rating
- Financial wellbeing rating
- Community belonging and support
- Neighborhood trust and safety (day/night)
- Police presence and safety
- Green space access and quality
- Location sharing preferences

**Question Types:**
- Integer inputs (sleep hours with 0-24 validation)
- Single-choice questions (wellbeing ratings, agreement scales)
- Multiple-choice questions (location sharing options)
- Descriptive text blocks

### Initial Demographics Survey (19 questions)
**Information Collected:**
- Age (integer, 13-120 validation)
- Geographic location (suburb for Gauteng)
- Ethnicity (multi-select, site-specific options)
- Gender identity
- Sexual orientation
- Place of birth
- Residence type (Barcelona-specific)
- Building type
- Household items (socioeconomic indicators)
- Education level
- Climate activism engagement
- General health status (Gauteng-specific)

**Site-Specific Logic:**
- Gauteng participants: suburb, local ethnicity options, health questions
- Barcelona participants: residence questions, European ethnicity options
- Universal questions: age, gender, education, etc.

## Generation Scripts

### create_xlsforms.py
```bash
python create_xlsforms.py
```
Generates Excel XLSForm files from CSV source data.

### create_qsf_surveys.py
```bash
python create_qsf_surveys.py
```
Generates QSF JSON files for Qualtrics import from CSV source data.

### validate_qsf.py
```bash
python validate_qsf.py
```
Validates QSF files and provides summary information.

## Platform-Specific Import Instructions

### XLSForm Platforms (ODK, KoBoToolbox, etc.)
1. Upload the .xlsx file to your platform
2. Review imported survey structure
3. Test on mobile devices
4. Configure data collection settings
5. Deploy to field teams

### Qualtrics
1. Login to Qualtrics account
2. Create Project → Survey → From file
3. Upload .qsf file
4. Review question flow and formatting
5. Customize branding and appearance
6. Configure survey options (anonymous, etc.)
7. Test survey preview
8. Publish when ready

### Custom Platforms
1. Parse CSV files programmatically
2. Map question types to platform equivalents
3. Implement validation rules
4. Create choice lists and skip logic
5. Test survey functionality

## Data Validation

### Built-in Validation Rules
- **Age**: Integer between 13-120 years
- **Sleep Hours**: Integer between 0-24 hours
- **Required Fields**: Configurable per question
- **Choice Constraints**: Single vs. multiple selection enforced

### Quality Assurance
- All generated files validated as proper format
- Question text and choice labels preserved
- Conditional logic properly structured
- Cross-platform compatibility verified

## File Maintenance

### Updating Surveys
1. Modify source CSV files (survey_data.csv, choices_data.csv, settings_data.csv)
2. Run generation scripts to create new export files
3. Test updated surveys on target platforms
4. Document changes in version control

### Version Control
- Source CSV files tracked in git
- Generated files (.xlsx, .qsf) can be tracked or generated on-demand
- Documentation maintained alongside code
- Changes logged in commit messages

## Technical Specifications

### XLSForm Compatibility
- Standard ODK XLSForm specification
- Compatible with XLSForm Online validator
- Supports advanced features (calculations, constraints)
- Multi-language ready structure

### QSF Format Details
- JSON structure matching Qualtrics API v3
- UTF-8 encoding for international characters
- Unique question and block IDs generated
- Survey metadata included (creation date, language, etc.)

### CSV Structure
- Standard comma-separated format
- UTF-8 encoding
- Headers match XLSForm specification
- Platform-agnostic field naming

## Support and Troubleshooting

### Common Issues
- **File encoding**: Ensure UTF-8 for special characters
- **Question IDs**: Must be unique within each survey
- **Skip logic**: Test conditional questions thoroughly
- **Choice lists**: Verify all referenced lists exist

### Platform-Specific Notes
- **ODK**: Test on Android devices for UI compatibility
- **Qualtrics**: Review question types after import
- **KoBoToolbox**: Check GPS location functionality
- **Custom platforms**: Implement proper validation

## Research Ethics Compliance

### Privacy Features
- Anonymous response collection supported
- No personally identifiable information required
- Location sharing fully optional
- Clear consent language included

### Data Security
- No hardcoded server endpoints in surveys
- Configurable data storage locations
- Encryption recommendations provided
- Access control considerations documented

---

*Last Updated: August 2025*
*Survey Version: 1.0*
*Generated Files: Validated and Ready for Production*
