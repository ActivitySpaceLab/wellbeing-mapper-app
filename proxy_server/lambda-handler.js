const app = require('./server');

// AWS Lambda handler for Function URLs
exports.handler = async (event, context) => {
  // Function URL format uses requestContext.http instead of httpMethod
  if (event.requestContext && event.requestContext.http) {
    const serverless = require('serverless-http');
    const handler = serverless(app);
    return await handler(event, context);
  }
  
  // For direct Lambda invocation (health checks)
  return {
    statusCode: 200,
    body: JSON.stringify({
      status: 'healthy',
      message: 'Encrypted Survey Proxy Lambda',
      timestamp: new Date().toISOString()
    })
  };
};