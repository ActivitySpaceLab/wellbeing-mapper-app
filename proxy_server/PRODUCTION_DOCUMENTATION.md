# Encrypted Survey Proxy Server - Production Documentation

**Version:** 1.0  
**Deployment Date:** September 16, 2025  
**Location:** AWS Lambda (Cape Town, af-south-1)  
**Purpose:** Secure encrypted survey data collection for Gauteng Wellbeing Research  

---

## 🏗️ Architecture Overview

### System Flow
```
📱 Flutter App
     ↓ (RSA 4096-bit encryption on device)
🔐 Encrypted Survey Blob  
     ↓ (HTTPS POST to AWS Lambda)
☁️  AWS Lambda Proxy Server (Cape Town)
     ↓ (Qualtrics API call)
📊 Qualtrics Survey Database (SV_81uhgIyzv52qgdM)
```

### Key Components
- **Mobile App**: RSA encrypts complete survey responses before transmission
- **AWS Lambda**: Serverless proxy in South Africa for data sovereignty
- **Qualtrics API**: Final storage destination for encrypted survey data
- **No Persistent Storage**: Data flows through proxy without being stored

---

## 🔧 How the Server Was Built

### 1. Initial Setup
- Created Express.js server for HTTP handling
- Added security middleware (helmet, CORS, compression)
- Implemented health check and data forwarding endpoints
- Added comprehensive error handling and logging

### 2. AWS Deployment
- Packaged server with serverless-http adapter for Lambda
- Created deployment scripts with regional restrictions (af-south-1)
- Set up IAM roles with minimal required permissions
- Configured environment variables for API tokens

### 3. Qualtrics Integration
- **Initial Problem**: Tried form submission (failed - no data stored)
- **Solution**: Switched to Qualtrics API v3 with proper authentication
- **Field Mapping Discovery**: Found QID_TEXT format required for text fields
- **Final Working Format**: QID1_TEXT, QID2_TEXT, QID3_TEXT

### 4. Security Implementation
- API tokens stored as encrypted Lambda environment variables
- Regional data processing (South Africa only)
- Zero hardcoded credentials in codebase
- HTTPS-only communication

---

## ⚙️ How It Works

### Data Processing
1. **Receives POST** to `/submit` endpoint
2. **Validates** required fields (encrypted_data, survey_type, timestamp)
3. **Forwards** to Qualtrics API using proper field mapping
4. **Returns** success/failure response to mobile app
5. **No Storage**: Data passes through without persistence

### Field Mapping
```javascript
{
  values: {
    QID1_TEXT: encrypted_data,    // Encrypted survey blob
    QID2_TEXT: survey_type,       // "initial", "biweekly", or "consent"
    QID3_TEXT: timestamp          // ISO 8601 timestamp
  }
}
```

### Error Handling
- Invalid requests (400 Bad Request)
- Missing fields (400 Bad Request)
- Qualtrics API failures (500 Internal Server Error)
- Network timeouts (500 Internal Server Error)

---

## 🚨 Critical Production Information

### ⚠️ Data Storage Policy
**IMPORTANT**: The proxy server **DOES NOT STORE** any survey data permanently:
- Data flows through Lambda memory only
- No database or file storage
- Lambda containers are ephemeral and destroyed after requests
- **If forwarding to Qualtrics fails, data is LOST**

### 🔄 Failure Handling Strategy

#### Current Mobile App Behavior
- App currently assumes success if proxy responds with 200 status
- **CRITICAL GAP**: No verification that data reached Qualtrics
- **RECOMMENDATION**: Implement robust retry mechanism

#### Recommended Mobile App Improvements
```dart
// Enhanced error handling in encrypted_survey_service.dart
static Future<bool> _sendToProxy(String surveyType, String encryptedBlob) async {
  try {
    final response = await http.post(/* ... */);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Parse response to verify Qualtrics success
      final result = jsonDecode(response.body);
      if (result['success'] == true) {
        return true; // Confirmed delivery to Qualtrics
      }
    }
    
    // Any failure - keep data for retry
    return false;
    
  } catch (e) {
    // Network/connection failure - keep data for retry
    return false;
  }
}
```

---

## 🛠️ Production Monitoring & Maintenance

