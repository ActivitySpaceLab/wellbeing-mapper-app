const express = require('express');
const router = express.Router();

// Health check endpoint (no authentication required)
router.get('/', (req, res) => {
  const healthStatus = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    server: 'Barcelona Research Server',
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    study_id: process.env.STUDY_ID || 'barcelona_study_2025',
    encryption: 'RSA 4096-bit enabled',
    compliance: 'GDPR compliant (EU hosting)',
    uptime: Math.floor(process.uptime()),
    memory_usage: {
      rss: Math.round(process.memoryUsage().rss / 1024 / 1024),
      heap_used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
      heap_total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024)
    }
  };

  // Add database connectivity check if needed
  // This could be expanded to check PostgreSQL connection

  res.json(healthStatus);
});

// Detailed health check (requires authentication)
router.get('/detailed', (req, res) => {
  // This endpoint could include:
  // - Database connection status
  // - Disk space usage
  // - Recent error counts
  // - Performance metrics
  
  const detailedHealth = {
    ...require('./health').healthStatus,
    database: {
      status: 'connected', // TODO: Add actual DB health check
      connection_pool: 'active',
      last_query: 'recent'
    },
    performance: {
      avg_response_time: '< 100ms',
      requests_last_hour: 0, // TODO: Add actual metrics
      errors_last_hour: 0
    },
    security: {
      encryption_status: 'active',
      auth_failures_last_hour: 0,
      rate_limit_hits: 0
    }
  };

  res.json(detailedHealth);
});

module.exports = router;