#!/usr/bin/env node

/**
 * Discover Qualtrics Survey Question IDs (QIDs)
 * This script will fetch the survey definition to find the correct QIDs
 */

const https = require('https');

const QUALTRICS_API_BASE = 'https://pretoria.eu.qualtrics.com/API/v3';
const SURVEY_ID = 'SV_81uhgIyzv52qgdM';
const API_TOKEN = process.env.QUALTRICS_API_TOKEN;

if (!API_TOKEN) {
  console.error('❌ Please set QUALTRICS_API_TOKEN environment variable');
  process.exit(1);
}

function makeAPIRequest(endpoint) {
  return new Promise((resolve, reject) => {
    const url = `${QUALTRICS_API_BASE}${endpoint}`;
    const urlObj = new URL(url);
    
    const options = {
      hostname: urlObj.hostname,
      path: urlObj.pathname + urlObj.search,
      method: 'GET',
      headers: {
        'X-API-TOKEN': API_TOKEN,
        'Accept': 'application/json'
      }
    };
    
    console.log(`🔍 Fetching: ${url}`);
    
    const req = https.request(options, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        try {
          const response = JSON.parse(data);
          resolve({ statusCode: res.statusCode, data: response });
        } catch (e) {
          reject(new Error(`JSON parse error: ${e.message}`));
        }
      });
    });
    
    req.on('error', (error) => {
      reject(error);
    });
    
    req.end();
  });
}

async function discoverQIDs() {
  try {
    console.log('🔍 Discovering Question IDs for Survey:', SURVEY_ID);
    console.log('=' .repeat(60));
    
    // Get survey definition
    const response = await makeAPIRequest(`/surveys/${SURVEY_ID}`);
    
    if (response.statusCode !== 200) {
      console.error('❌ API Error:', response.data);
      return;
    }
    
    const survey = response.data.result;
    console.log(`📋 Survey Name: ${survey.name}`);
    console.log(`🆔 Survey ID: ${survey.id}`);
    console.log(`📅 Created: ${survey.creationDate}`);
    console.log('');
    
    // Extract questions
    const questions = survey.questions || {};
    console.log(`📝 Found ${Object.keys(questions).length} questions:`);
    console.log('');
    
    Object.entries(questions).forEach(([qid, question]) => {
      console.log(`🔹 ${qid}: "${question.questionText?.replace(/<[^>]*>/g, '')?.substring(0, 50) || 'No text'}"...`);
      console.log(`   Type: ${question.questionType}`);
      console.log(`   DataExportTag: ${question.dataExportTag || 'none'}`);
      console.log('');
    });
    
    // Try to identify the fields we need
    console.log('🎯 Suggested mappings for your encrypted survey:');
    console.log('=' .repeat(40));
    
    const qids = Object.keys(questions);
    if (qids.length >= 3) {
      console.log(`encrypted_data: ${qids[0]}`);
      console.log(`survey_type: ${qids[1]}`);
      console.log(`timestamp: ${qids[2]}`);
    } else {
      console.log('❌ Expected 3 questions, found:', qids.length);
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

// Run the discovery
discoverQIDs();