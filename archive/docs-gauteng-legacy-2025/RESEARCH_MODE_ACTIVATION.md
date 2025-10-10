# Research Mode Activation Guide

## Quick Start for Researchers

### Prerequisites
- Server set up according to [Server Setup Guide](SERVER_SETUP.md)
- Database configured with participant validation tables
- HTTPS endpoint for participant validation API

### Step 1: Add Participant Codes

1. **Generate participant codes** following your study protocol
2. **Use the provided script** to add codes to the database:

```bash
# Example: Add codes for Gauteng study
node scripts/add-participant-codes.js
```

Or manually via SQL:
```sql
-- Add individual participant codes
INSERT INTO participant_codes (hashed_code, study_site, notes) 
VALUES (
  SHA256('GTNG001'),
  'gauteng',
  'Pilot participant - batch 1'
);
```

### Step 2: Configure App Server URL

Update the app configuration in `lib/services/participant_validation_service.dart`:

```dart
// Update these when server is ready
static const String _baseUrl = 'https://your-research-server.org';
static const String _validateEndpoint = '/api/v1/participants/validate';
static const String _consentEndpoint = '/api/v1/participants/consent';
```

### Step 3: Enable Research Mode

In `lib/services/participant_validation_service.dart`, remove the early return that blocks all validation:

```dart
// REMOVE OR COMMENT OUT these lines:
print('[ParticipantValidation] Code validation attempted: ${cleanCode.substring(0, min(3, cleanCode.length))}*** (No codes in system yet)');
return ValidationResult(
  isValid: false,
  error: 'No participant codes are currently active in the system. Please contact the research team.',
);

// UNCOMMENT the server communication code below
```

### Step 4: Test the System

1. **Add a test code** to your database
2. **Build and test** the app with that code
3. **Verify consent recording** is working
4. **Check server logs** for validation attempts

### Step 5: Monitor Participation

Use the provided management scripts to monitor:

```bash
# Check participation statistics
node -e "
const { getParticipantStats } = require('./scripts/manage-codes.js');
getParticipantStats().then(console.table);
"

# Check recent consent activity
node -e "
const { getRecentActivity } = require('./scripts/manage-codes.js');
getRecentActivity(7).then(console.table);
"
```

## Production Checklist

- [ ] Server endpoints deployed and tested
- [ ] Database tables created with proper indexes
- [ ] Participant codes added to database
- [ ] App configuration updated with server URL
- [ ] Early return removed from validation service
- [ ] HTTPS certificate valid and working
- [ ] Rate limiting configured on validation endpoint
- [ ] Monitoring and logging set up
- [ ] Backup procedures in place
- [ ] Research team trained on code management

## Security Notes

- **Participant codes are hashed** before storage and transmission
- **No plain text codes** exist on server after initial import
- **Rate limiting** prevents brute force attacks
- **HTTPS required** for all communication
- **Consent timestamps** recorded for compliance

## Troubleshooting

### Common Issues

**"No participant codes are currently active"**
- Check that codes were added to database correctly
- Verify app configuration points to correct server
- Ensure early return is removed from validation service

**Validation always fails**
- Check server logs for validation attempts
- Verify HTTPS certificate is valid
- Test API endpoints with curl or Postman
- Check network connectivity from app

**Consent not recording**
- Verify consent endpoint is responding
- Check participant code was validated first
- Review server logs for consent recording attempts

### Debug Commands

```bash
# Test validation endpoint
curl -X POST https://your-server.org/api/v1/participants/validate \
  -H "Content-Type: application/json" \
  -d '{"hashed_code":"test_hash","timestamp":"2025-08-08T12:00:00Z"}'

# Check database contents
psql $DATABASE_URL -c "SELECT COUNT(*) FROM participant_codes WHERE is_active = true;"

# Monitor server logs
tail -f /var/log/wellbeing-research/api.log
```

## Support

For technical support with the participant validation system:

- **Documentation**: [Participant Validation System](PARTICIPANT_VALIDATION_SYSTEM.md)
- **Server Setup**: [Server Setup Guide](SERVER_SETUP.md)
- **Issues**: Contact development team through GitHub Issues
- **Security Concerns**: Contact the research team directly
