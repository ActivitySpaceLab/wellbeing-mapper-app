#!/usr/bin/env python3
"""
Location Data Decryption Tool for Wellbeing Mapper Research

This tool decrypts location data from Qualtrics survey exports.
Simply place your private key file and CSV export in the same folder as this script.

Requirements:
- Python 3.6+
- cryptography library (install with: pip install cryptography)

Usage:
1. Export your survey data from Qualtrics as CSV
2. Place your private key file (RSA private key in PEM format) in the same folder
3. Run this script: python decrypt_location_data.py
4. Follow the prompts to select your files
5. The decrypted data will be saved as a new CSV file

Author: Wellbeing Mapper Development Team
"""

import csv
import json
import base64
import os
import sys
from datetime import datetime
from pathlib import Path

try:
    from cryptography.hazmat.primitives import serialization, hashes
    from cryptography.hazmat.primitives.asymmetric import rsa, padding
    from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
    from cryptography.hazmat.backends import default_backend
except ImportError:
    print("❌ Error: Required 'cryptography' library not found.")
    print("Please install it by running: pip install cryptography")
    print("Then run this script again.")
    sys.exit(1)

class LocationDecryptor:
    def __init__(self):
        self.private_key = None
        self.decrypted_locations = []
        
    def load_private_key(self, key_file_path, password=None):
        """Load RSA private key from file"""
        try:
            with open(key_file_path, 'rb') as key_file:
                if password:
                    password = password.encode('utf-8')
                
                self.private_key = serialization.load_pem_private_key(
                    key_file.read(),
                    password=password,
                    backend=default_backend()
                )
            print(f"✅ Successfully loaded private key from {key_file_path}")
            return True
        except Exception as e:
            print(f"❌ Error loading private key: {e}")
            return False
    
    def decrypt_aes_key(self, encrypted_key_b64):
        """Decrypt the AES key using RSA private key"""
        try:
            encrypted_key = base64.b64decode(encrypted_key_b64)
            aes_key = self.private_key.decrypt(
                encrypted_key,
                padding.OAEP(
                    mgf=padding.MGF1(algorithm=hashes.SHA256()),
                    algorithm=hashes.SHA256(),
                    label=None
                )
            )
            return aes_key
        except Exception as e:
            print(f"❌ Error decrypting AES key: {e}")
            return None
    
    def decrypt_location_data(self, encrypted_data_b64, aes_key):
        """Decrypt location data using AES key"""
        try:
            encrypted_data = base64.b64decode(encrypted_data_b64)
            
            # Extract IV (first 16 bytes) and encrypted content
            iv = encrypted_data[:16]
            encrypted_content = encrypted_data[16:]
            
            # Decrypt using AES
            cipher = Cipher(
                algorithms.AES(aes_key),
                modes.CBC(iv),
                backend=default_backend()
            )
            decryptor = cipher.decryptor()
            padded_data = decryptor.update(encrypted_content) + decryptor.finalize()
            
            # Remove PKCS7 padding
            padding_length = padded_data[-1]
            location_json = padded_data[:-padding_length].decode('utf-8')
            
            return json.loads(location_json)
        except Exception as e:
            print(f"❌ Error decrypting location data: {e}")
            return None
    
    def process_encrypted_location(self, encrypted_location_data):
        """Process a complete encrypted location data string"""
        try:
            # Parse the encrypted location data JSON
            encrypted_data = json.loads(encrypted_location_data)
            
            # Extract components
            encrypted_aes_key = encrypted_data.get('encryptedKey')
            encrypted_location_data = encrypted_data.get('encryptedData')
            
            if not encrypted_aes_key or not encrypted_location_data:
                print("❌ Missing encryption components in location data")
                return None
            
            # Decrypt AES key
            aes_key = self.decrypt_aes_key(encrypted_aes_key)
            if not aes_key:
                return None
            
            # Decrypt location data
            location_data = self.decrypt_location_data(encrypted_location_data, aes_key)
            return location_data
            
        except json.JSONDecodeError as e:
            print(f"❌ Error parsing encrypted location data JSON: {e}")
            return None
        except Exception as e:
            print(f"❌ Error processing encrypted location: {e}")
            return None
    
    def process_qualtrics_csv(self, csv_file_path):
        """Process Qualtrics CSV export and decrypt location data"""
        try:
            with open(csv_file_path, 'r', encoding='utf-8') as file:
                # Skip the first row (Qualtrics metadata)
                csv_reader = csv.DictReader(file)
                next(csv_reader)  # Skip first data row if it's metadata
                
                processed_count = 0
                error_count = 0
                
                for row_num, row in enumerate(csv_reader, start=3):  # Start at 3 since we skip header + metadata
                    # Look for location data column (adjust column name as needed)
                    location_column = None
                    for col_name in row.keys():
                        if 'location' in col_name.lower() or 'QID' in col_name:
                            if row[col_name] and row[col_name].strip():
                                location_column = col_name
                                break
                    
                    if not location_column:
                        continue
                    
                    encrypted_location = row[location_column].strip()
                    if not encrypted_location or encrypted_location == '':
                        continue
                    
                    print(f"Processing row {row_num}...")
                    
                    # Decrypt location data
                    location_data = self.process_encrypted_location(encrypted_location)
                    
                    if location_data:
                        # Extract participant info
                        participant_code = row.get('participantCode', row.get('ParticipantCode', 'Unknown'))
                        participant_uuid = row.get('participantUUID', row.get('ParticipantUUID', 'Unknown'))
                        survey_date = row.get('RecordedDate', row.get('recordedDate', 'Unknown'))
                        
                        # Process each location point
                        if isinstance(location_data, list):
                            for location_point in location_data:
                                self.decrypted_locations.append({
                                    'participant_code': participant_code,
                                    'participant_uuid': participant_uuid,
                                    'survey_date': survey_date,
                                    'timestamp': location_point.get('timestamp', ''),
                                    'latitude': location_point.get('latitude', ''),
                                    'longitude': location_point.get('longitude', ''),
                                    'accuracy': location_point.get('accuracy', ''),
                                    'speed': location_point.get('speed', ''),
                                    'heading': location_point.get('heading', ''),
                                    'altitude': location_point.get('altitude', ''),
                                })
                        processed_count += 1
                    else:
                        error_count += 1
                        print(f"❌ Failed to decrypt location data in row {row_num}")
                
                print(f"\n✅ Processing complete!")
                print(f"   Successfully processed: {processed_count} rows")
                print(f"   Errors: {error_count} rows")
                print(f"   Total location points extracted: {len(self.decrypted_locations)}")
                
                return True
                
        except Exception as e:
            print(f"❌ Error processing CSV file: {e}")
            return False
    
    def save_decrypted_data(self, output_file_path):
        """Save decrypted location data to new CSV file"""
        try:
            if not self.decrypted_locations:
                print("❌ No location data to save")
                return False
            
            with open(output_file_path, 'w', newline='', encoding='utf-8') as file:
                fieldnames = [
                    'participant_code',
                    'participant_uuid', 
                    'survey_date',
                    'timestamp',
                    'latitude',
                    'longitude',
                    'accuracy',
                    'speed',
                    'heading',
                    'altitude'
                ]
                
                writer = csv.DictWriter(file, fieldnames=fieldnames)
                writer.writeheader()
                writer.writerows(self.decrypted_locations)
            
            print(f"✅ Decrypted location data saved to: {output_file_path}")
            return True
            
        except Exception as e:
            print(f"❌ Error saving decrypted data: {e}")
            return False

