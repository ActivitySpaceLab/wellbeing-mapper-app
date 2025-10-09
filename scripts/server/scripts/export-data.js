#!/usr/bin/env node

/**
 * Barcelona Research Data Export Tool
 * 
 * Decrypts and exports research data for analysis.
 * Only authorized researchers should have access to the private key.
 */

require('dotenv').config();
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { Pool } = require('pg');

// PostgreSQL connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

// Load private key for decryption
const loadPrivateKey = () => {
  const privateKeyPath = process.env.PRIVATE_KEY_PATH || '/opt/keys/barcelona_private_key.pem';
  
  if (!fs.existsSync(privateKeyPath)) {
    throw new Error(`Private key not found at: ${privateKeyPath}`);
  }

  return fs.readFileSync(privateKeyPath, 'utf8');
};

// Decrypt RSA-encrypted data
const decryptData = (encryptedData, privateKey) => {
  try {
    const buffer = Buffer.from(encryptedData, 'base64');
    const decrypted = crypto.privateDecrypt(
      {
        key: privateKey,
        padding: crypto.constants.RSA_PKCS1_PADDING
      },
      buffer
    );
    return JSON.parse(decrypted.toString('utf8'));
  } catch (error) {
    console.warn('⚠️  Failed to decrypt data:', error.message);
    return null;
  }
};

// Export survey responses
const exportSurveyData = async (privateKey, outputDir) => {
  console.log('📊 Exporting survey responses...');
  
  const query = `
    SELECT 
      id, participant_id, survey_type, encrypted_responses,
      data_type, study_id, received_at, created_at
    FROM survey_responses 
    ORDER BY created_at ASC
  `;
  
  const result = await pool.query(query);
  const surveys = [];
  
  for (const row of result.rows) {
    const decryptedData = decryptData(row.encrypted_responses, privateKey);
    if (decryptedData) {
      surveys.push({
        id: row.id,
        participant_id: row.participant_id || decryptedData.participant_id,
        survey_type: row.survey_type,
        data_type: row.data_type,
        study_id: row.study_id,
        received_at: row.received_at,
        created_at: row.created_at,
        responses: decryptedData.responses || decryptedData
      });
    }
  }
  
  const surveyFile = path.join(outputDir, 'survey_responses.json');
  fs.writeFileSync(surveyFile, JSON.stringify(surveys, null, 2));
  console.log(`✅ Exported ${surveys.length} survey responses to ${surveyFile}`);
  
  return surveys.length;
};

// Export consent responses
const exportConsentData = async (privateKey, outputDir) => {
  console.log('📝 Exporting consent responses...');
  
  const query = `
    SELECT 
      id, participant_id, encrypted_consent, study_id, received_at, created_at
    FROM consent_responses 
    ORDER BY created_at ASC
  `;
  
  const result = await pool.query(query);
  const consents = [];
  
  for (const row of result.rows) {
    const decryptedData = decryptData(row.encrypted_consent, privateKey);
    if (decryptedData) {
      consents.push({
        id: row.id,
        participant_id: row.participant_id || decryptedData.participant_id,
        study_id: row.study_id,
        received_at: row.received_at,
        created_at: row.created_at,
        consent_data: decryptedData
      });
    }
  }
  
  const consentFile = path.join(outputDir, 'consent_responses.json');
  fs.writeFileSync(consentFile, JSON.stringify(consents, null, 2));
  console.log(`✅ Exported ${consents.length} consent responses to ${consentFile}`);
  
  return consents.length;
};

// Export location data
const exportLocationData = async (privateKey, outputDir) => {
  console.log('📍 Exporting location data...');
  
  const query = `
    SELECT 
      id, participant_id, encrypted_location_batch, batch_size,
      study_id, received_at, created_at
    FROM location_data 
    ORDER BY created_at ASC
  `;
  
  const result = await pool.query(query);
  const locations = [];
  
  for (const row of result.rows) {
    const decryptedData = decryptData(row.encrypted_location_batch, privateKey);
    if (decryptedData) {
      locations.push({
        id: row.id,
        participant_id: row.participant_id || decryptedData.participant_id,
        batch_size: row.batch_size,
        study_id: row.study_id,
        received_at: row.received_at,
        created_at: row.created_at,
        location_points: decryptedData.location_points || decryptedData
      });
    }
  }
  
  const locationFile = path.join(outputDir, 'location_data.json');
  fs.writeFileSync(locationFile, JSON.stringify(locations, null, 2));
  console.log(`✅ Exported ${locations.length} location batches to ${locationFile}`);
  
  return locations.length;
};

// Export participant data (unencrypted)
const exportParticipantData = async (outputDir) => {
  console.log('👥 Exporting participant data...');
  
  const query = `
    SELECT 
      id, participant_id, study_id, registration_timestamp,
      app_version, platform, created_at
    FROM participants 
    ORDER BY created_at ASC
  `;
  
  const result = await pool.query(query);
  
  const participantFile = path.join(outputDir, 'participants.json');
  fs.writeFileSync(participantFile, JSON.stringify(result.rows, null, 2));
  console.log(`✅ Exported ${result.rows.length} participants to ${participantFile}`);
  
  return result.rows.length;
};

// Generate export summary
const generateSummary = (stats, outputDir) => {
  const summary = {
    export_timestamp: new Date().toISOString(),
    study_id: process.env.STUDY_ID || 'barcelona_study_2025',
    total_participants: stats.participants,
    total_surveys: stats.surveys,
    total_consents: stats.consents,
    total_location_batches: stats.locations,
    files_generated: [
      'participants.json',
      'survey_responses.json', 
      'consent_responses.json',
      'location_data.json',
      'export_summary.json'
    ],
    notes: [
      'All data has been decrypted using the Barcelona private key',
      'Participant IDs are pseudonymized UUIDs',
      'Location data is stored in batches for efficiency',
      'Timestamps are in ISO 8601 format with timezone'
    ]
  };
  
  const summaryFile = path.join(outputDir, 'export_summary.json');
  fs.writeFileSync(summaryFile, JSON.stringify(summary, null, 2));
  console.log(`📋 Export summary saved to ${summaryFile}`);
};

// Main export function
const main = async () => {
  try {
    console.log('🔐 Barcelona Research Data Export Tool');
    console.log('=====================================');
    
    // Create output directory
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const outputDir = path.join(process.cwd(), `barcelona_data_export_${timestamp}`);
    fs.mkdirSync(outputDir, { recursive: true });
    console.log(`📁 Export directory: ${outputDir}`);
    
    // Load private key
    console.log('🔑 Loading private key...');
    const privateKey = loadPrivateKey();
    console.log('✅ Private key loaded successfully');
    
    // Export all data types
    const stats = {
      participants: await exportParticipantData(outputDir),
      surveys: await exportSurveyData(privateKey, outputDir),
      consents: await exportConsentData(privateKey, outputDir),
      locations: await exportLocationData(privateKey, outputDir)
    };
    
    // Generate summary
    generateSummary(stats, outputDir);
    
    console.log('');
    console.log('🎉 Data export completed successfully!');
    console.log(`📊 Summary:`);
    console.log(`   - Participants: ${stats.participants}`);
    console.log(`   - Survey responses: ${stats.surveys}`);
    console.log(`   - Consent responses: ${stats.consents}`);
    console.log(`   - Location batches: ${stats.locations}`);
    console.log(`📁 Files saved to: ${outputDir}`);
    
  } catch (error) {
    console.error('❌ Export failed:', error);
    process.exit(1);
  } finally {
    await pool.end();
  }
};

// Run the export
if (require.main === module) {
  main();
}

module.exports = { main };