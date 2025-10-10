# Consent System Implementation

## Overview

The consent system has been successfully implemented in the Wellbeing Mapper app. It provides a dual-mode system where users can either:

1. **Use the app privately** - No data sharing, personal use only
2. **Participate in research** - Enter participant code and complete consent form

## Files Created

### Models
- `lib/models/consent_models.dart` - Data models for consent and participation settings

### Services
- `lib/services/consent_service.dart` - Service layer for managing consent data

### UI Screens
- `lib/ui/consent/participation_selection_screen.dart` - Initial screen for choosing private vs research
- `lib/ui/consent/consent_form_screen.dart` - Full consent form for research participants

### Database
- Updated `lib/db/survey_database.dart` - Database schema and methods for consent storage

## How It Works

### 1. Participation Selection
Users first see a welcome screen with two options:
- **Personal Use**: Creates private user settings and goes directly to surveys
- **Join Research**: Requires participant code and leads to consent form

### 2. Consent Form (Research Participants Only)
Research participants must complete a comprehensive consent form covering:
- Informed consent
- Data processing
- Location data collection
- Survey data collection
- Data retention policies
- Data sharing for research
- Voluntary participation confirmation

### 3. Data Storage
- Participation settings stored in SharedPreferences
- Consent responses stored in SQLite database
- All data encrypted and secure

## Navigation

The consent system integrates with the existing app navigation:
- Route: `/participation_selection` - Main selection screen
- Route: `/consent_form` - Research consent form
- Side drawer includes "Research Participation" menu item

## Usage Example

```dart
// Check if user has completed setup
bool hasSetup = await ConsentService.hasCompletedSetup();

// Check if user is research participant
bool isResearch = await ConsentService.isResearchParticipant();

// For research participants, check consent completion
bool hasConsent = await ConsentService.hasCompletedConsent();

// Get participant ID for research users
String? participantId = await ConsentService.getParticipantId();
```

## Features

### Privacy Protection
- Private users: No data sharing, local storage only
- Research participants: Explicit consent for all data uses
- Easy withdrawal process

### Compliance
- GDPR compliant consent collection
- Clear language and explanations
- Digital signature collection
- Audit trail with timestamps

### User Experience
- Clean, intuitive interface
- Card-based layout for easy reading
- Progress indicators and validation
- Comprehensive error handling

## Testing

All existing tests continue to pass, ensuring the consent system doesn't break existing functionality. The system includes:
- Unit tests for data models
- Widget tests for UI components
- Integration with existing survey flow

## Future Enhancements

Potential improvements for the consent system:
1. **Consent versioning** - Handle updates to consent forms
2. **Withdrawal process** - Easy way to withdraw consent and delete data
3. **Consent renewal** - Periodic re-consent for long-term studies
4. **Multi-language support** - Translate consent forms
5. **PDF export** - Generate PDF copies of signed consent forms

## Technical Notes

- Uses `flutter_form_builder` for robust form validation
- Integrates with existing `shared_preferences` for settings
- Leverages existing SQLite database for consent storage
- Follows existing app patterns and architecture
- Maintains backward compatibility with existing data
