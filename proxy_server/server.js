#!/usr/bin/env node

/**
 * Simple Express.js proxy server for encrypted survey data
 * Receives encrypted survey blobs from mobile app and forwards to Qualtrics
 * 
 * Security: Server never sees plaintext data - only encrypted blobs
 * 
 * Usage: 
 *   npm install express cors
 *   node server.js
 */

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const https = require('https');
const querystring = require('querystring');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Qualtrics API configuration
const QUALTRICS_API_BASE = 'https://pretoria.eu.qualtrics.com/API/v3';
const QUALTRICS_SURVEY_ID = 'SV_81uhgIyzv52qgdM';
const QUALTRICS_API_TOKEN = process.env.QUALTRICS_API_TOKEN;

// Validate required environment variables
if (!QUALTRICS_API_TOKEN) {
  console.error('❌ QUALTRICS_API_TOKEN environment variable is required');
  process.exit(1);
}

// Valid survey types for validation
const VALID_SURVEY_TYPES = ['initial', 'biweekly', 'consent'];

// Load participant codes database
let participantCodes = null;
try {
  const codesPath = path.join(__dirname, 'participant_codes.json');
  participantCodes = JSON.parse(fs.readFileSync(codesPath, 'utf8'));
  console.log(`✅ Loaded ${participantCodes.meta.totalCodes} participant codes`);
} catch (error) {
  console.error('❌ Failed to load participant codes:', error.message);
  console.log('ℹ️  Participant validation will fall back to hardcoded test codes only');
}

// Hash function for participant codes (matches app implementation)
function hashParticipantCode(code) {
  return crypto.createHash('sha256').update(code.trim().toUpperCase()).digest('hex');
}

// Security middleware
app.use(helmet());
app.use(compression());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : '*',
  methods: ['GET', 'POST'],
  credentials: false
}));

// Body parsing middleware
app.use(express.json({ limit: '10mb' })); // Large limit for encrypted data
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
    server_version: '1.2.0'
  });
});

