# Participant Code Validation System

## Overview

The participant code validation system provides secure access control for research mode participation. This system ensures that only verified participants with valid codes can access research features while maintaining participant anonymity.

## Security Architecture

```
Participant Code → SHA-256 Hash → Server Lookup → Validation Response
       ↓                             ↓               ↓
   User Input                   Secure Storage    App Access Granted
```

## Key Components

### 1. Client-Side Validation Service
**File**: `lib/services/participant_validation_service.dart`

- **Code Hashing**: Uses SHA-256 to hash participant codes before transmission
- **Local Caching**: Stores validation status to prevent re-entry
- **Consent Recording**: Tracks consent completion and timestamps
- **Security**: Never stores plain-text codes locally

### 2. Participant Code Entry Screen
**File**: `lib/ui/participant_code_entry_screen.dart`

- **User Interface**: Clean, professional code entry form
- **Input Validation**: Real-time validation and error feedback
- **Security Guidance**: Information about code security and usage
- **Contact Information**: Research team contact details

### 3. Research Flow Integration
**Files**: 
- `lib/ui/participation_selection_screen.dart` - Updated research mode flow
- `lib/ui/consent_form_screen.dart` - Consent recording integration
- `lib/models/route_generator.dart` - Navigation routing

## User Experience Flow

### For New Research Participants
1. **Select Research Mode** → Participant code entry screen
2. **Enter Participant Code** → Validation against server
3. **Code Validation Success** → Proceed to consent form
4. **Complete Consent** → Access to main research features

### For Returning Participants
1. **Select Research Mode** → Automatic validation check
2. **Already Validated** → Skip directly to consent (if not completed) or main app
3. **Seamless Experience** → No re-entry of participant codes required

## Server Implementation Requirements

### Database Schema

#### Participant Codes Table
```sql
CREATE TABLE participant_codes (
    id SERIAL PRIMARY KEY,
    hashed_code VARCHAR(64) UNIQUE NOT NULL,  -- SHA-256 hash
    study_site VARCHAR(50) NOT NULL,          -- 'gauteng', 'barcelona', etc.
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT                                -- Optional researcher notes
);
```

#### Consent Records Table
```sql
CREATE TABLE consent_records (
    id SERIAL PRIMARY KEY,
    hashed_participant_code VARCHAR(64) NOT NULL,
    consent_timestamp TIMESTAMP NOT NULL,
    consent_version VARCHAR(10) DEFAULT '1.0',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (hashed_participant_code) REFERENCES participant_codes(hashed_code)
);
```

### API Endpoints

#### 1. Validate Participant Code
```
POST /api/v1/participants/validate
Content-Type: application/json

{
  "hashed_code": "a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3",
  "timestamp": "2025-08-08T12:00:00Z"
}
```

**Response** (Valid):
```json
{
  "valid": true,
  "study_site": "gauteng"
}
```

**Response** (Invalid):
```json
{
  "valid": false,
  "error": "Invalid participant code"
}
```

#### 2. Record Consent
```
POST /api/v1/participants/consent
Content-Type: application/json

{
  "hashed_participant_code": "a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3",
  "consent_timestamp": "2025-08-08T12:00:00Z",
  "consent_version": "1.0"
}
```

**Response**:
```json
{
  "success": true,
  "consent_id": "12345"
}
```

### Sample Node.js Implementation

```javascript
const express = require('express');
const bcrypt = require('bcrypt');
const crypto = require('crypto');
const { Pool } = require('pg');

const app = express();
app.use(express.json());

const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

// Validate participant code
app.post('/api/v1/participants/validate', async (req, res) => {
  try {
    const { hashed_code, timestamp } = req.body;
    
    // Rate limiting and validation would go here
    if (!hashed_code || !timestamp) {
      return res.status(400).json({ 
        valid: false, 
        error: 'Missing required fields' 
      });
    }
    
    // Check if code exists and is active
    const result = await pool.query(
      'SELECT study_site FROM participant_codes WHERE hashed_code = $1 AND is_active = true',
      [hashed_code]
    );
    
    if (result.rows.length > 0) {
      res.json({ 
        valid: true, 
        study_site: result.rows[0].study_site 
      });
    } else {
      res.status(404).json({ 
        valid: false, 
        error: 'Invalid participant code' 
      });
    }
  } catch (error) {
    console.error('Validation error:', error);
    res.status(500).json({ 
      valid: false, 
      error: 'Internal server error' 
    });
  }
});

// Record consent
app.post('/api/v1/participants/consent', async (req, res) => {
  try {
    const { hashed_participant_code, consent_timestamp, consent_version } = req.body;
    
    // Verify participant code exists
    const participantCheck = await pool.query(
      'SELECT id FROM participant_codes WHERE hashed_code = $1 AND is_active = true',
      [hashed_participant_code]
    );
    
    if (participantCheck.rows.length === 0) {
      return res.status(404).json({ 
        success: false, 
        error: 'Invalid participant code' 
      });
    }
    
    // Insert consent record
    const result = await pool.query(
      'INSERT INTO consent_records (hashed_participant_code, consent_timestamp, consent_version) VALUES ($1, $2, $3) RETURNING id',
      [hashed_participant_code, consent_timestamp, consent_version || '1.0']
    );
    
    res.status(201).json({ 
      success: true, 
      consent_id: result.rows[0].id.toString() 
    });
  } catch (error) {
    console.error('Consent recording error:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Internal server error' 
    });
  }
});
```

