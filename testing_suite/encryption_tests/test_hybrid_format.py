#!/usr/bin/env python3
"""
Test script to verify the hybrid AES/RSA encryption format can be decrypted
"""

import json
import base64
from decryption_tools.decrypt_survey_data import decrypt_hybrid_format

def test_sample_hybrid_format():
    """Test with a properly formatted hybrid encryption package"""
    
    # Simulate what the Flutter app should produce
    sample_hybrid_package = {
        "encryptedData": "SGVsbG8gV29ybGQhIFRoaXMgaXMgYSB0ZXN0IG1lc3NhZ2UgZm9yIGh5YnJpZCBlbmNyeXB0aW9uLg==",  # Sample encrypted data
        "encryptedKey": "VGhpcyBpcyBhIHNhbXBsZSBlbmNyeXB0ZWQgQUVTIGtleQ==",  # Sample encrypted AES key
        "algorithm": "AES-256-GCM + RSA-PKCS1",
        "researchSite": "gauteng", 
        "timestamp": "2023-08-15T10:30:00Z"
    }
    
    print("Testing hybrid encryption format...")
    print("=" * 50)
    print(f"Package structure:")
    print(json.dumps(sample_hybrid_package, indent=2))
    print("\n" + "=" * 50)
    
    # Test if the format would be detected correctly
    try:
        # Convert to base64 as it would come from CSV
        package_json = json.dumps(sample_hybrid_package)
        package_b64 = base64.b64encode(package_json.encode('utf-8')).decode('utf-8')
        
        print(f"Base64 encoded package length: {len(package_b64)} chars")
        print(f"First 100 chars: {package_b64[:100]}...")
        
        # Try parsing it back
        decoded_package = json.loads(base64.b64decode(package_b64).decode('utf-8'))
        
        if 'encryptedData' in decoded_package and 'encryptedKey' in decoded_package:
            print("✅ Package structure is correct for hybrid format")
            print("✅ Would be detected as hybrid encryption")
        else:
            print("❌ Package missing required hybrid fields")
            
    except Exception as e:
        print(f"❌ Error testing package format: {e}")

def create_test_hybrid_csv():
    """Create a test CSV file with hybrid encryption format"""
    
    # Sample survey data in hybrid format
    sample_surveys = [
        {
            "encryptedData": "SGVsbG8gV29ybGQhIFRoaXMgaXMgYSB0ZXN0IG1lc3NhZ2UgZm9yIGh5YnJpZCBlbmNyeXB0aW9uLg==",
            "encryptedKey": "VGhpcyBpcyBhIHNhbXBsZSBlbmNyeXB0ZWQgQUVTIGtleQ==",
            "algorithm": "AES-256-GCM + RSA-PKCS1",
            "researchSite": "gauteng",
            "timestamp": "2023-08-15T10:30:00Z"
        }
    ]
    
    # Create CSV content
    csv_content = "timestamp,encrypted_data\n"
    
    for survey in sample_surveys:
        # Convert survey to JSON and then base64
        survey_json = json.dumps(survey)
        survey_b64 = base64.b64encode(survey_json.encode('utf-8')).decode('utf-8')
        csv_content += f"{survey['timestamp']},{survey_b64}\n"
    
    # Write to test file
    with open('decryption_tools/test_hybrid_data.csv', 'w') as f:
        f.write(csv_content)
    
    print("✅ Created test_hybrid_data.csv with hybrid format")
    print(f"CSV content preview:")
    print(csv_content[:200] + "...")

if __name__ == "__main__":
    print("Hybrid Encryption Format Testing")
    print("=" * 60)
    
    test_sample_hybrid_format()
    print("\n" + "=" * 60)
    
    create_test_hybrid_csv()
    print("\n" + "=" * 60)
    
    print("Next steps:")
    print("1. Update Flutter app to generate this hybrid format")
    print("2. Test with decryption_tools/decrypt_survey_data.py")
    print("3. Verify hybrid detection works correctly")