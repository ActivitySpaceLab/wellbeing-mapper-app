# Encryption Configuration Guide for Wellbeing Mapper

This guide provides detailed instructions for configuring the RSA+AES hybrid encryption system used by the Wellbeing Mapper app for secure research data transmission.

## Encryption Overview

The Wellbeing Mapper app uses a hybrid encryption approach that combines the security of RSA asymmetric encryption with the performance of AES symmetric encryption:

1. **AES-256-GCM**: Used to encrypt the actual data payload (fast, efficient for large data)
2. **RSA-4096-OAEP**: Used to encrypt the AES key (secure key exchange)
3. **SHA-256**: Used for hashing and OAEP padding

## Data Flow

```
Participant Data → AES-256-GCM Encryption → RSA-4096 Key Encryption → Base64 Encoding → HTTPS Upload
     ↓                    ↓                       ↓                      ↓
Survey Responses    Random AES Key         Encrypted with          Secure Transit
Location Tracks     Generated Fresh        Research Team's         to Server
Demographics        for Each Upload        Public Key              
```

## Key Management Architecture

### Research Site Keys
Each research site (Barcelona and Gauteng) has its own independent RSA key pair:

```
Barcelona Study:
├── barcelona_private_key.pem (Server-side, SECRET)
└── barcelona_public_key.pem (Embedded in app)

Gauteng Study:
├── gauteng_private_key.pem (Server-side, SECRET)
└── gauteng_public_key.pem (Embedded in app)
```

## Step 1: Generate RSA Key Pairs

### For Barcelona Research Site

```bash
# Create directory for Barcelona keys
mkdir -p /secure/keys/barcelona
cd /secure/keys/barcelona

# Generate 4096-bit RSA private key
openssl genrsa -out barcelona_private_key.pem 4096

# Extract public key
openssl rsa -in barcelona_private_key.pem -pubout -out barcelona_public_key.pem

# Verify key generation
openssl rsa -in barcelona_private_key.pem -noout -text | head -20

# Set secure permissions
chmod 600 barcelona_private_key.pem
chmod 644 barcelona_public_key.pem
```

### For Gauteng Research Site

```bash
# Create directory for Gauteng keys
mkdir -p /secure/keys/gauteng
cd /secure/keys/gauteng

# Generate 4096-bit RSA private key
openssl genrsa -out gauteng_private_key.pem 4096

# Extract public key
openssl rsa -in gauteng_private_key.pem -pubout -out gauteng_public_key.pem

# Verify key generation
openssl rsa -in gauteng_private_key.pem -noout -text | head -20

# Set secure permissions
chmod 600 gauteng_private_key.pem
chmod 644 gauteng_public_key.pem
```

### Key Verification

```bash
# Test encryption/decryption with generated keys
echo "Test message" | openssl rsautl -encrypt -pubin -inkey barcelona_public_key.pem | openssl rsautl -decrypt -inkey barcelona_private_key.pem
```

## Step 2: Configure Mobile App

### Update Data Upload Service

Edit `/lib/services/data_upload_service.dart` and replace the placeholder public keys:

```dart
static const Map<String, ServerConfig> _serverConfigs = {
  'barcelona': ServerConfig(
    baseUrl: 'https://barcelona-research.your-domain.com',
    uploadEndpoint: '/api/v1/participant-data',
    publicKey: '''-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA1234567890abcdef...
[PASTE YOUR BARCELONA PUBLIC KEY CONTENT HERE - ALL LINES]
...1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
-----END PUBLIC KEY-----''',
  ),
  'gauteng': ServerConfig(
    baseUrl: 'https://gauteng-research.your-domain.com',
    uploadEndpoint: '/api/v1/participant-data',
    publicKey: '''-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA0987654321fedcba...
[PASTE YOUR GAUTENG PUBLIC KEY CONTENT HERE - ALL LINES]
...0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba
-----END PUBLIC KEY-----''',
  ),
};
```

### Get Public Key Content

To get the exact content to paste into the app:

```bash
# For Barcelona
cat /secure/keys/barcelona/barcelona_public_key.pem

# For Gauteng  
cat /secure/keys/gauteng/gauteng_public_key.pem
```

Copy the **entire** content including the `-----BEGIN PUBLIC KEY-----` and `-----END PUBLIC KEY-----` lines.

### Validate Configuration

After updating the app configuration, validate the keys are properly formatted:

