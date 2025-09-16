# Encrypted Survey Proxy Server - Deployment Guide

This directory contains deployment configurations for the encrypted survey proxy server.

## Deployment Options

### 1. AWS Lambda (Recommended for Data Sovereignty)

**Why AWS Cape Town (af-south-1)?**
- Data sovereignty requirements for South African research data
- Lowest latency for mobile apps in Gauteng region
- GDPR/POPIA compliance with local data processing

**Deploy to AWS Lambda:**
```bash
# Install AWS CLI first
brew install awscli  # macOS
# or apt-get install awscli  # Ubuntu

# Configure AWS credentials
aws configure

# Deploy the proxy
./deploy-aws.sh
```

**Manual AWS Setup:**
```bash
# Create deployment package
npm run package

# Create Lambda function
aws lambda create-function \
  --function-name gauteng-wellbeing-proxy \
  --runtime nodejs18.x \
  --role arn:aws:iam::YOUR_ACCOUNT:role/lambda-execution-role \
  --handler index.handler \
  --zip-file fileb://proxy.zip \
  --region af-south-1

# Update function code
aws lambda update-function-code \
  --function-name gauteng-wellbeing-proxy \
  --zip-file fileb://proxy.zip \
  --region af-south-1
```

### 2. Vercel (Alternative)

**Deploy to Vercel:**
```bash
# Install Vercel CLI
npm install -g vercel

# Deploy from proxy_server directory
vercel deploy

# Production deployment
vercel deploy --prod
```

### 3. Docker (Self-hosted)

**Build and run with Docker:**
```bash
# Create Dockerfile
cat > Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY server.js ./
EXPOSE 3000
CMD ["node", "server.js"]
EOF

# Build image
docker build -t gauteng-proxy .

# Run container
docker run -p 3000:3000 \
  -e NODE_ENV=production \
  -e ALLOWED_ORIGINS=* \
  gauteng-proxy
```

## Environment Variables

Copy `.env.template` to `.env` and configure:

```bash
cp .env.template .env
# Edit .env with your settings
```

Key variables:
- `NODE_ENV`: Set to 'production' for live deployment
- `ALLOWED_ORIGINS`: CORS origins (use '*' for mobile apps)
- `PORT`: Server port (default: 3000)

## Testing

Test any deployment:
```bash
# Local testing
npm test

# Test specific URL
node test/test-proxy.js https://your-proxy-url.com

# Test health endpoint
curl https://your-proxy-url.com/health
```

## Monitoring

### AWS CloudWatch Logs
```bash
# View Lambda logs
aws logs tail /aws/lambda/gauteng-wellbeing-proxy --region af-south-1 --follow

# View API Gateway logs
aws logs tail API-Gateway-Execution-Logs_YOUR-API-ID/prod --region af-south-1
```

### Log Analysis
The proxy logs all requests with:
- Timestamp and request method/path
- Encrypted data size (not content)
- Survey type being submitted
- Success/failure status
- Qualtrics response codes

## Security Considerations

1. **No API Tokens**: Proxy never handles Qualtrics API tokens
2. **Encrypted Transit**: All survey data is RSA-encrypted before reaching proxy
3. **No Data Storage**: Proxy immediately forwards data, no persistence
4. **Request Validation**: Validates request format but not content
5. **CORS Protection**: Configurable allowed origins

## Cost Estimates

### AWS Lambda (Cape Town)
- **Requests**: R0.0000002 per request
- **Compute**: R0.0000166667 per GB-second
- **Data Transfer**: R0.09 per GB (outbound)

**Example Monthly Cost** (1000 surveys):
- 1000 requests × R0.0000002 = R0.0002
- 1000 × 100ms × 256MB = ~R0.004
- **Total: ~R0.01 per month**

### Vercel
- Free tier: 100GB bandwidth/month
- Pro tier: $20/month for commercial use

## Troubleshooting

### Common Issues

1. **CORS Errors**
   - Check `ALLOWED_ORIGINS` environment variable
   - Ensure mobile app URL is included

2. **Lambda Timeout**
   - Default timeout is 30 seconds
   - Increase with: `aws lambda update-function-configuration --timeout 60`

3. **Large Encrypted Payloads**
   - API Gateway limit: 10MB
   - Lambda limit: 6MB (synchronous)
   - Consider payload compression if needed

4. **Qualtrics Connection Issues**
   - Verify survey URLs are accessible
   - Check Qualtrics survey settings (anonymous responses enabled)
   - Validate form field names (QID1_TEXT, QID2_TEXT, QID3_TEXT)

### Debug Commands

```bash
# Test local proxy server
cd .. && node server.js &
npm test
kill %1

# Test AWS deployment
node test/test-proxy.js https://YOUR-API-ID.execute-api.af-south-1.amazonaws.com/prod

# Check Lambda function
aws lambda invoke \
  --function-name gauteng-wellbeing-proxy \
  --region af-south-1 \
  response.json && cat response.json
```

## Data Flow

1. **Mobile App** → Encrypts survey data with RSA public key
2. **Proxy Server** → Receives encrypted blob, forwards to Qualtrics
3. **Qualtrics** → Stores encrypted data in single text field
4. **Researchers** → Download and decrypt with RSA private key

This ensures end-to-end encryption with no intermediate plaintext exposure.