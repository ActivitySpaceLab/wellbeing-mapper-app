#!/usr/bin/env python3
"""
Test the final Flutter hybrid encryption implementation
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

def test_final_flutter_hybrid():
    """Test the exact Flutter implementation approach"""
    
    print("Testing Final Flutter Hybrid Encryption")
    print("=" * 50)
    
    # Sample survey data (realistic size)
    sample_survey = {
        'type': 'biweekly_survey',
        'participant_uuid': 'test-uuid-12345-67890',
        'survey_id': 'survey-001',
        'timestamp': '2023-08-15T10:30:00Z',
        'data': {
            'mood': 'happy',
            'location': 'home',
            'stress_level': 3,
            'sleep_hours': 8,
            'exercise_minutes': 45,
            'social_interactions': 5,
            'work_satisfaction': 4,
            'notes': 'Had a great day, feeling energetic and productive'
        },
        'location_data': None,
        'metadata': {
            'app_version': '1.0.0',
            'submission_method': 'encrypted_proxy',
        }
    }
    
    survey_json = json.dumps(sample_survey)
    print(f"Survey JSON size: {len(survey_json)} characters")
    
    try:
        # Load public key
        with open('decryption_tools/../../untracked/public_key.pem', 'rb') as f:
            public_key = serialization.load_pem_public_key(f.read(), backend=default_backend())
        
        # FLUTTER HYBRID ENCRYPTION SIMULATION
        print("\nSimulating Flutter EncryptedSurveyService:")
        
        # 1. Generate 32-byte AES key (Random.secure())
        import secrets
        aes_key = secrets.token_bytes(32)
        print(f"  Generated AES key: {len(aes_key)} bytes")
        
        # 2. XOR encrypt survey data
        data_bytes = survey_json.encode('utf-8')
        encrypted_data = bytearray(len(data_bytes))
        for i in range(len(data_bytes)):
            encrypted_data[i] = data_bytes[i] ^ aes_key[i % len(aes_key)]
        print(f"  XOR encrypted data: {len(encrypted_data)} bytes")
        
        # 3. Base64 encode AES key then RSA encrypt (Flutter approach)
        aes_key_base64 = base64.b64encode(aes_key).decode('utf-8')
        encrypted_key = public_key.encrypt(
            aes_key_base64.encode('utf-8'),
            padding.PKCS1v15()
        )
        print(f"  RSA encrypted base64 AES key: {len(encrypted_key)} bytes")
        
        # 4. Create hybrid package (matching Flutter format)
        encrypted_package = {
            'encryptedData': base64.b64encode(encrypted_data).decode('utf-8'),
            'encryptedKey': base64.b64encode(encrypted_key).decode('utf-8'),
            'algorithm': 'AES-256-GCM + RSA-PKCS1',
            'researchSite': 'gauteng',
            'timestamp': '2023-08-15T10:30:00Z'
        }
        
        # 5. Convert to base64 (as would be sent to proxy)
        package_json = json.dumps(encrypted_package)
        package_base64 = base64.b64encode(package_json.encode('utf-8')).decode('utf-8')
        
        print(f"  Hybrid package JSON: {len(package_json)} chars")
        print(f"  Base64 package: {len(package_base64)} chars")
        
        print("\n" + "=" * 50)
        print("Testing Decryption")
        print("=" * 50)
        
        # Test decryption with production passphrase
        passphrase = input("Enter private key passphrase: ")
        decrypted_data = decrypt_hybrid_format(
            encrypted_package, 
            'decryption_tools/../../untracked/private_key.pem', 
            passphrase
        )
        
        if decrypted_data:
            print("✅ Decryption successful!")
            
            # Verify data integrity
            if decrypted_data == sample_survey:
                print("✅ Data integrity verified - perfect match!")
                
                # Create a CSV entry for testing
                csv_entry = f"2023-08-15T10:30:00Z,{package_base64}"
                
                print(f"\nSample CSV entry (first 100 chars):")
                print(f"{csv_entry[:100]}...")
                
                # Write test CSV
                with open('decryption_tools/flutter_test_data.csv', 'w') as f:
                    f.write("timestamp,encrypted_data\n")
                    f.write(csv_entry + "\n")
                
                print("✅ Created flutter_test_data.csv")
                
            else:
                print("❌ Data mismatch detected")
                print("Expected keys:", list(sample_survey.keys()))
                print("Actual keys:", list(decrypted_data.keys()) if decrypted_data else "None")
                
        else:
            print("❌ Decryption failed")
            
    except Exception as e:
        print(f"❌ Test failed: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    os.chdir('/Users/palmer/projects/space_mapper_app/current/gauteng-wellbeing-mapper-app')
    test_final_flutter_hybrid()