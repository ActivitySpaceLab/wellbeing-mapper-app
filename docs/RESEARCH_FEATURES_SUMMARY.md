---
layout: default
title: Research Features
description: Study participation tools and features for the Wellbeing Mapper
---

# Wellbeing Mapper - Research Features Summary

## Overview

This document summarizes the major features of the Wellbeing Mapper app to support research participation with end-to-end encryption. These features enable secure data collection for the research study in Italy.

## Key Features

### 1. Two-Way Participation System ✨

Users can now choose between two modes when starting the app:

- **🏠 Private Mode**: Personal use only, no data sharing
- **🔬 Research Mode**: Participate in the study

**Implementation:**
- `ParticipationSelectionScreen`: New UI for mode selection
- `ParticipationSettings` model: Manages participation preferences
- Site-specific participant code entry and validation

### 2. End-to-End Encryption System 🔐

**Hybrid Encryption Approach:**
- **AES-256-GCM**: Fast encryption for data payload
- **RSA-4096-OAEP**: Secure key exchange using research team public keys
- **Unique session keys**: Fresh AES key for each upload (forward secrecy)

**Security Features:**
- Data encrypted on device before transmission
- Research teams can only decrypt with their private keys
- No personal identifying information transmitted
- Site isolation (separate keys for each research location)

**Implementation:**
- `DataUploadService`: Core encryption and upload service
- `ServerConfig`: Site-specific server and key configuration
- `EncryptionResult`: Encryption operation results
- `fast_rsa` package integration for RSA operations

### 3. Advanced Data Sharing Consent System 🛡️

**Granular User Control:**
- Three-tier consent options: Full data, Partial data, Survey-only
- Interactive location cluster selection for partial sharing
- Opt-out approach: all areas selected by default, users uncheck sensitive locations
- Real-time data summary and privacy transparency

**Location Clustering:**
- Automatic grouping of GPS points into geographic areas (~1km radius)
- Privacy-friendly area names instead of exact coordinates
- Visit frequency and date range information for each cluster
- User-friendly selection interface with checkboxes

**Consent Management:**
- Persistent preference storage with history tracking
- Data Sharing Preferences screen for ongoing management
- Consent decisions saved per participant with timestamps
- Flexible filtering: users can share some areas while keeping others private

**Implementation:**
- `DataSharingConsent` model: Consent preferences with location cluster IDs
- `DataSharingConsentDialog`: Interactive consent interface with data preview
- `ConsentAwareDataUploadService`: Filtering service that respects user choices
- `DataSharingPreferencesScreen`: Ongoing preference management interface
- Enhanced database schema with `data_sharing_consent` table

### 4. Enhanced Notification System 🔔

**Dual-Notification Approach:**
- **Device-level notifications**: System notifications that work even when app is closed
- **In-app dialogs**: Traditional backup system for maximum reliability
- **2-week recurring schedule**: Automatic survey reminders every 14 days
- **Research-grade reliability**: Dramatically improved participant response rates

**Enhanced Testing Tools:**
- **Device notification testing**: Verify system-level notifications work properly
- **Permission diagnostics**: Check and troubleshoot notification permissions
- **Comprehensive statistics**: Monitor notification delivery and engagement
- **Research team tools**: Detailed diagnostics for troubleshooting

**Platform Support:**
- Cross-platform implementation (Android/iOS)
- Automatic permission handling with graceful fallbacks
- Background processing that survives app termination
- Minimal battery impact with efficient scheduling

**Implementation:**
- Enhanced `NotificationService`: Device notification support via flutter_local_notifications
- `NotificationSettingsView`: Comprehensive testing and management interface
- Platform-specific permission handling and diagnostics
- Dual notification strategy for maximum research reliability

### 5. Research Features 🌍

**Research:**
- Local demographics (building type)
- Health status tracking (general health questions)
- Area tracking for environmental correlation
- Local privacy compliance

**Implementation:**
- `ConsentFormScreen`: Dynamic consent based on research site
- Enhanced survey models with site-specific fields
- `SurveyModels`: Added `researchSite`, `suburb`, `generalHealth` fields

### 6. Secure Data Upload System 📤

**Features:**
- Bi-weekly automated upload scheduling
- Encrypted survey responses and location data
- Upload status tracking and retry logic
- Privacy-focused upload management UI
- **Consent-aware filtering:** Only uploads data according to user preferences

**Implementation:**
- `DataUploadScreen`: User interface for upload management
- `LocationTrack` model: Location data for research uploads
- Enhanced `SurveyDatabase`: Location tracking table and methods
- Upload synchronization and status tracking
- `ConsentAwareDataUploadService`: Respects user data sharing preferences

### 6. Enhanced Database Schema 🗄️

**New/Updated Tables:**
- `location_tracks`: GPS coordinates with accuracy and timestamps
- Enhanced survey tables with `research_site` field
- `consent_responses`: Complete consent tracking with all required fields
- **`data_sharing_consent`**: User consent preferences and location cluster selections

**Features:**
- Location data synchronized with uploads
- Site-specific survey storage
- Consent audit trail with granular preferences
- Local data retention management
- **Consent history tracking:** Full record of user data sharing decisions

