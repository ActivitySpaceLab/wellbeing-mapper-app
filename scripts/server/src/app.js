require('dotenv').config();
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const compression = require('compression');

// Import route handlers
const surveyRoutes = require('./routes/survey-responses');
const consentRoutes = require('./routes/consent-responses');
const locationRoutes = require('./routes/location-data');
const participantRoutes = require('./routes/participants');
const healthRoutes = require('./routes/health');

// Import middleware
const authMiddleware = require('./middleware/auth');
const errorHandler = require('./middleware/error-handler');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet({
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  }
}));

// CORS configuration for Flutter app
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
  methods: ['GET', 'POST'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Study-ID'],
  credentials: false
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: {
    error: 'Too many requests from this IP, please try again later.',
    code: 'RATE_LIMIT_EXCEEDED'
  }
});
app.use('/api/', limiter);

// Body parsing and compression
app.use(compression());
app.use(express.json({ limit: '10mb' })); // Allow larger payloads for location data
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Logging
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('combined'));
}

// Health check (no auth required)
app.use('/api/health', healthRoutes);

// Authentication middleware for protected routes
app.use('/api', authMiddleware);

// API Routes (all authenticated)
app.use('/api/survey-responses', surveyRoutes);
app.use('/api/consent-responses', consentRoutes);
app.use('/api/location-data', locationRoutes);
app.use('/api/participants', participantRoutes);

// Study configuration endpoint
app.get('/api/study-config/:studyId', (req, res) => {
  const { studyId } = req.params;
  
  if (studyId !== process.env.STUDY_ID) {
    return res.status(404).json({
      error: 'Study not found',
      code: 'STUDY_NOT_FOUND'
    });
  }

  res.json({
    study_id: studyId,
    name: 'Barcelona Wellbeing Mapper Study',
    description: 'Mental wellbeing and urban mobility research in Barcelona',
    encryption_enabled: true,
    data_retention_days: 2555, // 7 years for research compliance
    privacy_policy_url: 'https://your-institution.edu/privacy/barcelona-study',
    contact_email: 'research@your-institution.edu',
    study_status: 'active',
    last_updated: new Date().toISOString()
  });
});

// Error handling
app.use(errorHandler);

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Endpoint not found',
    code: 'NOT_FOUND'
  });
});

// Start server
const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Barcelona Research Server started on port ${PORT}`);
  console.log(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔐 Encryption: Enabled (RSA 4096-bit)`);
  console.log(`🇪🇺 GDPR: Compliant (EU hosting)`);
  console.log(`📊 Study ID: ${process.env.STUDY_ID || 'barcelona_study_2025'}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('🛑 SIGTERM received, shutting down gracefully');
  server.close(() => {
    console.log('✅ Server closed successfully');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('🛑 SIGINT received, shutting down gracefully');
  server.close(() => {
    console.log('✅ Server closed successfully');
    process.exit(0);
  });
});

module.exports = app;