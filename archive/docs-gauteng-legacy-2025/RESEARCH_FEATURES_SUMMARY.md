---
layout: default
title: Research Features
description: Study participation tools and features for the Gauteng Wellbeing Mapper
---

# Gauteng Wellbeing Mapper - Research Features Summary

## Overview

This document summarizes the major features of the Gauteng Wellbeing Mapper app to support research participation with end-to-end encryption. These features enable secure data collection for the research study in Gauteng, South Africa.

## Key Features

### 1. Two-Way Participation System ✨

Users can now choose between two modes when starting the app:

- **🏠 Private Mode**: Personal use only, no data sharing
- **🇿🇦 Gauteng Research**: Participate in South African research study

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

### 5. Gauteng Research Features 🌍

**Gauteng Research:**
- South African demographics (ethnicity, building type)
- Health status tracking (general health questions)
- Suburb/area tracking for environmental correlation
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
Survey Data + Location Tracks
           ↓
    JSON Serialization
           ↓
    AES-256-GCM Encryption (random key)
           ↓
    RSA-4096-OAEP Key Encryption
           ↓
    Base64 Encoding: encrypted_key|encrypted_data
           ↓
    HTTPS POST to Research Server
           ↓
    Secure Storage (encrypted)
```

### Multi-Site Configuration
```dart
static const Map<String, ServerConfig> _serverConfigs = {
  'gauteng': ServerConfig(
    baseUrl: 'https://gauteng-research.domain.com',
    uploadEndpoint: '/api/v1/participant-data',
    publicKey: '''-----BEGIN PUBLIC KEY-----
    [RSA-4096 PUBLIC KEY FOR GAUTENG TEAM]
    -----END PUBLIC KEY-----''',
  ),
};
```

## Research Team Setup Instructions

### 1. Generate RSA Key Pairs

For each research site, generate a 4096-bit RSA key pair:

```bash
# Gauteng keys  
openssl genrsa -out gauteng_private_key.pem 4096
openssl rsa -in gauteng_private_key.pem -pubout -out gauteng_public_key.pem
```

### 2. Configure Mobile App

**Update Public Keys:**
Edit `lib/services/data_upload_service.dart` and replace the public key placeholders with your generated public keys.

**Update Server URLs:**
Replace `baseUrl` values with your actual research server domains.

**Rebuild App:**
```bash
fvm flutter clean
fvm flutter pub get
fvm flutter build apk --release
```

### 3. Set Up Research Servers

**Required Components:**
- HTTPS server with valid SSL certificate
- REST API endpoint for encrypted data uploads
- Database for storing encrypted participant data
- Data processing pipeline with private key decryption

**API Endpoint:**
```
POST /api/v1/participant-data
Content-Type: application/json

{
  "uploadId": "uuid-v4",
  "participantUuid": "uuid-v4", 
  "researchSite": "gauteng",
  "encryptedData": "base64-encoded-payload",
  "encryptionMetadata": { ... },
  "dataPeriod": { "start": "...", "end": "..." }
}
```

### 4. Data Decryption

Server-side decryption example (Node.js):

```javascript
function decryptUpload(encryptedPayload, encryptionMetadata, privateKey) {
  const [encryptedAESKey, encryptedData] = encryptedPayload.split('|');
  
  // Decrypt AES key with RSA private key
  const aesKey = crypto.privateDecrypt({
    key: privateKey,
    padding: crypto.constants.RSA_PKCS1_OAEP_PADDING,
    oaepHash: 'sha256'
  }, Buffer.from(encryptedAESKey, 'base64'));
  
  // Decrypt data with AES-256-GCM
  const iv = Buffer.from(encryptionMetadata.iv, 'base64');
  const decipher = crypto.createDecipherGCM('aes-256-gcm', aesKey);
  // ... complete decryption process
  
  return JSON.parse(decryptedData);
}
```

## Decrypted Data Structure

After successful decryption, research teams receive:

```json
{
  "participantUuid": "anonymous-uuid",
  "researchSite": "gauteng",
  "uploadTimestamp": "2025-07-23T10:30:00Z",
  "surveys": [
    {
      "type": "initial" | "recurring",
      "submittedAt": "2025-07-23T10:30:00Z",
      "responses": {
        "wellbeingScore": 1-10,
        "stressLevel": 1-10,
        "mood": "happy|neutral|sad|anxious|...",
        "suburb": "string",           // Gauteng only
        "generalHealth": "excellent|good|fair|poor",  // Gauteng only
        "ethnicity": "string",        // Site-specific options
        "buildingType": "string"      // Site-specific options
      }
    }
  ],
  "locationTracks": [
    {
      "timestamp": "2025-07-23T10:15:00Z",
      "latitude": -26.1076,
      "longitude": 28.0567,
      "accuracy": 10.5
    }
  ]
}
```

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
