# Encrypted Survey Proxy Server

A secure proxy server for the Gauteng Wellbeing Mapper app that forwards encrypted survey data to Qualtrics without exposing API tokens or processing plaintext data.

## 🔐 Security Architecture

```
Mobile App → Proxy Server → Qualtrics
     ↓           ↓            ↓
  Encrypt    Forward Only   Store Blob
   (RSA)    (No Decrypt)   (Encrypted)
```

## 📁 Directory Structure

```
proxy_server/
├── README.md           # This file
├── package.json        # Node.js dependencies
├── server.js          # Main proxy server
├── deploy/            # Deployment configurations
│   ├── aws-lambda.js  # AWS Lambda version
│   └── vercel.json    # Vercel deployment config
├── config/            # Configuration files
│   └── .env.example   # Environment variables template
└── test/              # Test files
    └── test-proxy.js  # Local testing script
```

## 🚀 Quick Start

### Local Development
```bash
cd proxy_server
npm install
npm start
```

### Environment Variables
```bash
cp config/.env.example .env
# Edit .env with your settings
```

## 🌍 Deployment Options

### AWS Lambda (Cape Town)
- **Data location**: South Africa (af-south-1)
- **Security**: SOC 2, ISO 27001 compliant
- **Cost**: Pay per request (~$0.01 per 1000 requests)

### Vercel
- **Global CDN**: Fast worldwide
- **Easy deployment**: `vercel deploy`
- **Free tier**: 100,000 requests/month

## Architecture Overview

The proxy server bridges between the mobile app and Qualtrics using a simplified, secure approach:

1. **Mobile App** → Encrypts complete survey data (JSON) with RSA public key
2. **Proxy Server** → Receives encrypted blob, forwards to single Qualtrics survey  
3. **Qualtrics Survey** → Stores encrypted data in 3 simple fields:
   - `encrypted_data`: RSA-encrypted JSON blob containing full survey
   - `survey_type`: Plain text ("initial", "biweekly", or "consent")
   - `timestamp`: Submission timestamp
4. **Researchers** → Download responses and decrypt with RSA private key

**Key Benefits:**
- **Single Survey**: One Qualtrics survey handles all survey types
- **Zero API Tokens**: No Qualtrics credentials in mobile app
- **End-to-End Encryption**: Data encrypted from phone to researcher download
- **Offline Capability**: Native forms work without internet, sync when available  

## 📊 Data Flow

1. **App encrypts** survey JSON with RSA public key
2. **Proxy receives** encrypted blob + metadata
3. **Proxy forwards** to appropriate Qualtrics survey
4. **Qualtrics stores** encrypted data in single text field
5. **Research team** downloads and decrypts with private key

## 🧪 Testing

```bash
npm test              # Run all tests
npm run test:local    # Test local server
npm run test:deploy   # Test deployed server
```

## 📈 Monitoring

The proxy provides health checks and basic metrics:
- `GET /health` - Server health status
- `GET /metrics` - Request counts and response times
- Logs are minimal and contain no sensitive data

## 🛠️ Configuration

Environment variables:
- `PORT` - Server port (default: 3000)
- `NODE_ENV` - Environment (development/production)
- `CORS_ORIGIN` - Allowed origins for CORS
- `LOG_LEVEL` - Logging level (error/warn/info/debug)