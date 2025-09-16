# Survey Data Decryption Tools

This directory contains tools and test data for decrypting survey data from the Gauteng Wellbeing Mapper app.

## Files

### Decryption Scripts
- `decrypt_survey_data.py` - Main decryption script for survey data from CSV files
- `test_hybrid_decryption.py` - Test script for hybrid AES/RSA encryption format

### Test Data
- `test_survey_data.csv` - Sample encrypted survey data for testing decryption
- `private_key.pem` - RSA private key for decryption (password protected)
- `public_key.pem` - RSA public key (for reference)

## Usage

### Basic Decryption
```bash
cd decryption_tools
python3 decrypt_survey_data.py
```

The script will:
1. Prompt for the private key passphrase
2. Load encrypted survey data from `test_survey_data.csv`
3. Attempt to decrypt each survey using both direct RSA and hybrid AES/RSA methods
4. Display the decrypted survey data

### Encryption Formats Supported
1. **Direct RSA Encryption** - Survey JSON encrypted directly with RSA PKCS1v15
2. **Hybrid AES/RSA Encryption** - Survey data encrypted with AES, AES key encrypted with RSA

## Key Information
- RSA Key Size: 4096 bits (512 bytes)
- Passphrase: `[your private key passphrase]` (for production keys)
- Padding: PKCS1v15
- AES Algorithm: XOR-based encryption (matching Flutter implementation)

## Troubleshooting

### Common Issues
1. **"Ciphertext length must be equal to key size"** - Data was encrypted with hybrid method but script tried direct RSA
2. **"Invalid base64-encoded string"** - Base64 padding issues, script includes auto-fixing
3. **"Encrypted data exceeds RSA key capacity"** - Survey data too large for direct RSA, needs hybrid encryption

### Key Size Limits
- Direct RSA encryption limited to ~501 bytes (4096-bit key with PKCS1v15 padding)
- Survey JSON data typically 1000+ bytes, requiring hybrid encryption
- Hybrid encryption has no practical size limit