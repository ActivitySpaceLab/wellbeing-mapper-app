# Server Setup Guide for Wellbeing Mapper Research Data Collection

This guide provides comprehensive instructions for setting up secure data collection servers for the Wellbeing Mapper app's research participation features.

## Overview

The Wellbeing Mapper app supports encrypted data collection for research studies in two locations:
- **Barcelona, Spain** study
- **Gauteng, South Africa** study

Each study site requires:
1. A dedicated HTTPS server with REST API endpoints
2. RSA-4096 public/private key pair for encryption
3. Secure database for storing encrypted participant data
4. Data processing pipeline for decryption and analysis

## Architecture

```
Mobile App → RSA+AES Encryption → HTTPS POST → Server → Database
     ↓                                            ↓
Participant Data                           Encrypted Storage
- Survey responses                         - Cannot be read without
- Location tracks                            private key
- Demographics                            - Anonymized UUIDs only
```

## 1. Server Requirements

### Minimum System Requirements
- **OS**: Ubuntu 20.04 LTS or later, CentOS 8+, or similar
- **RAM**: 4GB minimum, 8GB recommended
- **Storage**: 100GB minimum, SSD recommended
- **CPU**: 2 cores minimum, 4 cores recommended
- **SSL Certificate**: Valid HTTPS certificate (Let's Encrypt or commercial)

### Software Dependencies
- **Node.js**: 18.x or later (recommended) OR Python 3.9+ OR equivalent
- **Database**: PostgreSQL 13+ (recommended) or MongoDB 4.4+
- **Web Server**: Nginx or Apache with reverse proxy
- **SSL**: Certbot for Let's Encrypt certificates

## 2. RSA Key Generation and Configuration

### Generate Key Pair

```bash
# Generate 4096-bit RSA private key
openssl genrsa -out research_private_key.pem 4096

# Extract public key
openssl rsa -in research_private_key.pem -pubout -out research_public_key.pem

# Verify key pair
openssl rsa -in research_private_key.pem -noout -text
```

### Key Security
- **Private Key**: Store securely with restricted file permissions (600)
- **Public Key**: This will be embedded in the mobile app
- **Backup**: Create encrypted backups of private keys
- **Rotation**: Plan for annual key rotation

## 3. Mobile App Configuration

### Add Public Key to App

Edit `/lib/services/data_upload_service.dart` and update the server configurations:

```dart
static const Map<String, ServerConfig> _serverConfigs = {
  'barcelona': ServerConfig(
    baseUrl: 'https://your-barcelona-server.com',
    uploadEndpoint: '/api/v1/participant-data',
    publicKey: '''-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA...
[YOUR BARCELONA RSA PUBLIC KEY HERE]
...
-----END PUBLIC KEY-----''',
  ),
  'gauteng': ServerConfig(
    baseUrl: 'https://your-gauteng-server.com',
    uploadEndpoint: '/api/v1/participant-data',
    publicKey: '''-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA...
[YOUR GAUTENG RSA PUBLIC KEY HERE]
...
-----END PUBLIC KEY-----''',
  ),
};
```

### Rebuild and Deploy App
After updating the public keys:
```bash
cd wellbeing-mapper-app
fvm flutter clean
fvm flutter pub get
fvm flutter build apk --release  # For Android
fvm flutter build ios --release   # For iOS
```

## 4. Database Schema

### PostgreSQL Schema

```sql
-- Create database
CREATE DATABASE wellbeing_research;

-- Participants table
CREATE TABLE participants (
    id SERIAL PRIMARY KEY,
    participant_uuid UUID UNIQUE NOT NULL,
    research_site VARCHAR(20) NOT NULL CHECK (research_site IN ('barcelona', 'gauteng')),
    enrolled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_upload_at TIMESTAMP WITH TIME ZONE,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Encrypted data uploads table
CREATE TABLE data_uploads (
    id SERIAL PRIMARY KEY,
    upload_id UUID UNIQUE NOT NULL,
    participant_uuid UUID NOT NULL REFERENCES participants(participant_uuid),
    research_site VARCHAR(20) NOT NULL,
    encrypted_payload TEXT NOT NULL,  -- Base64 encoded encrypted data
    encryption_metadata JSONB NOT NULL,  -- IV, key info, etc.
    upload_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    data_period_end TIMESTAMP WITH TIME ZONE NOT NULL,
    processed BOOLEAN DEFAULT FALSE,
    processed_at TIMESTAMP WITH TIME ZONE
);

-- Decrypted data (after processing)
CREATE TABLE survey_responses (
    id SERIAL PRIMARY KEY,
    participant_uuid UUID NOT NULL,
    survey_type VARCHAR(50) NOT NULL,
    response_data JSONB NOT NULL,
    submitted_at TIMESTAMP WITH TIME ZONE NOT NULL,
    upload_id UUID REFERENCES data_uploads(upload_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE location_tracks (
    id SERIAL PRIMARY KEY,
    participant_uuid UUID NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    accuracy DECIMAL(8, 2),
    recorded_at TIMESTAMP WITH TIME ZONE NOT NULL,
    upload_id UUID REFERENCES data_uploads(upload_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_participants_uuid ON participants(participant_uuid);
CREATE INDEX idx_participants_site ON participants(research_site);
CREATE INDEX idx_uploads_participant ON data_uploads(participant_uuid);
CREATE INDEX idx_uploads_timestamp ON data_uploads(upload_timestamp);
CREATE INDEX idx_surveys_participant ON survey_responses(participant_uuid);
CREATE INDEX idx_locations_participant ON location_tracks(participant_uuid);
CREATE INDEX idx_locations_time ON location_tracks(recorded_at);
```

## 5. REST API Endpoints

### Upload Endpoint Specification

**Endpoint**: `POST /api/v1/participant-data`

**Headers**:
```
Content-Type: application/json
Authorization: Bearer <optional-api-key>
User-Agent: WellbeingMapper/1.0
```

**Request Body**:
```json
{
  "uploadId": "uuid-v4-string",
  "participantUuid": "uuid-v4-string",
  "researchSite": "barcelona" | "gauteng",
  "encryptedData": "base64-encoded-encrypted-payload",
  "encryptionMetadata": {
    "algorithm": "RSA-OAEP-AES-256-GCM",
    "keySize": 4096,
    "iv": "base64-encoded-iv",
    "timestamp": "2025-07-23T10:30:00Z"
  },
  "dataPeriod": {
    "start": "2025-07-09T00:00:00Z",
    "end": "2025-07-23T23:59:59Z"
  }
}
```

**Response Codes**:
- `200 OK`: Upload successful
- `400 Bad Request`: Invalid request format
- `401 Unauthorized`: Authentication failed
- `409 Conflict`: Duplicate upload ID
- `500 Internal Server Error`: Server error

**Success Response**:
```json
{
  "success": true,
  "uploadId": "uuid-v4-string",
  "receivedAt": "2025-07-23T10:30:15Z",
  "message": "Data uploaded successfully"
}
```

## 6. Node.js Server Implementation Example

### package.json
```json
{
  "name": "wellbeing-research-server",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.18.0",
    "helmet": "^7.0.0",
    "cors": "^2.8.5",
    "pg": "^8.11.0",
    "crypto": "^1.0.1",
    "uuid": "^9.0.0",
    "joi": "^17.9.0"
  }
}
```

### server.js
```javascript
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const crypto = require('crypto');
const { Pool } = require('pg');
const Joi = require('joi');

const app = express();
const port = process.env.PORT || 3000;

// Database connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));

// Load private key
const privateKey = require('fs').readFileSync('./research_private_key.pem', 'utf8');

// Validation schema
const uploadSchema = Joi.object({
  uploadId: Joi.string().uuid().required(),
  participantUuid: Joi.string().uuid().required(),
  researchSite: Joi.string().valid('barcelona', 'gauteng').required(),
  encryptedData: Joi.string().base64().required(),
  encryptionMetadata: Joi.object({
    algorithm: Joi.string().required(),
    keySize: Joi.number().required(),
    iv: Joi.string().base64().required(),
    timestamp: Joi.string().isoDate().required()
  }).required(),
  dataPeriod: Joi.object({
    start: Joi.string().isoDate().required(),
    end: Joi.string().isoDate().required()
  }).required()
});

// Upload endpoint
app.post('/api/v1/participant-data', async (req, res) => {
  try {
    // Validate request
    const { error, value } = uploadSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        error: 'Invalid request format',
        details: error.details
      });
    }

    const { uploadId, participantUuid, researchSite, encryptedData, encryptionMetadata, dataPeriod } = value;

    // Check for duplicate upload
    const existingUpload = await pool.query(
      'SELECT id FROM data_uploads WHERE upload_id = $1',
      [uploadId]
    );
    
    if (existingUpload.rows.length > 0) {
      return res.status(409).json({
        success: false,
        error: 'Upload ID already exists'
      });
    }

    // Store encrypted data
    await pool.query(`
      INSERT INTO data_uploads (
        upload_id, participant_uuid, research_site, encrypted_payload,
        encryption_metadata, data_period_start, data_period_end
      ) VALUES ($1, $2, $3, $4, $5, $6, $7)
    `, [
      uploadId,
      participantUuid,
      researchSite,
      encryptedData,
      JSON.stringify(encryptionMetadata),
      dataPeriod.start,
      dataPeriod.end
    ]);

    // Ensure participant record exists
    await pool.query(`
      INSERT INTO participants (participant_uuid, research_site, last_upload_at)
      VALUES ($1, $2, NOW())
      ON CONFLICT (participant_uuid) 
      DO UPDATE SET last_upload_at = NOW()
    `, [participantUuid, researchSite]);

    res.json({
      success: true,
      uploadId: uploadId,
      receivedAt: new Date().toISOString(),
      message: 'Data uploaded successfully'
    });

  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.listen(port, () => {
  console.log(`Research server listening on port ${port}`);
});
```

## 7. Data Decryption Process

### Decryption Script (Node.js)
```javascript
const crypto = require('crypto');
const fs = require('fs');

function decryptUpload(encryptedData, encryptionMetadata, privateKey) {
  try {
    // Parse encrypted payload (format: encrypted_aes_key|encrypted_data)
    const [encryptedAESKey, encryptedPayload] = encryptedData.split('|');
    
    // Decrypt AES key with RSA private key
    const aesKey = crypto.privateDecrypt(
      {
        key: privateKey,
        padding: crypto.constants.RSA_PKCS1_OAEP_PADDING,
        oaepHash: 'sha256'
      },
      Buffer.from(encryptedAESKey, 'base64')
    );

    // Decrypt data with AES key
    const iv = Buffer.from(encryptionMetadata.iv, 'base64');
    const decipher = crypto.createDecipherGCM('aes-256-gcm', aesKey);
    decipher.setIV(iv);
    
    let decrypted = decipher.update(encryptedPayload, 'base64', 'utf8');
    decrypted += decipher.final('utf8');
    
    return JSON.parse(decrypted);
  } catch (error) {
    throw new Error(`Decryption failed: ${error.message}`);
  }
}

// Example usage
async function processUploads() {
  const privateKey = fs.readFileSync('./research_private_key.pem', 'utf8');
  
  const uploads = await pool.query(
    'SELECT * FROM data_uploads WHERE processed = FALSE ORDER BY upload_timestamp'
  );
  
  for (const upload of uploads.rows) {
    try {
      const decryptedData = decryptUpload(
        upload.encrypted_payload,
        upload.encryption_metadata,
        privateKey
      );
      
      // Store surveys
      for (const survey of decryptedData.surveys) {
        await pool.query(`
          INSERT INTO survey_responses (
            participant_uuid, survey_type, response_data, submitted_at, upload_id
          ) VALUES ($1, $2, $3, $4, $5)
        `, [
          upload.participant_uuid,
          survey.type,
          JSON.stringify(survey.responses),
          survey.submittedAt,
          upload.upload_id
        ]);
      }
      
      // Store location tracks
      for (const track of decryptedData.locationTracks) {
        await pool.query(`
          INSERT INTO location_tracks (
            participant_uuid, latitude, longitude, accuracy, recorded_at, upload_id
          ) VALUES ($1, $2, $3, $4, $5, $6)
        `, [
          upload.participant_uuid,
          track.latitude,
          track.longitude,
          track.accuracy,
          track.timestamp,
          upload.upload_id
        ]);
      }
      
      // Mark as processed
      await pool.query(
        'UPDATE data_uploads SET processed = TRUE, processed_at = NOW() WHERE id = $1',
        [upload.id]
      );
      
      console.log(`Processed upload ${upload.upload_id}`);
      
    } catch (error) {
      console.error(`Failed to process upload ${upload.upload_id}:`, error);
    }
  }
}
```

## 8. Security Considerations

### Data Protection
- **Encryption at Rest**: Encrypt database with disk-level encryption
- **Encryption in Transit**: Use HTTPS with TLS 1.3
- **Key Management**: Store private keys in secure hardware modules (HSM) when possible
- **Access Control**: Implement role-based access control (RBAC)
- **Audit Logging**: Log all data access and processing activities

### GDPR Compliance
- **Data Minimization**: Only collect necessary data
- **Consent Management**: Track consent status and allow withdrawal
- **Right to Erasure**: Implement data deletion procedures
- **Data Portability**: Provide data export functionality
- **Privacy by Design**: Built-in privacy protections

### Server Hardening
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Configure firewall
sudo ufw enable
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS

# Disable root login
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# Install fail2ban
sudo apt install fail2ban -y
```

## 9. Monitoring and Maintenance

### Log Monitoring
```bash
# Monitor upload logs
tail -f /var/log/wellbeing-research/uploads.log

# Monitor server performance
htop
iotop
```

### Backup Strategy
```bash
# Daily database backup
pg_dump wellbeing_research | gzip > backup_$(date +%Y%m%d).sql.gz

# Weekly key backup (encrypted)
tar -czf keys_backup_$(date +%Y%m%d).tar.gz *.pem
gpg --symmetric --cipher-algo AES256 keys_backup_$(date +%Y%m%d).tar.gz
```

### Health Monitoring
- **Uptime Monitoring**: Use services like Uptime Robot or Pingdom
- **Performance Metrics**: Monitor CPU, memory, disk usage
- **Database Performance**: Track query performance and connection pools
- **SSL Certificate Expiry**: Monitor certificate renewal

## 10. Deployment Checklist

### Pre-Deployment
- [ ] Generate RSA key pairs (4096-bit)
- [ ] Set up secure server environment
- [ ] Configure database with proper schema
- [ ] Implement API endpoints with validation
- [ ] Set up HTTPS with valid SSL certificates
- [ ] Configure monitoring and logging
- [ ] Test encryption/decryption pipeline

### App Configuration
- [ ] Update public keys in `data_upload_service.dart`
- [ ] Update server URLs for each research site
- [ ] Test connectivity to both servers
- [ ] Verify encryption works end-to-end
- [ ] Build and deploy updated app versions

### Post-Deployment
- [ ] Verify server health endpoints
- [ ] Test data upload functionality
- [ ] Monitor logs for errors
- [ ] Verify data decryption process
- [ ] Set up automated backups
- [ ] Document operational procedures

## Support

For technical support with server setup:
1. Check server logs: `/var/log/wellbeing-research/`
2. Verify database connectivity: `psql -d wellbeing_research`
3. Test API endpoints with curl or Postman
4. Contact the development team with specific error messages

## Security Incident Response

If you suspect a security breach:
1. **Immediate**: Disable affected endpoints
2. **Assess**: Review logs for unauthorized access
3. **Contain**: Isolate affected systems
4. **Notify**: Contact research ethics boards and participants if required
5. **Recover**: Restore from clean backups
6. **Review**: Update security measures based on lessons learned
