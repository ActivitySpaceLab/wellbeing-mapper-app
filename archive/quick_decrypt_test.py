#!/usr/bin/env python3
"""
Quick test to decrypt the location data from the debug output
"""

import json
import base64
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.backends import default_backend

def decrypt_location_data(encrypted_data_json, private_key_path, password="wellbeing123"):
    """
    Decrypt location data using the format from the Flutter app
    """
    try:
        # Load private key
        with open(private_key_path, 'rb') as key_file:
            private_key = serialization.load_pem_private_key(
                key_file.read(),
                password=password.encode('utf-8') if password else None,
                backend=default_backend()
            )
        
        # Parse the encrypted data
        encrypted_data = json.loads(encrypted_data_json)
        
        # Extract components
        encrypted_aes_key_b64 = encrypted_data.get('encryptedKey')
        encrypted_location_data_b64 = encrypted_data.get('encryptedData')
        
        if not encrypted_aes_key_b64 or not encrypted_location_data_b64:
            print("❌ Missing encryption components")
            return None
        
        # Decrypt AES key using PKCS1v15 padding (as used by Flutter app)
        encrypted_aes_key = base64.b64decode(encrypted_aes_key_b64)
        aes_key = private_key.decrypt(
            encrypted_aes_key,
            padding.PKCS1v15()  # Flutter app uses PKCS1v15, not OAEP
        )
        
        # Decrypt location data using simple XOR (as implemented in Flutter app)
        encrypted_location_data = base64.b64decode(encrypted_location_data_b64)
        
        # The Flutter app uses simple XOR with key cycling
        decrypted_data = []
        for i in range(len(encrypted_location_data)):
            decrypted_data.append(encrypted_location_data[i] ^ aes_key[i % len(aes_key)])
        
        # Convert to string and parse JSON
        location_json = bytes(decrypted_data).decode('utf-8')
        location_data = json.loads(location_json)
        
        return location_data
        
    except Exception as e:
        print(f"❌ Error decrypting: {e}")
        return None

# Test with the provided encrypted data
encrypted_data_string = '''{"encryptedData":"GEYJCQQJHQMEAikPGxFTSCgPVxoWDBAODhgYXEW0saxUXFRRU1BdRkkAAgAIGQUHFxFXTFpPSlRCSkVJT7G3rkEQDAsCGx0LBhxPVE1CQUBGWUVOWklJLkpKR09GurW7TV1TVD1KRUgKDw4bHRESC1FORlhGQVVYGhAJFwv15edBXkhVSVtFSBgcCAsLUktCXUVCWlUZGg4SChQKBqK7oBQFCQ0OBg5IFkAWTAMRBRsHARETVUJNSlVLRU9LtrSuQQgKCAABHR8PCU9UQkdCXEpCTU9PQE9WWQgUExrz9eMOFEdcRVpZWF5BXVZCQUEmQkJPRE9CTUxVTEpJJaKtoAIHBhMVCQoTSVZbQFxEXVASGAEfAw0dH1lGUE1Rs62gEBQAAwNKU1pFXVlCTRESBhoCHAIOWkNYEhIiCBro6OEPAUcbSxNLBgoYBBoaFBRQSUBFWEBASElMTU9SXezu7AQNERMDDUtQRlteQFZGSEJDQkFaVQwQFx4PCR8S8KO4QVZVVFJFWVJGXV06XkZLQUJOREJZQU9JIV5RXB7j4vcRBQYfRVJfRFpeQUwOHAUbBwERE1VCVElVT1FcDPDk5wdGX1ZJW0VICg8ZBxkZBQtRTlcfGScPHxMVHhIaovyuGEYJBxMBHR8PCU9UW0BfRUtFR0FGVFsWFBIaFwv15edBXkhRVEZQXFJcX1ZDUgUbHhEGAhYVCVhBXk9OTbWssltJVFYzWV9QWF9XX1xeSEZLLldaVRkaGQ4OHB0GoruxTVBXSkUJBR4CGBgKClJLX0FaTFpVCwkfHhhfRE+us7VPRgQFEwEfAx8VT1RNGR8tBREdHxQUHFgGUAZcE+H16xcRAQNFUl1aRVtVX15JREFfVhkZGR8QDg4YGFxFrbaxTV1TXl5dXFhHThkHAhUCBhIZBVRNWktKSUlQTketsLI3VVNcVF5TX19CVFtZKlNeURUWFQIKGBkCX","encryptedKey":"hkFPQ2nGllTwmhpXCBYrBgkGHhEGAxYVCVlGbOTa0UsIDgsHBBkJGQcJHaOsp01TV0xSRl9RXE5KS0lJJ0FpRVZRQVFTVUJOWE5W4KeqQlZTV1FOQkNfRUJWW1lCWUlI8+vqABdGXElRUldTUEtFRklNSEVJKElGU1VBVUNfWkdNWWflsadIFhkYGhMJGh4OGBIVFB9NUE1YREFTVREbBg8fHx4NH1ZLVkmtraBCW1dUU05KW09cVFJVVUtGb+zm2gETVFNPXENYVVlLW05OVjlBXVdDVT06Q0hNTw3j8ekaXkFcS1VRV1hEX1VWVlFE9u3hDgFJWUdCTV5MVRMdAhUJGwgCCV5GWOHf1FYeABsIBR8RHg5CS09NVVdXQ0tB8P7qGFJGWUBRXEJYXhwQGQ8FBgkJV0ZY5ezTXwQYDg0BBwcGGk5HQF5LVF9LS0pPS1FWU09K5ez1DwEcR1xJWllYXkFdVkJBQSbrs6cOUF5DUkhUU09fVE5KT+Pu5Q8DF0RUTFRTTVZ","algorithm":"AES-256-GCM + RSA-PKCS1","researchSite":"gauteng","timestamp":"2025-08-11T20:33:37.457447"}'''

if __name__ == "__main__":
    print("🔍 Testing location data decryption...")
    
    # Try common passwords
    passwords = ["wellbeing123", "gauteng2025", "research123", "mapper2025", "", None]
    
    for password in passwords:
        print(f"\n🔑 Trying password: {'(empty)' if not password else '***'}")
        try:
            result = decrypt_location_data(
                encrypted_data_string,
                "private_key.pem",
                password
            )
            
            if result:
                print("✅ Decryption successful!")
                print(json.dumps(result, indent=2))
                break
                
        except Exception as e:
            print(f"❌ Failed with this password: {e}")
            continue
    else:
        print("\n❌ Could not decrypt with any of the tried passwords")
        print("The private key may require a different password")
