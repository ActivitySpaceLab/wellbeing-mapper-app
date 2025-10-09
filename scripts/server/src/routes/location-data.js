const express = require('express');
const { body, validationResult } = require('express-validator');
const { storeEncryptedData } = require('../models/database');
const router = express.Router();

// Validation middleware for location data
const validateLocationData = [
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
  body('batch_size')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Batch size must be a positive integer')
];

// Submit location data batch
router.post('/', validateLocationData, async (req, res) => {
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

    const { encrypted_payload, study_id, batch_size } = req.body;

    // Store encrypted location data
    const result = await storeEncryptedData({
      table: 'location_data',
      data: {
        encrypted_location_batch: encrypted_payload,
        batch_size: batch_size || null,
        study_id: study_id,
        received_at: new Date().toISOString(),
        source_ip: req.ip
      }
    });

    console.log(`✅ Location data batch stored: ID ${result.id}, size: ${batch_size || 'unknown'}`);

    res.status(201).json({
      success: true,
      message: 'Location data batch stored successfully',
      id: result.id,
      batch_size: batch_size,
      timestamp: result.created_at
    });

  } catch (error) {
    console.error('❌ Error storing location data:', error);
    res.status(500).json({
      error: 'Failed to store location data',
      code: 'STORAGE_ERROR'
    });
  }
});

module.exports = router;