```dart
// Add this test to your app's test suite
void testEncryptionKeys() {
  final barcelonaConfig = DataUploadService._serverConfigs['barcelona']!;
  final gautengConfig = DataUploadService._serverConfigs['gauteng']!;
  
  // Test that keys can be parsed
  expect(() => RSAKeyParser().parse(barcelonaConfig.publicKey), returnsNormally);
  expect(() => RSAKeyParser().parse(gautengConfig.publicKey), returnsNormally);
  
  print('✅ All public keys are valid');
}
```

## Step 3: Server-Side Decryption Setup

### Private Key Storage

Store private keys securely on your servers:

```bash
# On Barcelona server
sudo mkdir -p /etc/wellbeing-research/keys
sudo cp barcelona_private_key.pem /etc/wellbeing-research/keys/
sudo chown research-app:research-app /etc/wellbeing-research/keys/barcelona_private_key.pem
sudo chmod 600 /etc/wellbeing-research/keys/barcelona_private_key.pem

# On Gauteng server
sudo mkdir -p /etc/wellbeing-research/keys
sudo cp gauteng_private_key.pem /etc/wellbeing-research/keys/
sudo chown research-app:research-app /etc/wellbeing-research/keys/gauteng_private_key.pem
sudo chmod 600 /etc/wellbeing-research/keys/gauteng_private_key.pem
```

### Decryption Implementation (Node.js)

```javascript
const crypto = require('crypto');
const fs = require('fs');

class DataDecryptor {
  constructor(privateKeyPath) {
    this.privateKey = fs.readFileSync(privateKeyPath, 'utf8');
  }

  decryptUpload(encryptedPayload, encryptionMetadata) {
    try {
      // Parse the hybrid encrypted data
      // Format: base64(rsa_encrypted_aes_key)|base64(aes_encrypted_data)
      const [encryptedAESKeyB64, encryptedDataB64] = encryptedPayload.split('|');
      
      if (!encryptedAESKeyB64 || !encryptedDataB64) {
        throw new Error('Invalid encrypted payload format');
      }

      // Step 1: Decrypt AES key with RSA private key
      const encryptedAESKey = Buffer.from(encryptedAESKeyB64, 'base64');
      const aesKey = crypto.privateDecrypt(
        {
          key: this.privateKey,
          padding: crypto.constants.RSA_PKCS1_OAEP_PADDING,
          oaepHash: 'sha256'
        },
        encryptedAESKey
      );

      // Step 2: Decrypt data with AES-256-GCM
      const iv = Buffer.from(encryptionMetadata.iv, 'base64');
      const encryptedData = Buffer.from(encryptedDataB64, 'base64');
      
      // Split encrypted data and auth tag (last 16 bytes)
      const authTag = encryptedData.slice(-16);
      const ciphertext = encryptedData.slice(0, -16);
      
      const decipher = crypto.createDecipherGCM('aes-256-gcm', aesKey);
      decipher.setIV(iv);
      decipher.setAuthTag(authTag);
      
      let decrypted = decipher.update(ciphertext, null, 'utf8');
      decrypted += decipher.final('utf8');
      
      return JSON.parse(decrypted);
      
    } catch (error) {
      throw new Error(`Decryption failed: ${error.message}`);
    }
  }
}

// Usage example
const barcelonaDecryptor = new DataDecryptor('/etc/wellbeing-research/keys/barcelona_private_key.pem');
const gautengDecryptor = new DataDecryptor('/etc/wellbeing-research/keys/gauteng_private_key.pem');

// In your upload handler
app.post('/api/v1/participant-data', async (req, res) => {
  const { researchSite, encryptedData, encryptionMetadata } = req.body;
  
  try {
    const decryptor = researchSite === 'barcelona' ? barcelonaDecryptor : gautengDecryptor;
    const decryptedData = decryptor.decryptUpload(encryptedData, encryptionMetadata);
    
    // Process decrypted data
    await processParticipantData(decryptedData, req.body);
    
    res.json({ success: true, message: 'Data processed successfully' });
  } catch (error) {
    console.error('Decryption error:', error);
    res.status(400).json({ success: false, error: 'Decryption failed' });
  }
});
```

### Decrypted Data Structure

The decrypted JSON payload contains:

