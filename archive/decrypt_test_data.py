#!/usr/bin/env python3
"""
Quick script to decrypt the location data from the Qualtrics submission
"""

import json
import base64
from cryptography.hazmat.primitives import serialization, hashes
from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.backends import default_backend

# The encrypted data from the Qualtrics submission
encrypted_data_str = '{"encryptedData":"GEYJCQQJHQMEAikPGxFTSCgPVxoWDBAODhgYXEW0saxUXFRRU1BdRkkAAgAIGQUHFxFXTFpPSlRCSkVJT7G3rkEQDAsCGx0LBhxPVE1CQUBGWUVOWklJLkpKR09GurW7TV1TVD1KRUgKDw4bHRESC1FORlhGQVVYGhAJFwv15edBXkhVSVtFSBgcCAsLUktCXUVCWlUZGg4SChQKBqK7oBQFCQ0OBg5IFkAWTAMRBRsHARETVUJNSlVLRU5LtrSuQQgKCAABHR8PCU9UQkdCXEpCTU9PQE9WWQgUExrz9eMOFEdcRVpZWF5BXVZCQUEmQkJPRE9CTUxVTEpJJaKtoAIHBhMVCQoTSVZbQFxEXVASGAEfAw0dH1lGUE1Rs62gEBQAAwNKU1pFXVlCTRESBhoCHAIOWkNYEhIiCBro6OEPAUcbSxNLBgoYBBoaFBRQSUBFWEBASElMTU9SXezu7AQNERMDDUtQRlteQFZGSEJDQkFaVQwQFx4PCR8S8KO4QVZVVFJFWVJGXV06XkZLQUJOREJZQU9JIV5RXB7j4vcRBQYfRVJfRFpeQUwOHAUbBwERE1VCVElVT1FcDPDk5wdGX1ZJW0VICg8ZBxkZBQtRTlcfGScPHxMVHhIaovyuGEYJBxMBHR8PCU9UW0BfRUtFR0FGVFsWFBIaFwv15edBXkhRVEZQXFJcX1ZDUgUbHhEGAhYVCVhBXk9OTbWssltJVFYzWV9QWF9XX1xeSEZLLldaVRkaGQ4OHB0GoruxTVBXSkUJBR4CGBgKClJLX0FaTFpVCwkfHhhfRE+us7VPRgQFEwEfAx8VT1RNGR8tBREdHxQUHFgGUAZcE+H16xcRAQNFUl1aRVtVX15JREFfVhkZGR8QDg4YGFxFrbaxTV1TXl5dXFhHThkHAhUCBhIZBVRNWktKSUlQTketsLI3VVNcVF5TX19CVFtZKlNeURUWFQIKGBkCX","encryptedKey":"GhULXw4QFgUMAhtCQVdSSFpOT0hOBAgUDBQJFhINWRgLEQQeBwARE1lPVVIOCwgfHxFHQU5aHhQNHR8PC1FLREBETEhGUkxJWFcYAAYTEw0bGAsJTVhTSkAJAQECGVBGUEhQRlhCQlgOCgkOAAQJBFhFWRsHJBMMChUGFVRdURYQFwcMDAUBABhMRkhVQw8HDAgGCldHREBaSkpCUhkWAwIJABMTB1pHWFdHWUJJVQoRGwYNBRMLB1lAUFpJQkdCUAUeGh8CAw8eGEZLQUNXREFSXVhPTEtZT1lXXQcMHRAUCQYOClNAUFlPQwUFEEVCQUJdR0xZVkkMEQkTDQ0MEFgfUBJQTBAoAAkBA1NJSENWSEVZVE4CEwgZHBsSGVVET0dOS0lQR0YZDQ8NARYWFl5KGAgcJhYNHh8RRUBBVkpeWEhBUQcKGh8NAwcHF1pAQEJNQUtYXRsRGxIIAwsHH0VQQ1VGSUJBQgsQGhADHR8PGVhFQlZHQkFQUk1IVUhbUU1SFhAJGRISDwcfQkpLWEtRRE5CBA==","algorithm":"AES-256-GCM + RSA-PKCS1","researchSite":"gauteng","timestamp":"2025-08-11T21:46:12.639249"}'