def find_files_in_directory():
    """Find relevant files in the current directory"""
    current_dir = Path('.')
    
    # Look for private key files
    key_files = []
    for ext in ['.pem', '.key', '.txt']:
        key_files.extend(list(current_dir.glob(f'*private*{ext}')))
        key_files.extend(list(current_dir.glob(f'*key*{ext}')))
    
    # Look for CSV files
    csv_files = list(current_dir.glob('*.csv'))
    
    return key_files, csv_files

def get_user_input():
    """Get file selections from user"""
    print("🔍 Looking for files in current directory...")
    key_files, csv_files = find_files_in_directory()
    
    # Select private key file
    if not key_files:
        print("❌ No private key files found.")
        key_file_path = input("Please enter the path to your private key file: ").strip()
        if not os.path.exists(key_file_path):
            print("❌ Private key file not found.")
            return None, None
    else:
        print(f"\n📁 Found {len(key_files)} potential private key file(s):")
        for i, key_file in enumerate(key_files, 1):
            print(f"   {i}. {key_file.name}")
        
        if len(key_files) == 1:
            key_file_path = str(key_files[0])
            print(f"✅ Using: {key_file_path}")
        else:
            try:
                choice = int(input(f"\nSelect private key file (1-{len(key_files)}): "))
                key_file_path = str(key_files[choice - 1])
            except (ValueError, IndexError):
                print("❌ Invalid selection")
                return None, None
    
    # Select CSV file
    if not csv_files:
        print("❌ No CSV files found.")
        csv_file_path = input("Please enter the path to your Qualtrics CSV export: ").strip()
        if not os.path.exists(csv_file_path):
            print("❌ CSV file not found.")
            return None, None
    else:
        print(f"\n📁 Found {len(csv_files)} CSV file(s):")
        for i, csv_file in enumerate(csv_files, 1):
            print(f"   {i}. {csv_file.name}")
        
        if len(csv_files) == 1:
            csv_file_path = str(csv_files[0])
            print(f"✅ Using: {csv_file_path}")
        else:
            try:
                choice = int(input(f"\nSelect CSV file (1-{len(csv_files)}): "))
                csv_file_path = str(csv_files[choice - 1])
            except (ValueError, IndexError):
                print("❌ Invalid selection")
                return None, None
    
    return key_file_path, csv_file_path

