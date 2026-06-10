# Changelog

## Recent Updates and Changes

### Google Play Store Compliance Fix
**Date**: July 31, 2025
**Impact**: Critical compliance update

#### Changes Made
- ✅ **Removed Restricted Permissions**: Eliminated `USE_EXACT_ALARM` and `SCHEDULE_EXACT_ALARM` from AndroidManifest.xml
- ✅ **Switched to Inexact Alarms**: Changed `AndroidScheduleMode.exactAllowWhileIdle` to `AndroidScheduleMode.inexactAllowWhileIdle`
- ✅ **Google Play Compliance**: App now meets Google Play Store policies for notification permissions
- ✅ **Improved User Experience**: Notifications appear at device-optimized times for better battery life

#### Files Modified
- `android/app/src/main/AndroidManifest.xml` - Removed restricted alarm permissions
- `lib/services/notification_service.dart` - Updated all notification scheduling to use inexact alarms
- `docs/TROUBLESHOOTING_GUIDE.md` - Added troubleshooting section for Google Play compliance
- `GOOGLE_PLAY_COMPLIANCE_FIX.md` - Comprehensive documentation of the fix

#### Technical Details
```dart
// Changed from exact alarms (requires special permission):
androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

// To inexact alarms (no special permission needed):
androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
```

#### Impact
- **No functionality loss**: Biweekly survey reminders continue working perfectly
- **Better battery efficiency**: Inexact alarms are more power-friendly
- **Google Play approval**: App can now be submitted without permission violations
- **Enhanced UX**: Notifications appear at optimal times rather than potentially inconvenient exact moments

### App Mode System Implementation
**Date**: Latest Update
**Impact**: Major feature enhancement

#### Changes Made
- ✅ **Flexible Mode System**: Implemented `AppMode` enum with Private, App Testing, and Research modes
- ✅ **Beta Configuration**: Single boolean flag to control beta vs. research release
- ✅ **Mode Switching UI**: Users can change modes via Settings → Change Mode
- ✅ **Welcome Screen Update**: New participation selection screen with beta indicators
- ✅ **App Mode Service**: Centralized mode management and validation

#### Files Modified
- `lib/models/app_mode.dart` - Core mode definitions and configuration
- `lib/services/app_mode_service.dart` - Mode management service
- `lib/ui/participation_selection_screen.dart` - Welcome screen with mode selection
- `lib/ui/change_mode_screen.dart` - Mode switching interface

#### Beta vs. Research Configuration
```dart
// Beta testing (current)
static const bool _isBetaPhase = true;
// Available modes: [Private, App Testing]

// Research release (future)
static const bool _isBetaPhase = false;
// Available modes: [Private, Research]
```

### Enhanced Notification System
**Date**: Recent Update  
**Impact**: Core feature enhancement

#### Changes Made
- ✅ **Bi-weekly Survey Reminders**: Automatic 14-day notification cycle
- ✅ **Testing Intervals**: Configurable 1-minute to hours for beta testing
- ✅ **Platform Support**: iOS and Android specific notification handling
- ✅ **Comprehensive Testing Tools**: Device/in-app notification testing
- ✅ **Statistics and Diagnostics**: Notification history and system status
- ✅ **Permission Management**: Notification permission checking and guidance

#### Files Modified
- `lib/services/notification_service.dart` - Core notification functionality
- `lib/ui/notification_settings_view.dart` - User interface for notification management
- `lib/main.dart` - Notification system initialization
- `lib/ui/home_view.dart` - Pending notification check on app startup

#### Key Features
- **Production Schedule**: 14-day intervals for research participants
- **Testing Mode**: 1-5 minute intervals for rapid beta testing
- **Dual Notification System**: Device notifications + in-app dialogs
- **Research Team Tools**: Comprehensive testing and diagnostic capabilities

### Welcome Screen and Onboarding Updates
**Date**: Latest Update
**Impact**: User experience improvement

#### Changes Made
- ✅ **Beta Version Indicator**: Clear "🧪 BETA VERSION" badge
- ✅ **Mode Selection Simplified**: Private vs. App Testing (not Research)
- ✅ **App Testing Explanation**: Detailed benefits and safety assurances
- ✅ **Contact Information Updated**: Development team contact for beta phase
- ✅ **Research Code Preserved**: Future research participation code maintained

