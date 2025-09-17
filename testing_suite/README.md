# Testing Suite

This directory contains test scripts for validating encryption, decryption, and Flutter app functionality.

## 📁 Directory Structure

### `encryption_tests/`
Tests for encryption and decryption functionality:
- `test_complete_hybrid.py` - Comprehensive hybrid encryption testing
- `test_hybrid_format.py` - Format validation for hybrid encryption

### `flutter_tests/`
Tests for Flutter app functionality:
- `test_final_flutter.py` - Final Flutter integration testing
- `test_flutter_style.py` - Flutter code style and format validation

## 🧪 Running Tests

### Encryption Tests
```bash
cd encryption_tests
python test_complete_hybrid.py
python test_hybrid_format.py
```

### Flutter Tests
```bash
cd flutter_tests
python test_final_flutter.py
python test_flutter_style.py
```

## 📋 Test Coverage

- **Encryption/Decryption:** RSA + AES hybrid encryption validation
- **Data Format:** JSON structure and field validation
- **Flutter Integration:** App-level encryption/decryption workflow
- **Code Quality:** Style and format compliance

## 🔧 Test Requirements

- Python 3.8+
- Cryptography libraries
- Flutter SDK (for Flutter tests)
- Test data files (included in respective directories)

## 📊 Test Reports

Test results and reports are generated in the same directory as the test scripts. Check for:
- `test_results.txt` - Detailed test output
- `coverage_report.html` - Coverage analysis (when available)

## 🆘 Troubleshooting

If tests fail:
1. Check that all dependencies are installed
2. Verify test data files are present
3. Ensure Flutter SDK is properly configured (for Flutter tests)
4. Review error logs for specific failure details