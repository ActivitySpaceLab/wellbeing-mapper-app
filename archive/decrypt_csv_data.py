#!/usr/bin/env python3
import json
import base64
import csv
from cryptography.hazmat.primitives import serialization, hashes
from cryptography.hazmat.primitives.asymmetric import rsa, padding

def decrypt_location_data():
    # Read the private key
    with open('private_key.pem', 'rb') as key_file:
        private_key = serialization.load_pem_private_key(
            key_file.read(),
            password=b'betakey'
        )
    
    # Read the CSV file
    csv_path = 'example_data/Gauteng Wellbeing Mapper - Biweekly Survey (Simple)_August 11, 2025_20.43.csv'
    
    with open(csv_path, 'r', encoding='utf-8') as file:
        reader = csv.DictReader(file)
        for row in reader:
            encrypted_location = row.get('Q18')
            if encrypted_location and encrypted_location.startswith('{"encryptedData"'):
                print(f"Found encrypted location data in row: {row.get('ResponseId', 'unknown')}")
                print(f"Encrypted data length: {len(encrypted_location)} characters")
                
                try:
                    # Parse the encrypted package
                    encrypted_package = json.loads(encrypted_location)
                    encrypted_data_b64 = encrypted_package['encryptedData']
                    encrypted_key_b64 = encrypted_package['encryptedKey']
                    
                    print(f"Encrypted AES key length: {len(encrypted_key_b64)} characters")
                    print(f"Encrypted data length: {len(encrypted_data_b64)} characters")
                    
                    # Decode from base64
                    encrypted_aes_key = base64.b64decode(encrypted_key_b64)
                    encrypted_data = base64.b64decode(encrypted_data_b64)
                    
                    # Decrypt the AES key using RSA
                    aes_key = private_key.decrypt(
                        encrypted_aes_key,
                        padding.PKCS1v15()
                    )
                    
                    print(f"Decrypted AES key: {aes_key}")
                    
                    # Decrypt the data using the simple XOR method from Flutter
                    decrypted_data = []
                    for i in range(len(encrypted_data)):
                        decrypted_data.append(encrypted_data[i] ^ aes_key[i % len(aes_key)])
                    
                    # Convert back to string
                    decrypted_json = bytes(decrypted_data).decode('utf-8')
                    location_data = json.loads(decrypted_json)
                    
                    print("\n=== DECRYPTED LOCATION DATA ===")
                    print(json.dumps(location_data, indent=2))
                    
                    # Extract and show location coordinates
                    if 'locationData' in location_data:
                        locations = location_data['locationData']
                        print(f"\n=== FOUND {len(locations)} LOCATION POINTS ===")
                        for i, loc in enumerate(locations[:5]):  # Show first 5
                            print(f"Location {i+1}: lat={loc.get('latitude')}, lng={loc.get('longitude')}")
                            print(f"  Timestamp: {loc.get('timestamp')}")
                            print(f"  Accuracy: {loc.get('accuracy')}m")
                            
                    return True
                    
                except Exception as e:
                    print(f"Decryption failed: {e}")
                    import traceback
                    traceback.print_exc()
                    
    print("No encrypted location data found in CSV")
    return False

if __name__ == "__main__":
    decrypt_location_data()