### Health Check
**URL**: `https://6p7hir7licc5yisxhkner4wt2i0yhtzo.lambda-url.af-south-1.on.aws/health`

**Expected Response**:
```json
{
  "status": "healthy",
  "timestamp": "2025-09-16T11:38:24.127Z",
  "message": "Encrypted Survey Proxy Server",
  "version": "1.0.0"
}
```

**Monitor This**: Set up automated monitoring to check this endpoint every 5 minutes.

### Quick Test Commands
```bash
# Health check
curl https://6p7hir7licc5yisxhkner4wt2i0yhtzo.lambda-url.af-south-1.on.aws/health

# Full test suite
cd /path/to/proxy_server
node test/test-proxy.js https://6p7hir7licc5yisxhkner4wt2i0yhtzo.lambda-url.af-south-1.on.aws

# Single data test
curl -X POST https://6p7hir7licc5yisxhkner4wt2i0yhtzo.lambda-url.af-south-1.on.aws/submit \
  -H "Content-Type: application/json" \
  -d '{"encrypted_data":"MONITOR_TEST_'$(date +%s)'","survey_type":"initial","timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%S.000Z)'"}'
```

### AWS CloudWatch Monitoring
- **Log Group**: `/aws/lambda/gauteng-wellbeing-proxy`
- **View Logs**: AWS Console → CloudWatch → Log Groups
- **Key Metrics**: Invocation count, error rate, duration

### Qualtrics Data Verification
- **Survey URL**: https://pretoria.eu.qualtrics.com/jfe/form/SV_81uhgIyzv52qgdM
- **Data & Analysis**: Check for new responses with proper field data
- **Expected Fields**: encrypted_data, survey_type, timestamp populated

---

## 🚨 Emergency Procedures

### If Proxy Server Fails

#### 1. Quick Diagnostics
```bash
# Test health endpoint
curl https://6p7hir7licc5yisxhkner4wt2i0yhtzo.lambda-url.af-south-1.on.aws/health

# Check AWS Lambda status
aws lambda get-function --function-name gauteng-wellbeing-proxy --region af-south-1
```

#### 2. Common Issues & Fixes

**Health check fails (no response)**:
- Lambda function may be down
- Check AWS Lambda console for errors
- Redeploy: `./deploy/deploy-aws.sh`

**Health check returns error**:
- Check CloudWatch logs for specific error
- API token may have expired
- Environment variables may be corrupted

**Data not reaching Qualtrics**:
- Verify Qualtrics API token is still valid
- Check Qualtrics survey is still active
- Run test suite to isolate issue

#### 3. Redeployment Process
```bash
cd /path/to/proxy_server
./deploy/deploy-aws.sh
```

### If Qualtrics Fails

#### 1. Verify Qualtrics Status
- Check if survey `SV_81uhgIyzv52qgdM` is still active
- Verify API token hasn't expired
- Test manual API submission

#### 2. API Token Renewal
```bash
# Update Lambda environment variables
aws lambda update-function-configuration \
  --function-name gauteng-wellbeing-proxy \
  --environment Variables='{
    ALLOWED_ORIGINS=*,
    NODE_ENV=production,
    QUALTRICS_API_TOKEN=new_token_here
  }' \
  --region af-south-1
```

---

## 🔐 Security Considerations

### AWS IAM Permissions
**Current User**: `GautengWellbeingMapper`
**Recommended**: Remove `IAMFullAccess` after setup, keep only:
- Custom policy with Lambda permissions
- API Gateway permissions (if needed)

### API Token Security
- **Storage**: Lambda environment variables (encrypted at rest)
- **Access**: Only Lambda function can access
- **Rotation**: Manually update when needed
- **Monitoring**: No token exposure in logs

### Regional Compliance
- **Processing**: af-south-1 (Cape Town) only
- **Data Flow**: South Africa → South Africa
- **IAM Restrictions**: Regional policies in place

---

## 📊 Performance & Scaling

### Current Configuration
- **Memory**: 256 MB
- **Timeout**: 30 seconds
- **Concurrency**: AWS default (1000 concurrent executions)
- **Cold Start**: ~1-2 seconds first request

