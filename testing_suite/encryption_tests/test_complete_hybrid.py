#!/usr/bin/env python3
"""
Test the complete hybrid encryption/decryption flow with real RSA keys
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

def test_hybrid_encryption():
    """Test complete hybrid encryption/decryption with real keys"""
    
    print("Testing Hybrid AES/RSA Encryption")
    print("=" * 50)
    
    # Sample survey data (like what Flutter would encrypt)
    sample_survey = {
        'type': 'biweekly_survey',
        'participant_uuid': 'test-uuid-12345',
        'survey_id': 'test-survey-001',
        'timestamp': '2023-08-15T10:30:00Z',
        'data': {
            'mood': 'happy',
            'location': 'home',
            'stress_level': 3,
            'sleep_hours': 8
        },
        'metadata': {
            'app_version': '1.0.0',
            'submission_method': 'encrypted_proxy',
        }
    }
    
    # Convert to JSON string
    survey_json = json.dumps(sample_survey)
    print(f"Original survey JSON size: {len(survey_json)} characters")
    
    try:
        # Load the public key for encryption
        with open('../untracked/public_key.pem', 'rb') as f:
            public_key = serialization.load_pem_public_key(f.read(), backend=default_backend())
        
        print("✅ Public key loaded successfully")
        
        # Simulate the Flutter hybrid encryption process
        import secrets
        
        # 1. Generate random AES key (32 bytes for AES-256)
        aes_key = secrets.token_bytes(32)
        print(f"Generated AES key: {len(aes_key)} bytes")
        
        # 2. Encrypt survey data with XOR (matching Flutter implementation)
        survey_bytes = survey_json.encode('utf-8')
        encrypted_data = bytearray(len(survey_bytes))
        for i in range(len(survey_bytes)):
            encrypted_data[i] = survey_bytes[i] ^ aes_key[i % len(aes_key)]
        
        print(f"XOR encrypted data: {len(encrypted_data)} bytes")
        
        # 3. Encrypt AES key with RSA (encrypt the raw bytes, not base64)
        encrypted_key = public_key.encrypt(
            aes_key,  # Encrypt raw AES key bytes
            padding.PKCS1v15()
        )
        encrypted_key_b64 = base64.b64encode(encrypted_key).decode('utf-8')
        
        print(f"RSA encrypted AES key: {len(encrypted_key)} bytes")
        
        # 4. Create the hybrid package (matching Flutter format)
        hybrid_package = {
            'encryptedData': base64.b64encode(encrypted_data).decode('utf-8'),
            'encryptedKey': encrypted_key_b64,
            'algorithm': 'AES-256-GCM + RSA-PKCS1',
            'researchSite': 'gauteng',
            'timestamp': '2023-08-15T10:30:00Z'
        }
        
        print("✅ Hybrid package created")
        print(f"   Encrypted data: {len(hybrid_package['encryptedData'])} chars")
        print(f"   Encrypted key: {len(hybrid_package['encryptedKey'])} chars")
        
        # 5. Test decryption
        print("\n" + "=" * 50)
        print("Testing Decryption")
        print("=" * 50)
        
        # Test decryption with production passphrase
        passphrase = input("Enter private key passphrase: ")
        decrypted_data = decrypt_hybrid_format(
            encrypted_package, 
            '../untracked/private_key.pem', 
            passphrase
        )
        
        if decrypted_data:
            print("✅ Decryption successful!")
            print("Decrypted survey data:")
            print(json.dumps(decrypted_data, indent=2))
            
            # Verify the data matches
            if decrypted_data == sample_survey:
                print("\n✅ Data integrity verified - original and decrypted data match!")
            else:
                print("\n❌ Data mismatch - decrypted data differs from original")
                
        else:
            print("❌ Decryption failed")
            
    except Exception as e:
        print(f"❌ Test failed: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    # Change to the project root directory
    os.chdir('/Users/palmer/projects/space_mapper_app/current/gauteng-wellbeing-mapper-app')
    test_hybrid_encryption()