## Technical Architecture

### Encryption Pipeline

```
Survey answers, consent, shared location history
           ↓
    AES-256-GCM, fresh key per upload
           ↓
    key wrapped with the study's RSA public key (OAEP-SHA-256)
           ↓
    base64 JSON envelope → HTTPS POST to the Wellbeing Mapper server
           ↓
    stored as a file; decrypted offline by the research team
```

### Server

The [Wellbeing Mapper server](https://github.com/ActivitySpaceLab/wellbeing-mapper-server)
stores each encrypted submission as a file and checks participant-code
hashes. It never decrypts anything. Its README covers deployment on a VPS,
keys, participant codes, backups and decryption.

## Research Team Setup Instructions

1. **Keys**: generate the study's RSA pair (server README, "Keys"); paste the
   public key into `ENV.researchPublicKey` in `lib/util/env.dart`; keep the
   private key offline.
2. **Server**: deploy it following the server README.
3. **Participant codes**: `python3 generate_participant_codes.py --count 500`
   in the server repository; put the hash file on the server and hand the
   codes to participants.
4. **App**: build with `--dart-define=SERVER_BASE_URL=https://your-host/api/v1`
   (see [Server Setup](SERVER_SETUP.md)).
5. **Decryption**: `python3 tools/decrypt_received.py --key private.pem --out decrypted/ received/`
   on a research team computer. The output format is described in
   [API Reference](API_REFERENCE.md), "Decrypted Data Structure".

## Privacy & Security Features

### Data Protection
- **Anonymous Identifiers**: Only UUID participant codes, no personal information
- **Encryption at Rest**: Private keys stored securely on research servers
- **Encryption in Transit**: HTTPS with TLS 1.3 for all communications
- **Forward Secrecy**: Compromised uploads don't affect other uploads
- **Site Isolation**: Research data completely isolated and secure

### Compliance Features
- **Informed Consent**: Comprehensive consent forms with granular permissions
- **Data Minimization**: Only collect necessary research data
- **Right to Withdraw**: Participants can stop participation at any time
- **Audit Trail**: Complete tracking of consent and data sharing decisions
- **Local Control**: Data remains on device until explicitly uploaded

### User Control
- **Upload Transparency**: Users see exactly what data is being shared
- **Upload Scheduling**: Clear indication of when uploads occur (bi-weekly)
- **Privacy Information**: Detailed explanations of encryption and data handling
- **Withdrawal Process**: Easy opt-out from research participation

## Documentation

### For Research Teams
- **[Server Setup Guide](docs/SERVER_SETUP.md)**: Complete server installation and configuration
- **[Encryption Setup Guide](docs/ENCRYPTION_SETUP.md)**: Detailed encryption configuration
- **[API Reference](docs/API_REFERENCE.md)**: Complete API documentation

### For Developers
- **[Developer Guide](docs/DEVELOPER_GUIDE.md)**: Development setup and workflows
- **[Architecture Guide](docs/ARCHITECTURE.md)**: System architecture and design patterns

## Testing & Validation

### Encryption Testing
```bash
# Run encryption tests
fvm flutter test test/encryption_test.dart

# Validate key pairs
node test-encryption.js

# End-to-end validation
fvm flutter drive --target=test_driver/encryption_driver.dart
```

### App Compilation
```bash
# Analyze code for errors
fvm flutter analyze

# Run all tests
fvm flutter test

# Build release version
fvm flutter build apk --release
```

## Deployment Checklist

### Pre-Deployment
- [ ] Generate RSA key pairs for both research sites
- [ ] Set up secure research servers with HTTPS
- [ ] Update app configuration with public keys and server URLs
- [ ] Test encryption/decryption pipeline end-to-end
- [ ] Verify compliance with research ethics requirements

### App Release
- [ ] Update public keys in `DataUploadService`
- [ ] Test Gauteng participation flow
- [ ] Validate all survey types and Gauteng-specific questions
- [ ] Verify location tracking and upload functionality
- [ ] Build and sign release versions

### Post-Deployment
- [ ] Monitor server logs for upload errors
- [ ] Verify data decryption on research servers
- [ ] Test upload retry mechanisms
- [ ] Validate consent form completeness
- [ ] Monitor app performance and user feedback

## Support

For technical issues:
1. **App Issues**: Check Flutter logs and error reporting
2. **Encryption Issues**: Verify key formats and server configuration
3. **Server Issues**: Check API logs and database connectivity
4. **Research Questions**: Contact the Planet4Health project team

## Future Enhancements

### Planned Features
- **Additional Research Sites**: Framework supports adding new locations easily
- **Advanced Analytics**: Enhanced data visualization for researchers
- **Key Rotation**: Automated key rotation for long-term studies
- **Offline Resilience**: Improved handling of network connectivity issues
- **Enhanced Privacy**: Additional privacy-preserving techniques

### Research Extensions
- **Environmental Data Integration**: Weather, air quality, noise levels
- **Activity Recognition**: Automatic detection of mental health relevant activities
- **Social Context**: Opt-in social interaction tracking
- **Intervention Triggers**: Proactive mental health support based on patterns
