# Barcelona Research Server

A GDPR-compliant Node.js server for the Barcelona Wellbeing Mapper study.

## Features

- End-to-end encryption (RSA 4096-bit)
- EU hosting (Digital Ocean Frankfurt)
- PostgreSQL encrypted data storage
- RESTful API for Flutter app
- GDPR-compliant data handling

## Quick Deploy

```bash
# On your Digital Ocean droplet (Ubuntu 22.04)
git clone https://github.com/yourusername/barcelona-server.git
cd barcelona-server
npm install
npm run setup-db
npm start
```

## Environment Variables

Create `.env` file:

```
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://username:password@localhost:5432/barcelona_research
PRIVATE_KEY_PATH=/opt/keys/barcelona_private_key.pem
API_KEY=your-secure-api-key-here
STUDY_ID=barcelona_study_2025
```

## API Endpoints

- `POST /api/survey-responses/initial` - Submit initial survey (encrypted)
- `POST /api/survey-responses/recurring` - Submit recurring survey (encrypted)  
- `POST /api/consent-responses` - Submit consent data (encrypted)
- `POST /api/location-data` - Submit location batch (encrypted)
- `POST /api/participants` - Register participant
- `GET /api/health` - Server health check
- `GET /api/study-config/:studyId` - Get study configuration

## Data Flow

1. **Flutter App**: Encrypts data with public key → sends to server
2. **Server**: Stores encrypted data in PostgreSQL database
3. **Research Team**: Uses private key to decrypt data for analysis

## Security Features

- RSA 4096-bit encryption
- API key authentication
- Rate limiting
- Request logging
- HTTPS only (Let's Encrypt)
- Database connection encryption