#### User Experience Improvements
- Clear distinction between beta testing and future research participation
- Simplified onboarding flow without participant codes or consent forms
- Comprehensive explanations of what each mode provides
- Safety messaging that no real research data is collected in testing mode

### Documentation Overhaul
**Date**: Latest Update
**Impact**: Comprehensive documentation update

#### New Documentation
- ✅ **[Beta Testing Guide](docs/BETA_TESTING_GUIDE.md)** - Release preparation instructions
- ✅ **[Beta User Guide](docs/BETA_USER_GUIDE.md)** - Complete beta testing user guide
- ✅ **App Mode System Documentation** - Added to Developer Guide
- ✅ **Notification System Documentation** - Enhanced in Developer Guide

#### Updated Documentation
- ✅ **README.md**: Updated for beta status with new features
- ✅ **docs/index.md**: Restructured for beta testers, users, developers, researchers
- ✅ **DEVELOPER_GUIDE.md**: Added app mode system and notification features
- ✅ **Table of Contents**: Updated across all documentation files

#### Documentation Highlights
- Clear separation between beta testing and future research documentation
- Comprehensive release preparation instructions
- Beta testing user experience guide
- Technical implementation details for developers

### Privacy and Security Enhancements
**Date**: Recent Updates
**Impact**: Privacy and security improvements

#### Changes Made
- ✅ **Beta Privacy Protection**: All data stays local during beta testing
- ✅ **Mode-Based Data Handling**: Different privacy behaviors per mode
- ✅ **Clear Privacy Messaging**: Users understand what data is/isn't collected
- ✅ **Future Encryption Ready**: Research mode encryption prepared but disabled in beta

#### Privacy Features by Mode
- **Private Mode**: All data stays on device, no sharing
- **App Testing Mode**: All data stays local, no uploads, safe testing
- **Research Mode** *(future)*: Encrypted uploads with full consent

### Technical Infrastructure Improvements
**Date**: Recent Updates
**Impact**: Code quality and maintainability

#### Changes Made
- ✅ **Service Layer Organization**: Clear separation of concerns
- ✅ **Error Handling**: Comprehensive error handling and user feedback
- ✅ **Testing Infrastructure**: Beta testing tools and diagnostics
- ✅ **Platform Compatibility**: iOS and Android specific implementations
- ✅ **Configuration Management**: Centralized feature flags and settings

#### Code Quality Improvements
- Consistent error handling patterns
- Comprehensive logging for debugging
- Platform-specific code organization
- Clear service boundaries and responsibilities

## Upcoming Changes

### Research Release Preparation
**Target**: Future Release
**Impact**: Major mode transition

#### Planned Changes
- 🔄 **Enable Research Mode**: Set `_isBetaPhase = false`
- 🔄 **Participant Code System**: Restore research participant validation
- 🔄 **Consent Form Integration**: Enable full consent workflow
- 🔄 **Encryption Activation**: Enable RSA+AES encryption for research data
- 🔄 **Server Integration**: Connect to research data collection servers

### User Experience Enhancements
**Target**: Ongoing
**Impact**: Continuous improvement

#### Planned Improvements
- 🔄 **Feedback Integration**: Incorporate beta tester feedback
- 🔄 **Performance Optimization**: Battery and performance improvements
- 🔄 **Accessibility**: Enhanced accessibility features
- 🔄 **Localization**: Multi-language support for research sites

### Research Feature Completion
**Target**: Research Release
**Impact**: Full research functionality

#### Planned Features
- 🔄 **Multi-Site Support**: Configurable research site configurations
- 🔄 **Advanced Analytics**: Research-grade data collection and validation
- 🔄 **Compliance Features**: Full research ethics and privacy compliance
- 🔄 **Research Team Tools**: Advanced diagnostic and management features

---

## Version History

### v1.0.0-beta.x (Current)
- Beta testing version with Private and App Testing modes
- Comprehensive notification system with testing capabilities
- Enhanced documentation and user guides
- App mode system for flexible configuration

### v1.0.0 (Future)
- Research release with full study participation
- Encrypted data collection and upload
- Multi-site research support
- Complete consent and participant management system

---

*This changelog tracks major feature developments and will be updated with each significant release.*
