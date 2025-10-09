# Barcelona Server Setup Guide

## Architecture Overview

```
📱 Barcelona App (Phone)          🌍 Digital Ocean (EU-Frankfurt)
├── Encrypt data with public key  ├── Receive encrypted data
├── Sync via HTTPS API            ├── Store in PostgreSQL database  
└── No external dependencies      └── Export for data analysis
```

## Server Requirements

### GDPR Compliance ✅
- **EU Hosting**: Digital Ocean Frankfurt (FRA1) datacenter
- **Data Encryption**: End-to-end encryption (phone encrypts, server stores encrypted)
- **Access Controls**: API authentication, database security
- **Data Retention**: Configurable retention policies
- **Export Capability**: For data portability rights

### Technical Stack
- **Hosting**: Digital Ocean Droplet (EU-Frankfurt)
- **Backend**: Node.js + Express (simple REST API)
- **Database**: PostgreSQL (encrypted storage)
- **Security**: Let's Encrypt SSL + API key authentication
- **Monitoring**: Basic logging and health checks

## Phase 1: Digital Ocean Setup

### 1. Create EU-Compliant Droplet
```bash
# Digital Ocean Frankfurt datacenter (GDPR compliant)
Region: Frankfurt 1 (FRA1) 
Size: Basic Droplet - 2 GB RAM, 1 vCPU, 50 GB SSD ($12/month)
Image: Ubuntu 22.04 LTS
Networking: Enable IPv6, Monitoring
```

### 2. Domain Configuration
```bash
# Recommended setup
Domain: barcelona-research.yourdomain.com
SSL: Let's Encrypt (free, auto-renewing)
API Base: https://barcelona-research.yourdomain.com/api
```

### 3. Security Hardening
```bash
# Essential security setup
- SSH key authentication (disable password login)
- UFW firewall (only HTTP, HTTPS, SSH)  
- Fail2ban for intrusion prevention
- Regular security updates
- Database connection encryption
```

## Phase 2: Server Implementation

### Directory Structure
```
/opt/barcelona-server/
├── src/
│   ├── routes/
│   │   ├── survey-responses.js
│   │   ├── consent-responses.js
│   │   ├── location-data.js
│   │   └── participants.js
│   ├── middleware/
│   │   ├── auth.js
│   │   └── validation.js
│   ├── models/
│   │   └── database.js
│   └── app.js
├── config/
│   ├── database.sql
│   └── environment.js
├── scripts/
│   ├── export-data.js
│   └── backup.js
├── package.json
└── ecosystem.config.js (PM2)
```

### API Endpoints (Match Flutter Service)
```javascript
// Survey endpoints
POST /api/survey-responses/initial
POST /api/survey-responses/recurring

// Consent and participant management  
POST /api/consent-responses
POST /api/participants

// Location data
POST /api/location-data

// Administrative
GET /api/health
GET /api/study-config/:studyId
```

### Database Schema
```sql
-- Encrypted storage - data arrives pre-encrypted from phone
CREATE TABLE participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    participant_id VARCHAR(255) UNIQUE NOT NULL,
    study_id VARCHAR(255) NOT NULL,
    registration_timestamp TIMESTAMP WITH TIME ZONE,
    app_version VARCHAR(50),
    platform VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE survey_responses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    participant_id VARCHAR(255) REFERENCES participants(participant_id),
    survey_type VARCHAR(50) NOT NULL,
    encrypted_responses TEXT NOT NULL, -- Encrypted JSON from phone
    timestamp TIMESTAMP WITH TIME ZONE,
    study_id VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE location_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    participant_id VARCHAR(255) REFERENCES participants(participant_id),
    encrypted_location_batch TEXT NOT NULL, -- Encrypted location points
    upload_timestamp TIMESTAMP WITH TIME ZONE,
    study_id VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE consent_responses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    participant_id VARCHAR(255) REFERENCES participants(participant_id),
    encrypted_consent TEXT NOT NULL, -- Encrypted consent data
    timestamp TIMESTAMP WITH TIME ZONE,
    study_id VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## Phase 3: Encryption Strategy

### New Barcelona Key Pair
```bash
# Generate new RSA key pair (different from Gauteng)
openssl genrsa -out barcelona_private_key.pem 2048
openssl rsa -in barcelona_private_key.pem -pubout -out barcelona_public_key.pem

# Public key goes in Flutter app (embedded)
# Private key stays on server for data export/analysis
```

### Flutter Integration
```dart
// Update lib/util/env.dart
class ENV {
  static const String API_BASE_URL = "https://barcelona-research.yourdomain.com/api";
  static const String DEFAULT_SAMPLE_ID = "barcelona_study_2025";
  
  // Barcelona-specific public key (embedded)
  static const String BARCELONA_PUBLIC_KEY = '''
-----BEGIN PUBLIC KEY-----
[Your Barcelona Public Key Here]
-----END PUBLIC KEY-----
  ''';
}
```

## Phase 4: Data Flow

### 1. Phone Side (Already Implemented)
```dart
// Data encrypted on phone before transmission
1. Collect survey/location data
2. Encrypt with Barcelona public key  
3. Send via BarcelonaServerService
4. Store sync status locally
```

### 2. Server Side (To Implement)
```javascript
// Server receives and stores encrypted data
1. Authenticate API request
2. Validate data format
3. Store encrypted data in PostgreSQL
4. Return success/failure status
5. Log for monitoring
```

### 3. Data Export (To Implement)
```bash
# Research team data access
1. SSH to server with proper credentials
2. Run export script with private key
3. Decrypt and export data for analysis
4. Secure data transfer to research team
```

## Quick Start Commands

### Digital Ocean Setup
```bash
# 1. Create droplet via DO dashboard or CLI
doctl compute droplet create barcelona-server \
  --region fra1 \
  --image ubuntu-22-04-x64 \
  --size s-2vcpu-2gb \
  --ssh-keys [your-ssh-key-id]

# 2. Initial server setup
ssh root@your-server-ip
apt update && apt upgrade -y
ufw enable
ufw allow OpenSSH
ufw allow 'Nginx Full'
```

### Server Application Setup
```bash
# 3. Install dependencies
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt install -y nodejs postgresql postgresql-contrib nginx certbot python3-certbot-nginx

# 4. Clone and setup application
cd /opt
git clone https://github.com/yourusername/barcelona-server.git
cd barcelona-server
npm install
```

## Benefits of This Approach

### ✅ GDPR Compliant
- EU hosting (Frankfurt datacenter)
- End-to-end encryption
- Data minimization (only research-relevant data)
- Export capabilities for data portability

### ✅ Simple & Reliable
- No external dependencies (Qualtrics, etc.)
- Direct phone-to-server communication
- Standard tech stack (Node.js, PostgreSQL)
- Automated backups and monitoring

### ✅ Cost Effective
- ~$12/month for hosting
- No licensing fees for survey platforms
- Simple maintenance requirements

### ✅ Research Ready
- Encrypted data storage
- Easy export for analysis
- Configurable retention policies
- Audit trail for compliance

## Immediate Next Steps

1. **Create Digital Ocean Droplet** in Frankfurt region
2. **Set up domain and SSL** certificates
3. **Implement basic server** with authentication
4. **Generate Barcelona key pair** 
5. **Test integration** with Flutter app
6. **Deploy and validate** GDPR compliance

Would you like me to help implement the server code or set up the Digital Ocean configuration?