### Expected Load
- **Research Duration**: 6 months
- **Typical Load**: Hundreds of survey submissions per day
- **Peak Load**: Thousands of submissions per day
- **Lambda Limits**: Well within AWS free tier

### Scaling Considerations
- Lambda auto-scales automatically
- No manual intervention needed for normal research loads
- Monitor CloudWatch for any timeout issues

---

## 🔄 Backup & Recovery

### Code Backup
- **Primary**: Git repository in `proxy_server/` (public repository)
- **AWS**: Lambda function code stored in AWS
- **Local**: Complete codebase on development machine

### Configuration Backup
```bash
# Backup current Lambda configuration
aws lambda get-function-configuration \
  --function-name gauteng-wellbeing-proxy \
  --region af-south-1 > lambda-config-backup.json
```

### Recovery Process
1. **Code Recovery**: Redeploy from git repository
2. **Configuration Recovery**: Update environment variables
3. **Testing**: Run full test suite after recovery

---

## 📞 Emergency Contacts & Resources

### Key URLs
- **Production Proxy**: https://6p7hir7licc5yisxhkner4wt2i0yhtzo.lambda-url.af-south-1.on.aws
- **Health Check**: https://6p7hir7licc5yisxhkner4wt2i0yhtzo.lambda-url.af-south-1.on.aws/health
- **Qualtrics Survey**: https://pretoria.eu.qualtrics.com/jfe/form/SV_81uhgIyzv52qgdM
- **AWS Console**: https://af-south-1.console.aws.amazon.com/lambda/

### AWS Account Details
- **Account ID**: 736904063576
- **Region**: af-south-1 (Cape Town)
- **Function Name**: gauteng-wellbeing-proxy
- **IAM User**: GautengWellbeingMapper

### Development Environment
- **Repository**: gauteng-wellbeing-mapper-app
- **Branch**: feature/fix-qualtrics-data-collection
- **Directory**: proxy_server/ (publicly tracked)
- **Test Suite**: test/test-proxy.js

---

## 🚀 Future Improvements

### High Priority (Recommended for 6-month research)
1. **Enhanced Mobile App Error Handling**: Implement proper retry mechanism
2. **Dead Letter Queue**: Store failed submissions for manual recovery
3. **CloudWatch Alarms**: Automated alerts for failures
4. **Response Verification**: Confirm data reached Qualtrics before marking success

### Medium Priority
1. **Structured Logging**: Better log analysis
2. **Performance Monitoring**: Response time tracking
3. **Automated Health Checks**: External monitoring service
4. **Configuration Management**: Centralized config updates

### Lower Priority
1. **Multiple Survey Support**: If requirements change
2. **Data Analytics**: Usage patterns and trends
3. **Cost Optimization**: Reserved capacity if needed

---

## ✅ Final Production Checklist

### Before Research Starts
- [ ] Health check endpoint responding
- [ ] Test suite passing (6/6 tests)
- [ ] Qualtrics receiving test data correctly
- [ ] Mobile app updated with production URL
- [ ] CloudWatch monitoring set up
- [ ] Backup procedures documented
- [ ] Emergency procedures tested

### Weekly Monitoring
- [ ] Run health check
- [ ] Check Qualtrics for new responses
- [ ] Review CloudWatch logs for errors
- [ ] Verify API token hasn't expired
- [ ] Test mobile app submission end-to-end

### Monthly Maintenance
- [ ] Run full test suite
- [ ] Review AWS costs
- [ ] Update documentation if needed
- [ ] Backup Lambda configuration
- [ ] Check for AWS service updates

---

**Document Version**: 1.0  
**Last Updated**: September 16, 2025  
**Next Review**: October 16, 2025  

---

## 🆘 Quick Reference Commands

```bash
# Emergency redeployment
cd proxy_server && ./deploy/deploy-aws.sh

# Health check
curl https://6p7hir7licc5yisxhkner4wt2i0yhtzo.lambda-url.af-south-1.on.aws/health

# Full test
node test/test-proxy.js https://6p7hir7licc5yisxhkner4wt2i0yhtzo.lambda-url.af-south-1.on.aws

# View logs
aws logs tail /aws/lambda/gauteng-wellbeing-proxy --region af-south-1 --follow
```