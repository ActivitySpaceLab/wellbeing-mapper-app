# Beta Testing Guide

## Join the Beta Program

**[Join TestFlight Beta Testing →](https://testflight.apple.com/join/32WkKXs6)**

*Help us test the latest version of Wellbeing Mapper and provide valuable feedback before general release!*

### Requirements for Beta Testers
- iOS device (iPhone or iPad)
- iOS 12.0 or later
- TestFlight app installed from the App Store

---

## Developers' Guide to Beta Testing and Release

## Overview

The Wellbeing Mapper app is currently in **beta testing phase**. This document outlines the current beta configuration, how to prepare for the full research release, and what changes need to be made during the transition.

## Current Beta Configuration

### App Modes Available in Beta

1. **Private Mode**
   - Personal wellbeing tracking only
   - Data stays on device
   - No data sharing with researchers
   - All features available for personal use

2. **App Testing Mode**
   - Test all research features safely
   - Experience surveys and mapping functionality
   - NO real research data is collected
   - All responses stay local - nothing sent to servers
   - Allows users to familiarize themselves with research workflows

### What's Different in Beta vs. Full Release

| Feature | Beta Testing | Full Research Release |
|---------|-------------|----------------------|
| Available Modes | Private + App Testing | Private + Research |
| Research Participation | Simulated (no real data collection) | Real research participation |
| Participant Codes | Not required | Required for research mode |
| Consent Forms | Not shown (testing mode) | Required for research mode |
| Data Upload | Disabled (stays local) | Enabled for research participants |
| Survey Responses | Local testing only | Sent to research servers |
| Encryption | Not used in beta | Full encryption for research data |

## Beta Testing Features

### User Experience in Beta
- **Welcome Screen**: Shows "BETA VERSION" indicator
- **Mode Selection**: Choose between Private and App Testing
- **No Barriers**: No participant codes or consent forms required
- **Full Feature Access**: Can test all research features safely
- **Contact Info**: Shows development team contact instead of research team

### Beta Indicators in UI
- Beta badge in welcome screen
- Testing mode warnings in relevant screens
- Orange color scheme for testing mode
- Clear messaging that no real data is collected

## Preparing for Full Research Release

### Required Code Changes

#### 1. Update App Mode Configuration
**File**: `lib/models/app_mode.dart`

```dart
// Change this line from:
static const bool _isBetaPhase = true;

// To:
static const bool _isBetaPhase = false;
```

This single change will:
- Switch available modes from `[Private, App Testing]` to `[Private, Research]`
- Enable real research participation workflows
- Activate encryption and data upload features

#### 2. Restore Research Participation UI
**File**: `lib/ui/participation_selection_screen.dart`

1. **Update mode selection**:
   ```dart
   // Change back to:
   String _selectedMode = 'private'; // 'private', 'research'
   ```

2. **Uncomment participant code section**:
   - Remove comment blocks around `_buildParticipantCodeSection()` method
   - Restore participant code requirement in UI layout

3. **Update button text and flow**:
   ```dart
   // Change back to:
   'Continue to Consent Form' // instead of 'Start App Testing'
   ```

4. **Restore research flow in `_handleContinue()`**:
   - Re-enable consent form navigation
   - Restore participant code validation
   - Remove app testing mode handling

#### 3. Update Welcome Section
**File**: `lib/ui/participation_selection_screen.dart`

Remove beta version indicator:
```dart
// Remove this section from _buildWelcomeSection():
Container(
  // Beta testing notice - remove this entire container
),
```

#### 4. Restore Research Contact Information
**File**: `lib/ui/participation_selection_screen.dart`

Update contact information:
```dart
// Change button text:
'Contact Research Team' // instead of 'Contact Development Team'

// Restore full research team contact info in dialog
```

#### 5. Enable Encryption and Data Upload
**Files**: Various service files

- **Encryption Service**: Ensure RSA/AES encryption is enabled for research mode
- **Upload Service**: Enable automatic data upload for research participants  
- **Background Sync**: Activate bi-weekly sync for research data

### Testing the Release Version

#### Pre-Release Checklist

- [ ] Set `_isBetaPhase = false` in app_mode.dart
- [ ] Uncomment research participation code  
- [ ] Update UI text and flows for research mode
- [ ] Test research participant workflow with dummy codes
- [ ] Verify encryption is working
- [ ] Test data upload to staging servers
- [ ] Verify consent form displays correctly
- [ ] Test participant code validation
- [ ] Update contact information to research team
- [ ] Remove beta indicators from UI

#### Testing Research Mode

1. **Participant Code Testing**:
   - Test with valid format codes (e.g., "GP2024-001")
   - Test invalid format rejection
   - Test empty code validation

2. **Consent Flow Testing**:
   - Verify consent form displays
   - Test all consent checkboxes
   - Test consent completion workflow

3. **Data Collection Testing**:
   - Verify location tracking works
   - Test survey completion and upload
   - Verify encryption of uploaded data
   - Test bi-weekly notification schedule

## Version Control Strategy

### Beta Release Tags
- `v1.0.0-beta.1`, `v1.0.0-beta.2`, etc.
- Include "beta" in version strings
- Clear beta indicators in app

### Research Release Tags  
- `v1.0.0` for first research release
- Remove all beta indicators
- Full research functionality enabled

### Branch Strategy
- `main`: Always deployable version
- `beta`: Beta testing features and fixes
- `research`: Research release preparation
- `feature/*`: Individual feature development

## Documentation Updates for Release

### Files to Update
1. **README.md**: Remove beta references, add research info
2. **DEVELOPER_GUIDE.md**: Update app mode documentation
3. **USER_GUIDE.md**: Add research participation instructions
4. **docs/index.md**: Update from "beta testing" to "research ready"

### Research Team Documentation
- Participant recruitment guidelines
- Participant code generation procedures
- Data collection protocols
- Privacy and consent documentation

## Support and Contacts

### Beta Testing Phase
- **Development Team**: john.palmer@upf.edu
- **Issues**: GitHub repository issues
- **Feature Requests**: Development team contact

### Research Release Phase
- **Research Team**: 
  - Linda Theron: linda.theron@up.ac.za
  - Caradee Wright: Caradee.Wright@mrc.ac.za
  - John Palmer: john.palmer@upf.edu
- **Ethics Committee**: secretaria.cirep@upf.edu
- **Technical Issues**: Development team

## Timeline

### Current Status: Beta Testing
- ✅ Private mode fully functional
- ✅ App testing mode available
- ✅ All features testable safely
- ✅ No real research data collection

### Next Phase: Research Release
- 🔄 Participant recruitment begins
- 🔄 Consent system activation
- 🔄 Real data collection starts
- 🔄 Research server deployment

This guide ensures a smooth transition from beta testing to full research release while maintaining code quality and user experience.