def main():
    print("=" * 60)
    print("   🗺️  WELLBEING MAPPER LOCATION DATA DECRYPTION TOOL")
    print("=" * 60)
    print()
    print("This tool will decrypt location data from your Qualtrics survey export.")
    print("Make sure you have:")
    print("  ✓ Your RSA private key file (.pem format)")
    print("  ✓ CSV export from Qualtrics with encrypted location data")
    print()
    
    # Get file paths from user
    key_file_path, csv_file_path = get_user_input()
    
    if not key_file_path or not csv_file_path:
        print("❌ Required files not found. Exiting.")
        return
    
    # Check if private key is password protected
    password = None
    try:
        with open(key_file_path, 'r') as f:
            content = f.read()
            if 'ENCRYPTED' in content:
                password = input("\n🔒 Private key is password protected. Enter password: ")
    except:
        pass
    
    # Initialize decryptor
    decryptor = LocationDecryptor()
    
    # Load private key
    print(f"\n🔑 Loading private key...")
    if not decryptor.load_private_key(key_file_path, password):
        return
    
    # Process CSV file
    print(f"\n📊 Processing Qualtrics CSV export...")
    if not decryptor.process_qualtrics_csv(csv_file_path):
        return
    
    # Generate output filename
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_file = f"decrypted_locations_{timestamp}.csv"
    
    # Save decrypted data
    print(f"\n💾 Saving decrypted data...")
    if decryptor.save_decrypted_data(output_file):
        print(f"\n🎉 SUCCESS!")
        print(f"   Decrypted location data saved to: {output_file}")
        print(f"   Total location points: {len(decryptor.decrypted_locations)}")
        print(f"   You can now open this file in Excel or any spreadsheet program.")
    
    print("\n" + "=" * 60)
    print("Thank you for using the Wellbeing Mapper decryption tool!")
    print("=" * 60)

if __name__ == "__main__":
    main()