```json
{
  "participantUuid": "uuid-v4-string",
  "researchSite": "barcelona" | "gauteng",
  "uploadTimestamp": "2025-07-23T10:30:00Z",
  "surveys": [
    {
      "type": "initial" | "recurring",
      "submittedAt": "2025-07-23T10:30:00Z",
      "responses": {
        "wellbeingScore": 7,
        "stressLevel": 3,
        "suburb": "Sandton",  // Gauteng only
        "generalHealth": "good",  // Gauteng only
        // ... other survey fields
      }
    }
  ],
  "locationTracks": [
    {
      "timestamp": "2025-07-23T10:15:00Z",
      "latitude": -26.1076,
      "longitude": 28.0567,
      "accuracy": 10.5
    }
  ]
}
```

## Step 4: Testing the Encryption Pipeline

### End-to-End Test Script

Create a test script to verify the entire encryption/decryption pipeline:

```javascript
// test-encryption.js
const crypto = require('crypto');
const fs = require('fs');

// Test data
const testData = {
  participantUuid: '123e4567-e89b-12d3-a456-426614174000',
  researchSite: 'barcelona',
  uploadTimestamp: new Date().toISOString(),
  surveys: [{
    type: 'initial',
    submittedAt: new Date().toISOString(),
    responses: { wellbeingScore: 7, stressLevel: 3 }
  }],
  locationTracks: [{
    timestamp: new Date().toISOString(),
    latitude: 41.3851,
    longitude: 2.1734,
    accuracy: 15.0
  }]
};

function testEncryptionDecryption(publicKeyPath, privateKeyPath) {
  try {
    // Step 1: Generate AES key
    const aesKey = crypto.randomBytes(32); // 256-bit key
    const iv = crypto.randomBytes(12); // 96-bit IV for GCM
    
    // Step 2: Encrypt data with AES-256-GCM
    const cipher = crypto.createCipherGCM('aes-256-gcm', aesKey);
    cipher.setIV(iv);
    
    const jsonData = JSON.stringify(testData);
    let encrypted = cipher.update(jsonData, 'utf8');
    encrypted = Buffer.concat([encrypted, cipher.final()]);
    
    const authTag = cipher.getAuthTag();
    const encryptedDataWithTag = Buffer.concat([encrypted, authTag]);
    
    // Step 3: Encrypt AES key with RSA public key
    const publicKey = fs.readFileSync(publicKeyPath, 'utf8');
    const encryptedAESKey = crypto.publicEncrypt(
      {
        key: publicKey,
        padding: crypto.constants.RSA_PKCS1_OAEP_PADDING,
        oaepHash: 'sha256'
      },
      aesKey
    );
    
    // Step 4: Create final payload
    const finalPayload = encryptedAESKey.toString('base64') + '|' + encryptedDataWithTag.toString('base64');
    
    console.log('✅ Encryption successful');
    console.log('Payload size:', finalPayload.length, 'bytes');
    
    // Step 5: Test decryption
    const privateKey = fs.readFileSync(privateKeyPath, 'utf8');
    const [encryptedAESKeyB64, encryptedDataB64] = finalPayload.split('|');
    
    // Decrypt AES key
    const decryptedAESKey = crypto.privateDecrypt(
      {
        key: privateKey,
        padding: crypto.constants.RSA_PKCS1_OAEP_PADDING,
        oaepHash: 'sha256'
      },
      Buffer.from(encryptedAESKeyB64, 'base64')
    );
    
    // Decrypt data
    const encryptedDataBuffer = Buffer.from(encryptedDataB64, 'base64');
    const authTagFromData = encryptedDataBuffer.slice(-16);
    const ciphertext = encryptedDataBuffer.slice(0, -16);
    
    const decipher = crypto.createDecipherGCM('aes-256-gcm', decryptedAESKey);
    decipher.setIV(iv);
    decipher.setAuthTag(authTagFromData);
    
    let decrypted = decipher.update(ciphertext, null, 'utf8');
    decrypted += decipher.final('utf8');
    
    const decryptedData = JSON.parse(decrypted);
    
    console.log('✅ Decryption successful');
    console.log('Original data matches:', JSON.stringify(testData) === JSON.stringify(decryptedData));
    
    return true;
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
    return false;
  }
}

// Run tests
console.log('Testing Barcelona encryption...');
testEncryptionDecryption(
  '/secure/keys/barcelona/barcelona_public_key.pem',
  '/secure/keys/barcelona/barcelona_private_key.pem'
);

console.log('\nTesting Gauteng encryption...');
testEncryptionDecryption(
  '/secure/keys/gauteng/gauteng_public_key.pem',
  '/secure/keys/gauteng/gauteng_private_key.pem'
);
```

