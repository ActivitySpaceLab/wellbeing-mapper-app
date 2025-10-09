const express = require('express');
const { body, validationResult } = require('express-validator');
const { storeEncryptedData } = require('../models/database');
const router = express.Router();

// Validation middleware for participant registration
const validateParticipant = [
  body('participant_id')
    .notEmpty()
    .withMessage('Participant ID is required')
    .isString()
    .withMessage('Participant ID must be a string')
    .isLength({ min: 10, max: 100 })
    .withMessage('Participant ID must be between 10-100 characters'),
  body('study_id')
    .notEmpty()
    .withMessage('Study ID is required')
    .equals(process.env.STUDY_ID || 'barcelona_study_2025')
    .withMessage('Invalid study ID'),
  body('app_version')
    .optional()
    .isString()
    .withMessage('App version must be a string'),
  body('platform')
    .optional()
    .isIn(['android', 'ios'])
    .withMessage('Platform must be android or ios')
];

// Register new participant
router.post('/', validateParticipant, async (req, res) => {
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

    const { participant_id, study_id, app_version, platform } = req.body;

    // Register participant
    const result = await storeEncryptedData({
      table: 'participants',
      data: {
        participant_id: participant_id,
        study_id: study_id,
        registration_timestamp: new Date().toISOString(),
        app_version: app_version || 'unknown',
        platform: platform || 'unknown',
        source_ip: req.ip
      }
    });

    console.log(`✅ Participant registered: ${participant_id}`);

    res.status(201).json({
      success: true,
      message: 'Participant registered successfully',
      participant_id: participant_id,
      id: result.id,
      timestamp: result.created_at
    });

  } catch (error) {
    // Handle duplicate participant ID (already registered)
    if (error.code === '23505') { // PostgreSQL unique violation
      console.log(`ℹ️  Participant already registered: ${req.body.participant_id}`);
      return res.status(200).json({
        success: true,
        message: 'Participant already registered',
        participant_id: req.body.participant_id,
        status: 'existing'
      });
    }

    console.error('❌ Error registering participant:', error);
    res.status(500).json({
      error: 'Failed to register participant',
      code: 'REGISTRATION_ERROR'
    });
  }
});

module.exports = router;