const express = require('express');
const { body, validationResult } = require('express-validator');
const { storeEncryptedData } = require('../models/database');
const router = express.Router();

// Validation middleware for consent responses
const validateConsentResponse = [
  body('encrypted_payload')
    .notEmpty()
    .withMessage('Encrypted payload is required')
    .isString()
    .withMessage('Encrypted payload must be a string'),
  body('study_id')
    .notEmpty()
    .withMessage('Study ID is required')
    .equals(process.env.STUDY_ID || 'barcelona_study_2025')
    .withMessage('Invalid study ID')
];

// Submit consent response
router.post('/', validateConsentResponse, async (req, res) => {
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

    const { encrypted_payload, study_id } = req.body;

    // Store encrypted consent response
    const result = await storeEncryptedData({
      table: 'consent_responses',
      data: {
        encrypted_consent: encrypted_payload,
        study_id: study_id,
        received_at: new Date().toISOString(),
        source_ip: req.ip
      }
    });

    console.log(`✅ Consent response stored: ID ${result.id}`);

    res.status(201).json({
      success: true,
      message: 'Consent response stored successfully',
      id: result.id,
      timestamp: result.created_at
    });

  } catch (error) {
    console.error('❌ Error storing consent response:', error);
    res.status(500).json({
      error: 'Failed to store consent response',
      code: 'STORAGE_ERROR'
    });
  }
});

module.exports = router;