def fix_base64_padding(data):
    """Fix base64 padding if needed"""
    missing_padding = len(data) % 4
    if missing_padding:
        data += '=' * (4 - missing_padding)
    return data

def decrypt_location_data(encrypted_str, private_key_path, password):
    try:
        # Parse the encrypted package
        encrypted_package = json.loads(encrypted_str)
        
        # Extract components and fix base64 padding
        encrypted_data_b64 = fix_base64_padding(encrypted_package['encryptedData'])
        encrypted_key_b64 = fix_base64_padding(encrypted_package['encryptedKey'])
        
        encrypted_data = base64.b64decode(encrypted_data_b64)
        encrypted_key = base64.b64decode(encrypted_key_b64)
        
        print(f"Algorithm: {encrypted_package['algorithm']}")
        print(f"Research Site: {encrypted_package['researchSite']}")
        print(f"Timestamp: {encrypted_package['timestamp']}")
        print(f"Encrypted data length: {len(encrypted_data)} bytes")
        print(f"Encrypted key length: {len(encrypted_key)} bytes")
        
        # Load the private key
        with open(private_key_path, 'rb') as key_file:
            private_key = serialization.load_pem_private_key(
                key_file.read(),
                password=password.encode() if password else None,
                backend=default_backend()
            )
        
        # Decrypt the AES key using RSA PKCS1v15 padding (matching Flutter app)
        try:
            aes_key = private_key.decrypt(
                encrypted_key,
                padding.PKCS1v15()
            )
            print(f"Successfully decrypted AES key: {len(aes_key)} bytes")
        except Exception as e:
            print(f"Error decrypting AES key: {e}")
            return None
        
        # Since the Flutter app uses XOR-based "AES" (not real AES-GCM), we need to use XOR
        print("Decrypting data using XOR (matching Flutter app implementation)...")
        decrypted_data = []
        for i in range(len(encrypted_data)):
            decrypted_data.append(encrypted_data[i] ^ aes_key[i % len(aes_key)])
        
        # Convert back to string and parse JSON
        decrypted_str = bytes(decrypted_data).decode('utf-8')
        location_data = json.loads(decrypted_str)
        
        return location_data
        
    except Exception as e:
        print(f"Error decrypting data: {e}")
        import traceback
        traceback.print_exc()
        return None

if __name__ == "__main__":
    private_key_path = "private_key.pem"
    password = "betakey"
    
    print("Decrypting location data...")
    print("=" * 50)
    
    result = decrypt_location_data(encrypted_data_str, private_key_path, password)
    
    if result:
        print("\n" + "=" * 50)
        print("DECRYPTION SUCCESSFUL!")
        print("=" * 50)
        print(f"Decrypted data structure:")
        print(json.dumps(result, indent=2))
        
        # Extract location data specifically
        if 'locationData' in result:
            locations = result['locationData']
            print(f"\nFound {len(locations)} location records:")
            print("-" * 30)
            
            for i, loc in enumerate(locations):
                if 'latitude' in loc and 'longitude' in loc:
                    lat, lon = loc['latitude'], loc['longitude']
                    timestamp = loc.get('timestamp', 'Unknown')
                    activity = loc.get('activity', 'Unknown')
                    print(f"Location {i+1}: {lat}, {lon} (Activity: {activity}, Time: {timestamp})")
                    
                    # Check if coordinates are in Manhattan area
                    if 40.7 <= lat <= 40.8 and -74.0 <= lon <= -73.9:
                        print(f"  ✅ This location is in Manhattan, NYC area")
                    else:
                        print(f"  ❌ This location does NOT appear to be in Manhattan")
        else:
            print("No 'locationData' field found in decrypted data")
    else:
        print("Failed to decrypt location data")
