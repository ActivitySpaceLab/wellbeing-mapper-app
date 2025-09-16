#!/usr/bin/env python3
"""
Test script to verify the decryption tool works with sample data.
This creates sample encrypted data and tests the decryption process.
"""

import json
import base64
from cryptography.hazmat.primitives import serialization, hashes
from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend
import os

def generate_test_keypair():
    """Generate a test RSA keypair"""
    private_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048,
        backend=default_backend()
    )
    
    # Serialize private key
    private_pem = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption()
    )
    
    # Get public key
    public_key = private_key.public_key()
    
    return private_key, public_key, private_pem

def encrypt_sample_location_data(public_key):
    """Create sample encrypted location data like the app would"""
    # Sample location data
    location_data = [
        {
            "timestamp": "2025-08-11T10:30:00Z",
            "latitude": -26.2041,
            "longitude": 28.0473,
            "accuracy": 5.0,
            "speed": 0.0,
            "heading": 0.0,
            "altitude": 1753.0
        },
        {
            "timestamp": "2025-08-11T10:35:00Z", 
            "latitude": -26.2045,
            "longitude": 28.0476,
            "accuracy": 8.0,
            "speed": 1.2,
            "heading": 45.0,
            "altitude": 1755.0
        }
    ]
    
    # Convert to JSON
    location_json = json.dumps(location_data)
    
    # Generate AES key
    aes_key = os.urandom(32)  # 256-bit key
    
    # Encrypt with AES
    iv = os.urandom(16)
    cipher = Cipher(algorithms.AES(aes_key), modes.CBC(iv), backend=default_backend())
    encryptor = cipher.encryptor()
    
    # Pad data to 16-byte boundary (PKCS7)
    pad_length = 16 - (len(location_json) % 16)
    padded_data = location_json.encode('utf-8') + bytes([pad_length]) * pad_length
    
    encrypted_data = encryptor.update(padded_data) + encryptor.finalize()
    encrypted_data_with_iv = iv + encrypted_data
    
    # Encrypt AES key with RSA
    encrypted_aes_key = public_key.encrypt(
        aes_key,
        padding.OAEP(
            mgf=padding.MGF1(algorithm=hashes.SHA256()),
            algorithm=hashes.SHA256(),
            label=None
        )
    )
    
    # Create final encrypted package
    encrypted_package = {
        "encryptedKey": base64.b64encode(encrypted_aes_key).decode('utf-8'),
        "encryptedData": base64.b64encode(encrypted_data_with_iv).decode('utf-8')
    }
    
    return json.dumps(encrypted_package)

def create_test_files():
    """Create test files for the decryption tool"""
    print("🧪 Creating test files for decryption tool...")
    
    # Generate keypair
    private_key, public_key, private_pem = generate_test_keypair()
    
    # Save private key
    with open('test_private_key.pem', 'wb') as f:
        f.write(private_pem)
    print("✅ Created test_private_key.pem")
    
    # Create encrypted location data
    encrypted_location = encrypt_sample_location_data(public_key)
    
    # Create sample CSV data
    csv_content = '''StartDate,EndDate,Status,Progress,Duration__in_seconds_,Finished,RecordedDate,ResponseId,DistributionChannel,UserLanguage,Q_RecaptchaScore,participantCode,participantUUID,QID_LOCATION
"Start Date","End Date","Response Type","Progress","Duration (in seconds)","Finished","Recorded Date","Response ID","Distribution Channel","User Language","Q_RecaptchaScore","Participant Code","Participant UUID","Location Data"
"2025-08-11 10:20:30","2025-08-11 10:25:45","IP Address","100","315","True","2025-08-11 10:25:45","R_TEST123","anonymous","EN","0.9","TESTUSER001","550e8400-e29b-41d4-a716-446655440000","''' + encrypted_location + '''"
"2025-08-11 11:15:20","2025-08-11 11:18:30","IP Address","100","190","True","2025-08-11 11:18:30","R_TEST124","anonymous","EN","0.8","TESTUSER002","550e8400-e29b-41d4-a716-446655440001",""'''
    
    # Save CSV file
    with open('test_qualtrics_export.csv', 'w') as f:
        f.write(csv_content)
    print("✅ Created test_qualtrics_export.csv")
    
    print("\n🎯 Test files created! You can now run:")
    print("   python decrypt_location_data.py")
    print("\nThe tool should automatically find and decrypt the test data.")

if __name__ == "__main__":
    create_test_files()
