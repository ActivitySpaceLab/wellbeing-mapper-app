#!/usr/bin/env python3
"""
Test the Flutter-style hybrid encryption to match the Dart implementation
"""

import json
import base64
import os
from cryptography.hazmat.primitives import serialization, hashes
from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.backends import default_backend
import sys

# Add the decryption tools to path
sys.path.append('decryption_tools')
from decrypt_survey_data import decrypt_hybrid_format

def test_flutter_style_hybrid():
    """Test hybrid encryption matching the Flutter implementation exactly"""
    
    print("Testing Flutter-Style Hybrid Encryption")
    print("=" * 50)
    
    # Sample survey data
    sample_survey = {
        'type': 'biweekly_survey',
        'participant_uuid': 'test-uuid-12345',
        'data': {'mood': 'happy', 'stress_level': 3}
    }
    
    survey_json = json.dumps(sample_survey)
    print(f"Survey JSON: {survey_json}")
    
    try:
        # Load keys
        with open('decryption_tools/../../untracked/public_key.pem', 'rb') as f:
            public_key = serialization.load_pem_public_key(f.read(), backend=default_backend())
        
        # Step 1: Generate AES key (matching Flutter: Random.secure() + 32 bytes)
        import secrets
        aes_key = secrets.token_bytes(32)
        print(f"AES key: {len(aes_key)} bytes")
        
        # Step 2: XOR encryption (matching Flutter implementation)
        data_bytes = survey_json.encode('utf-8')
        encrypted_data = bytearray(len(data_bytes))
        for i in range(len(data_bytes)):
            encrypted_data[i] = data_bytes[i] ^ aes_key[i % len(aes_key)]
        
        # Step 3: Encrypt AES key with RSA 
        # Test 1: Raw bytes (like Python test that worked)
        try:
            encrypted_key_raw = public_key.encrypt(aes_key, padding.PKCS1v15())
            print(f"✅ Raw bytes RSA encryption: {len(encrypted_key_raw)} bytes")
        except Exception as e:
            print(f"❌ Raw bytes failed: {e}")
            
        # Test 2: String from char codes (like Flutter String.fromCharCodes)
        try:
            aes_key_string = ''.join(chr(b) for b in aes_key)
            encrypted_key_string = public_key.encrypt(aes_key_string.encode('latin-1'), padding.PKCS1v15())
            print(f"✅ String chars RSA encryption: {len(encrypted_key_string)} bytes")
        except Exception as e:
            print(f"❌ String chars failed: {e}")
            
        # Test 3: Base64 encoded (original approach)
        try:
            aes_key_b64 = base64.b64encode(aes_key).decode('utf-8')
            encrypted_key_b64 = public_key.encrypt(aes_key_b64.encode('utf-8'), padding.PKCS1v15())
            print(f"✅ Base64 RSA encryption: {len(encrypted_key_b64)} bytes")
        except Exception as e:
            print(f"❌ Base64 failed: {e}")
        
        # Create package with the working method (raw bytes)
        hybrid_package = {
            'encryptedData': base64.b64encode(encrypted_data).decode('utf-8'),
            'encryptedKey': base64.b64encode(encrypted_key_raw).decode('utf-8'),
            'algorithm': 'AES-256-GCM + RSA-PKCS1',
            'researchSite': 'gauteng',
            'timestamp': '2023-08-15T10:30:00Z'
        }
        
        # Test decryption with production passphrase
        print("\nTesting decryption with raw bytes approach:")
        passphrase = input("Enter private key passphrase: ")
        decrypted = decrypt_hybrid_format(hybrid_package, 'decryption_tools/../../untracked/private_key.pem', passphrase)
        
        if decrypted and decrypted == sample_survey:
            print("✅ Raw bytes approach works perfectly!")
        else:
            print("❌ Raw bytes approach failed")
            
        # Test with Flutter-style string approach
        if 'encrypted_key_string' in locals():
            hybrid_package_string = hybrid_package.copy()
            hybrid_package_string['encryptedKey'] = base64.b64encode(encrypted_key_string).decode('utf-8')
            
            print("\nTesting decryption with string chars approach:")
            
            # Need to modify decryption to handle string chars
            # The issue is that we need to convert back from latin-1 to bytes
            
    except Exception as e:
        print(f"❌ Test failed: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    os.chdir('/Users/palmer/projects/space_mapper_app/current/gauteng-wellbeing-mapper-app')
    test_flutter_style_hybrid()