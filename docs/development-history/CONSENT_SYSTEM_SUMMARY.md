# Data Sharing Consent System - Implementation Summary

## Overview

The Gauteng Wellbeing Mapper now includes an advanced data sharing consent system that gives research participants complete control over their location data sharing preferences. This system was implemented to enhance user privacy and comply with research ethics requirements.

## Key Features

### ✅ **Three-Tier Consent Options**
1. **Share Full Location Data** - Complete 2-week location history with survey responses
2. **Share Partial Location Data** - User selects specific geographic areas to share
3. **Survey Responses Only** - No location data, only mood/wellbeing answers

### ✅ **Interactive Location Cluster Selection**
- Automatic geographic clustering of location data (~1km radius)
- Privacy-friendly area names instead of exact coordinates
- **Opt-out approach**: All areas start selected, users uncheck sensitive locations
- Real-time feedback showing selected areas and visit statistics

### ✅ **Persistent Consent Management**
- Data Sharing Preferences screen accessible from side drawer
- History of all consent decisions with timestamps
- Update preferences anytime without penalty
- Complete transparency about what data will be shared

### ✅ **Privacy-First Design**
- Real-time data summary before consent decisions
- Geographic clustering for privacy protection
- No minimum selection requirements (users can uncheck all areas)
- Clear explanations of consequences for each choice

## Technical Implementation

### Core Components

1. **Models** (`lib/models/data_sharing_consent.dart`)
   - `DataSharingConsent`: Consent record with location cluster selections
   - `LocationSharingOption`: Enum for three sharing options
   - `DataUploadSummary`: Preview data for consent decisions
   - `LocationCluster`: Geographic area groupings

2. **UI Components**
   - `DataSharingConsentDialog`: Interactive consent collection with data preview
   - `DataSharingPreferencesScreen`: Ongoing preference management interface

3. **Services** (`lib/services/consent_aware_upload_service.dart`)
   - `ConsentAwareDataUploadService`: Upload service that respects user preferences
   - Location clustering and filtering algorithms
   - Integration with existing encryption and upload systems

4. **Database Schema**
   - `data_sharing_consent` table: Stores user preferences and cluster selections
   - Enhanced `SurveyDatabase` with consent management methods

### Integration Points

- **Biweekly Survey Completion**: Triggers consent dialog for research participants
- **Side Drawer Menu**: Added "Data Sharing Preferences" option
- **Route System**: New navigation route for preferences screen
- **Existing Upload Service**: Enhanced with consent awareness

## User Experience Flow

### Initial Consent (Biweekly Survey)
1. Research participant completes biweekly survey
2. App shows data summary (X survey responses, Y location records, date range)
3. User chooses from three sharing options
4. If "Partial Data" selected:
   - All location areas are pre-checked
   - User unchecks areas they want to keep private (e.g., home, work)
   - Real-time feedback shows selection count
5. Consent decision is saved with timestamp
6. Data is filtered and uploaded according to user's choice

### Ongoing Management
1. User accesses "Data Sharing Preferences" from side menu
2. Views current consent settings and history
3. Can update preferences with immediate effect
4. Privacy information and explanations provided

## Privacy Protection Features

### Data Minimization
- Only uploads data according to explicit user consent
- Users can share some areas while keeping others completely private
- Option to share no location data at all (survey-only)

### Transparency
- Clear preview of exactly what data will be shared
- Real-time summary of location areas and visit counts
- History of all consent decisions
- No hidden data collection

### User Control
- Complete autonomy over data sharing decisions
- No minimum requirements or forced sharing
- Can change preferences at any time
- Can withdraw from any level of sharing

### Security
- All data encrypted before transmission
- Geographic clustering protects exact location privacy
- Anonymous participation codes (no personal identifiers)
- Consent preferences stored locally on device

## Benefits for Research

### Ethical Compliance
- Meets highest standards for informed consent
- Granular control exceeds regulatory requirements
- Transparent and auditable consent process
- Respects participant autonomy

### Data Quality
- Users more likely to participate when they have control
- Partial sharing still provides valuable data
- Maintains participant engagement through trust
- Reduces dropout due to privacy concerns

### Flexibility
- Accommodates different privacy comfort levels
- Allows research to continue even with partial data
- Supports longitudinal studies with changing preferences
- Enables analysis of consent patterns themselves

## File Changes Summary

### New Files Created
- `lib/models/data_sharing_consent.dart`
- `lib/ui/data_sharing_consent_dialog.dart`
- `lib/ui/data_sharing_preferences_screen.dart`
- `lib/services/consent_aware_upload_service.dart`

### Modified Files
- `lib/db/survey_database.dart` - Added consent table and methods
- `lib/models/route_generator.dart` - Added preferences screen route
- `lib/ui/side_drawer.dart` - Added menu item for preferences
- `lib/ui/recurring_survey_screen.dart` - Integrated consent-aware uploads
- `lib/ui/data_upload_screen.dart` - Updated to use consent service

### Documentation Updates
- `docs/USER_GUIDE.md` - Added data sharing preferences section
- `docs/RESEARCH_FEATURES_SUMMARY.md` - Added consent system documentation
- `docs/PRIVACY.md` - Comprehensive privacy policy update
- `docs/API_REFERENCE.md` - Added consent system APIs
- `docs/DEVELOPER_GUIDE.md` - Added technical implementation details

## Testing Recommendations

1. **Consent Dialog Flow**
   - Test all three sharing options
   - Verify location cluster display and selection
   - Confirm data preview accuracy

2. **Preference Management**
   - Test preference updates and persistence
   - Verify consent history display
   - Check navigation and UI responsiveness

3. **Data Filtering**
   - Verify filtered uploads match user selections
   - Test with various cluster combinations
   - Confirm survey-only uploads exclude location data

4. **Edge Cases**
   - No location data available
   - All clusters unchecked
   - Database migration from previous versions

## Future Enhancements

- Enhanced location clustering with reverse geocoding
- Time-based filtering options (specific date ranges)
- Export/import of consent preferences
- Analytics dashboard for researchers (anonymized consent patterns)
- Integration with external consent management systems

## Conclusion

The data sharing consent system represents a significant advancement in research data privacy and user autonomy. By giving participants granular control over their location data sharing, the app maintains the highest ethical standards while enabling valuable research to continue. The opt-out approach with pre-selected areas balances usability with privacy protection, making it easy for users to participate while protecting sensitive locations.
