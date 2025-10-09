const express = require('express');
const { body, validationResult } = require('express-validator');
const { storeEncryptedData } = require('../models/database');
const router = express.Router();

// Validation middleware for survey responses
const validateSurveyResponse = [
  body('encrypted_payload')
    .notEmpty()
    .withMessage('Encrypted payload is required')
    .isString()
    .withMessage('Encrypted payload must be a string'),
  body('study_id')
    .notEmpty()
    .withMessage('Study ID is required')
    .equals(process.env.STUDY_ID || 'barcelona_study_2025')
    .withMessage('Invalid study ID'),
  body('data_type')
    .isIn(['initial_survey', 'recurring_survey'])
    .withMessage('Data type must be initial_survey or recurring_survey')
];

// Submit initial survey response
router.post('/initial', validateSurveyResponse, async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        code: 'VALIDATION_ERROR',
        details: errors.array()
      });
    }

    const { encrypted_payload, study_id, data_type } = req.body;

    // Store encrypted survey response
    const result = await storeEncryptedData({
      table: 'survey_responses',
      data: {
        encrypted_responses: encrypted_payload,
        survey_type: 'initial',
        study_id: study_id,
        data_type: data_type,
        received_at: new Date().toISOString(),
        source_ip: req.ip
      }
    });

    console.log(`✅ Initial survey stored: ID ${result.id}`);

    res.status(201).json({
      success: true,
      message: 'Initial survey response stored successfully',
      id: result.id,
      timestamp: result.created_at
    });

  } catch (error) {
    console.error('❌ Error storing initial survey:', error);
    res.status(500).json({
      error: 'Failed to store survey response',
      code: 'STORAGE_ERROR'
    });
  }
});

// Submit recurring survey response  
router.post('/recurring', validateSurveyResponse, async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        code: 'VALIDATION_ERROR', 
        details: errors.array()
      });
    }

    const { encrypted_payload, study_id, data_type } = req.body;

    // Store encrypted survey response
    const result = await storeEncryptedData({
      table: 'survey_responses',
      data: {
        encrypted_responses: encrypted_payload,
        survey_type: 'recurring',
        study_id: study_id,
        data_type: data_type,
        received_at: new Date().toISOString(),
        source_ip: req.ip
      }
    });

    console.log(`✅ Recurring survey stored: ID ${result.id}`);

    res.status(201).json({
      success: true,
      message: 'Recurring survey response stored successfully',
      id: result.id,
      timestamp: result.created_at
    });

  } catch (error) {
    console.error('❌ Error storing recurring survey:', error);
    res.status(500).json({
      error: 'Failed to store survey response',
      code: 'STORAGE_ERROR'
    });
  }
});

// Get survey statistics (for monitoring)
router.get('/stats', async (req, res) => {
  try {
    // This would typically require admin authentication
    const stats = {
      message: 'Survey statistics endpoint - implement based on research needs',
      note: 'Add admin authentication and database queries for survey counts'
    };

    res.json(stats);
  } catch (error) {
    console.error('❌ Error getting survey stats:', error);
    res.status(500).json({
      error: 'Failed to get survey statistics',
      code: 'STATS_ERROR'
    });
  }
});

module.exports = router;