## Security Considerations

### 1. Code Hashing
- **Client-Side Hashing**: Participant codes are hashed using SHA-256 before transmission
- **No Plain Text**: Codes are never transmitted or stored in plain text
- **Salt Consideration**: For additional security, consider adding a salt to the hashing process

### 2. Rate Limiting
- **API Protection**: Implement rate limiting on validation endpoints
- **Brute Force Prevention**: Limit validation attempts per IP/timeframe
- **Monitoring**: Log and monitor for suspicious validation patterns

### 3. Database Security
- **Encrypted Storage**: Database should use encryption at rest
- **Access Control**: Restrict database access to authorized personnel only
- **Backup Security**: Ensure backups are also encrypted and secure

### 4. Network Security
- **HTTPS Only**: All communication must use HTTPS
- **Certificate Validation**: Proper SSL certificate validation
- **CORS Configuration**: Appropriate CORS settings for app domains

## Administrative Tools

### Adding Participant Codes
```javascript
// Script to add new participant codes
const addParticipantCode = async (plainCode, studySite) => {
  const hashedCode = crypto.createHash('sha256').update(plainCode).digest('hex');
  
  await pool.query(
    'INSERT INTO participant_codes (hashed_code, study_site) VALUES ($1, $2)',
    [hashedCode, studySite]
  );
  
  console.log(`Added participant code for ${studySite}: ${plainCode.substring(0, 3)}***`);
};

// Example usage
await addParticipantCode('GTNG001', 'gauteng');
await addParticipantCode('GTNG002', 'gauteng');
```

### Monitoring and Analytics
```sql
-- Check consent completion rates
SELECT 
    pc.study_site,
    COUNT(pc.id) as total_codes,
    COUNT(cr.id) as consented_participants,
    ROUND((COUNT(cr.id)::float / COUNT(pc.id)) * 100, 2) as consent_rate
FROM participant_codes pc
LEFT JOIN consent_records cr ON pc.hashed_code = cr.hashed_participant_code
WHERE pc.is_active = true
GROUP BY pc.study_site;

-- Recent consent activity
SELECT 
    DATE(consent_timestamp) as consent_date,
    COUNT(*) as consents_given
FROM consent_records 
WHERE consent_timestamp >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(consent_timestamp)
ORDER BY consent_date;
```

## Current Status

### Development Phase
- **No Active Codes**: System currently has no participant codes in validation list
- **Testing Ready**: All validation logic implemented and tested
- **Server Framework**: Complete API specification ready for implementation

### Activation Process
1. **Deploy Server**: Set up validation and consent recording endpoints
2. **Add Participant Codes**: Upload researcher-provided codes to database
3. **Enable Research Mode**: Update app configuration to allow research participation
4. **Monitor System**: Track validation attempts and consent completion

## Integration Notes

### App Configuration
The app currently returns this message for all validation attempts:
```
"No participant codes are currently active in the system. Please contact the research team."
```

When ready to activate:
1. Remove the early return in `validateParticipantCode()` method
2. Uncomment server communication code
3. Configure server URL in `ParticipantValidationService`

### Testing
- **Unit Tests**: Comprehensive validation logic testing
- **Integration Tests**: Server communication testing
- **Security Tests**: Hash verification and rate limiting tests

## Related Documentation
- [Server Setup Guide](SERVER_SETUP.md) - Complete server configuration
- [Encryption Setup](ENCRYPTION_SETUP.md) - Data encryption implementation
- [Privacy Policy](PRIVACY.md) - Data protection measures
- [Research Features](RESEARCH_FEATURES_SUMMARY.md) - Available research tools