// Participant code validation endpoint
app.post('/api/v1/participants/validate', async (req, res) => {
  try {
    console.log('🔍 Participant code validation request received');
    
    const { hashed_code, timestamp } = req.body;
    
    // Validate required fields
    if (!hashed_code) {
      return res.status(400).json({ 
        valid: false,
        error: 'Missing required field: hashed_code' 
      });
    }
    
    // Validate hash format (SHA-256 should be 64 hex characters)
    if (!/^[a-f0-9]{64}$/i.test(hashed_code)) {
      return res.status(400).json({
        valid: false,
        error: 'Invalid hash format'
      });
    }
    
    console.log(`🔐 Validating hashed code: ${hashed_code.substring(0, Math.min(8, hashed_code.length))}...`);
    
    let isValid = false;
    let codeType = 'unknown';
    
    if (participantCodes) {
      // Check all code categories
      const allCodes = [
        ...participantCodes.pilot_codes,
        ...participantCodes.study_codes,
        ...participantCodes.test_codes
      ];
      
      // Hash each code and compare
      for (const code of allCodes) {
        const computedHash = hashParticipantCode(code);
        if (computedHash === hashed_code.toLowerCase()) {
          isValid = true;
          
          // Determine code type
          if (participantCodes.pilot_codes.includes(code)) {
            codeType = 'pilot';
          } else if (participantCodes.study_codes.includes(code)) {
            codeType = 'study';
          } else if (participantCodes.test_codes.includes(code)) {
            codeType = 'test';
          }
          
          console.log(`✅ Valid ${codeType} participant code accepted`);
          break;
        }
      }
    }
    
    if (!isValid) {
      console.log(`❌ Invalid participant code attempted: ${hashed_code.substring(0, Math.min(8, hashed_code.length))}...`);
    }
    
    // Response
    res.json({
      valid: isValid,
      code_type: isValid ? codeType : null,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ Participant validation error:', error);
    res.status(500).json({
      valid: false,
      error: 'Internal server error during validation'
    });
  }
});

// Get participant codes statistics (admin endpoint)
app.get('/api/v1/participants/stats', (req, res) => {
  if (!participantCodes) {
    return res.status(503).json({
      error: 'Participant codes database not loaded'
    });
  }
  
  res.json({
    total_codes: participantCodes.meta.totalCodes,
    pilot_codes: participantCodes.pilot_codes.length,
    study_codes: participantCodes.study_codes.length,
    test_codes: participantCodes.test_codes.length,
    database_version: participantCodes.meta.version,
    created: participantCodes.meta.created
  });
});

// Main proxy endpoint for encrypted survey data
app.post('/submit', async (req, res) => {
  try {
    console.log('📥 Received encrypted survey submission');
    
    const { encrypted_data, survey_type, timestamp } = req.body;
    
    // Validate required fields
    if (!encrypted_data || !survey_type) {
      return res.status(400).json({ 
        error: 'Missing required fields: encrypted_data, survey_type' 
      });
    }
    
    // Validate survey type
    if (!VALID_SURVEY_TYPES.includes(survey_type)) {
      return res.status(400).json({ 
        error: `Invalid survey_type: ${survey_type}. Must be: ${VALID_SURVEY_TYPES.join(', ')}` 
      });
    }
    
    console.log(`📤 Forwarding ${survey_type} survey to Qualtrics...`);
    console.log(`🔐 Encrypted data size: ${encrypted_data.length} characters`);
    
    // Additional validation and size warnings
    const dataSizeInMB = encrypted_data.length / (1024 * 1024);
    if (dataSizeInMB > 5.0) {
      console.log(`🚨 CRITICAL: Payload is ${dataSizeInMB.toFixed(2)}MB - exceeds AWS Lambda 6MB limit!`);
      return res.status(413).json({ 
        error: 'Payload too large for AWS Lambda',
        size_mb: dataSizeInMB.toFixed(2),
        max_size_mb: 6 
      });
    } else if (dataSizeInMB > 3.0) {
      console.log(`⚠️ Large payload warning: ${dataSizeInMB.toFixed(2)}MB`);
    } else {
      console.log(`✅ Payload size: ${dataSizeInMB.toFixed(2)}MB`);
    }
    
    if (!timestamp || timestamp.length === 0) {
      console.log(`⚠️ No timestamp provided, using server timestamp`);
    }
    
    // Prepare data for Qualtrics (single text field with encrypted blob)
    const qualtricsData = {
      'QID1_TEXT': encrypted_data, // Single field containing entire encrypted survey
      'QID2_TEXT': survey_type,    // Survey type for organization
      'QID3_TEXT': timestamp || new Date().toISOString() // Submission timestamp
    };
    
        // Forward to Qualtrics API
    const success = await forwardToQualtricsAPI({
      encrypted_data,
      survey_type,
      timestamp: timestamp || new Date().toISOString()
    });
    
    if (success) {
      console.log('✅ Successfully forwarded to Qualtrics');
      res.json({ 
        success: true, 
        message: 'Encrypted survey data forwarded to Qualtrics',
        survey_type,
        timestamp: new Date().toISOString()
      });
    } else {
      console.log('❌ Failed to forward to Qualtrics');
      res.status(500).json({ 
        error: 'Failed to forward data to Qualtrics' 
      });
    }
    
  } catch (error) {
    console.error('❌ Proxy error:', error);
    res.status(500).json({ 
      error: 'Internal server error',
      message: error.message 
    });
  }
});

// Forward encrypted data to Qualtrics API
async function forwardToQualtricsAPI(data) {
  return new Promise((resolve) => {
    try {
      // Create response data for Qualtrics API
      // Using the correct field names for text entry questions
      const responseData = {
        values: {
          QID1_TEXT: data.encrypted_data,     // First question: encrypted_data (text)
          QID2_TEXT: data.survey_type,        // Second question: survey_type (text)
          QID3_TEXT: data.timestamp           // Third question: timestamp (text)
        },
        embeddedData: {
          source: "mobile_app",
          proxy_version: "1.0"
        }
      };
      
      const postData = JSON.stringify(responseData);
      const apiUrl = `${QUALTRICS_API_BASE}/surveys/${QUALTRICS_SURVEY_ID}/responses`;
      const url = new URL(apiUrl);
      
      const options = {
        hostname: url.hostname,
        path: url.pathname,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': postData.length,
          'X-API-TOKEN': QUALTRICS_API_TOKEN,
          'Accept': 'application/json'
        },
        timeout: 30000
      };
      
      console.log(`📤 Sending to Qualtrics API: ${apiUrl}`);
      console.log(`📊 Payload:`, JSON.stringify(responseData, null, 2));
      
      const req = https.request(options, (res) => {
        console.log(`📥 Qualtrics API response status: ${res.statusCode}`);
        
        let responseBody = '';
        res.on('data', (chunk) => {
          responseBody += chunk;
        });
        
        res.on('end', () => {
          const success = res.statusCode >= 200 && res.statusCode < 300;
          if (success) {
            console.log('✅ Successfully submitted to Qualtrics API');
            console.log(`📋 Response: ${responseBody.substring(0, Math.min(200, responseBody.length))}`);
          } else {
            console.log(`❌ Qualtrics API error: ${res.statusCode}`);
            console.log(`📋 Full response: ${responseBody.substring(0, Math.min(1000, responseBody.length))}`);
            console.log(`🔍 Request details - Data size: ${postData.length}, Survey type: ${data.survey_type}`);
          }
          resolve(success);
        });
      });
      
      req.on('error', (error) => {
        console.error('❌ Qualtrics API request error:', error);
        resolve(false);
      });
      
      req.on('timeout', () => {
        console.error('❌ Qualtrics API request timeout');
        req.destroy();
        resolve(false);
      });
      
      req.write(postData);
      req.end();
      
    } catch (error) {
      console.error('❌ Qualtrics API forward error:', error);
      resolve(false);
    }
  });
}

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('❌ Unhandled error:', error);
  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not found',
    message: 'Available endpoints: GET /health, POST /submit, POST /api/v1/participants/validate, GET /api/v1/participants/stats'
  });
});

// Start server
const server = app.listen(PORT, () => {
  console.log(`🚀 Encrypted Survey Proxy Server running on port ${PORT}`);
  console.log(`📡 Health check: http://localhost:${PORT}/health`);
  console.log(`📥 Submit endpoint: http://localhost:${PORT}/submit`);
  console.log(`🔍 Participant validation: http://localhost:${PORT}/api/v1/participants/validate`);
  console.log(`📊 Participant stats: http://localhost:${PORT}/api/v1/participants/stats`);
  console.log('🔐 Server only handles encrypted data - no plaintext survey data processed');
  console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('🛑 Received SIGTERM, shutting down gracefully...');
  server.close(() => {
    console.log('✅ Server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('🛑 Received SIGINT, shutting down gracefully...');
  server.close(() => {
    console.log('✅ Server closed');
    process.exit(0);
  });
});

module.exports = app; // For testing