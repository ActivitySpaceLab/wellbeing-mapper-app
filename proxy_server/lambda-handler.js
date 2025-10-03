const app = require('./server');

// AWS Lambda handler for Function URLs and API Gateway
exports.handler = async (event, context) => {
  // Check if this is a Function URL or API Gateway event
  const isWebEvent = event.httpMethod || 
                    (event.requestContext && (event.requestContext.httpMethod || event.requestContext.http));
  
  if (isWebEvent) {
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