Run the test:
```bash
node test-encryption.js
```

### Mobile App Testing

Add this test to your Flutter test suite:

```dart
// test/encryption_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wellbeing_mapper/services/data_upload_service.dart';

void main() {
  group('Encryption Tests', () {
    test('can encrypt sample data', () async {
      final testData = {
        'participantUuid': '123e4567-e89b-12d3-a456-426614174000',
        'surveys': [{'wellbeingScore': 7}],
        'locationTracks': [{'latitude': 41.3851, 'longitude': 2.1734}]
      };

      final result = await DataUploadService.encryptData(testData, 'barcelona');
      
      expect(result.success, true);
      expect(result.encryptedData, isNotNull);
      expect(result.encryptedData!.contains('|'), true); // Should have key|data format
      expect(result.encryptionMetadata, isNotNull);
    });
    
    test('encryption produces different output each time', () async {
      final testData = {'test': 'data'};
      
      final result1 = await DataUploadService.encryptData(testData, 'barcelona');
      final result2 = await DataUploadService.encryptData(testData, 'barcelona');
      
      expect(result1.encryptedData, isNot(equals(result2.encryptedData)));
      expect(result1.encryptionMetadata!['iv'], isNot(equals(result2.encryptionMetadata!['iv'])));
    });
  });
}
```

## Step 5: Key Rotation Strategy

### Annual Key Rotation

1. **Generate new key pair**:
```bash
# Generate new keys with timestamp
openssl genrsa -out barcelona_private_key_2026.pem 4096
openssl rsa -in barcelona_private_key_2026.pem -pubout -out barcelona_public_key_2026.pem
```

2. **Update app configuration** with new public key
3. **Deploy new app version** to all participants
4. **Keep old private key** for 6 months to decrypt legacy uploads
5. **Securely destroy old keys** after transition period

### Emergency Key Rotation

If keys are compromised:
1. **Immediately** generate new keys
2. **Emergency app update** with new public keys
3. **Revoke old keys** on all servers
4. **Notify research ethics boards** of security incident

## Security Best Practices

### Key Storage
- **Hardware Security Modules (HSM)**: Use HSM for production private keys
- **File Permissions**: `600` for private keys, `644` for public keys
- **Backup Encryption**: Encrypt all key backups with strong passphrases
- **Access Logging**: Log all access to private key files

### Operational Security
- **Principle of Least Privilege**: Only essential personnel access private keys
- **Key Escrow**: Securely store backup copies with trusted third parties
- **Regular Audits**: Quarterly security audits of key management procedures
- **Incident Response**: Documented procedures for suspected key compromise

### Monitoring
- **Decryption Failures**: Alert on unusual decryption failure rates
- **Key Usage**: Log and monitor private key usage patterns
- **Access Attempts**: Monitor failed authentication attempts
- **System Health**: Regular checks of encryption/decryption performance

## Troubleshooting

### Common Issues

**"Invalid key format" error**:
- Verify public key includes complete `-----BEGIN/END PUBLIC KEY-----` headers
- Check for extra whitespace or missing newlines
- Validate key with `openssl rsa -pubin -in key.pem -noout -text`

**"Decryption failed" error**:
- Verify private key matches the public key used for encryption
- Check file permissions on private key (must be readable by app)
- Ensure AES IV is correctly extracted from metadata

**"Payload too large" error**:
- Check server request size limits (increase if needed)
- Verify base64 encoding is working correctly
- Consider data compression before encryption

### Diagnostic Commands

```bash
# Verify key pair match
diff <(openssl rsa -in private.pem -pubout) <(cat public.pem)

# Test key encryption/decryption
echo "test" | openssl rsautl -encrypt -pubin -inkey public.pem | openssl rsautl -decrypt -inkey private.pem

# Check key details
openssl rsa -in private.pem -noout -text | grep "Private-Key"
openssl rsa -pubin -in public.pem -noout -text | grep "Public-Key"
```

## Support

For encryption-related issues:
1. **Check the logs** for specific error messages
2. **Verify key formats** using OpenSSL commands
3. **Test end-to-end** with the provided test scripts
4. **Contact the development team** with detailed error information

Remember: Never share private keys in support requests or logs!
