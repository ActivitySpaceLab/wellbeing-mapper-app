// Global error handler middleware
const errorHandler = (err, req, res, next) => {
  console.error('❌ Server Error:', err);

  // Default error response
  let status = 500;
  let message = 'Internal server error';
  let code = 'INTERNAL_ERROR';

  // Handle specific error types
  if (err.name === 'ValidationError') {
    status = 400;
    message = 'Validation error';
    code = 'VALIDATION_ERROR';
  } else if (err.name === 'UnauthorizedError') {
    status = 401;
    message = 'Unauthorized access';
    code = 'UNAUTHORIZED';
  } else if (err.code === 'LIMIT_FILE_SIZE') {
    status = 413;
    message = 'Request payload too large';
    code = 'PAYLOAD_TOO_LARGE';
  } else if (err.type === 'entity.parse.failed') {
    status = 400;
    message = 'Invalid JSON format';
    code = 'INVALID_JSON';
  }

  // Log error details (but don't expose internal details to client)
  if (process.env.NODE_ENV !== 'production') {
    console.error('Error details:', err.stack);
  }

  res.status(status).json({
    error: message,
    code: code,
    timestamp: new Date().toISOString(),
    ...(process.env.NODE_ENV !== 'production' && { details: err.message })
  });
};

module.exports = errorHandler;