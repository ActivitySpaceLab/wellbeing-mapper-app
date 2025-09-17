#!/usr/bin/env python3
"""
Automated Decryption Pipeline for Qualtrics Survey Data
======================================================

This script automatically processes downloaded Qualtrics data and decrypts all survey responses.
It integrates with the download_qualtrics_data.py script to create a complete data processing pipeline.

Features:
- Automatic detection of downloaded CSV files
- Batch decryption of all survey responses
- Structured output with separate files for different data types
- Progress tracking and error handling
- Integration with existing decryption tools

Usage:
    python3 automated_decryption_pipeline.py [options]
    
Examples:
    # Process all data in ./data directory
    python3 automated_decryption_pipeline.py --input ./data
    
    # Process specific survey file
    python3 automated_decryption_pipeline.py --file biweekly_survey_responses.csv
    
    # Full pipeline: download then decrypt
    python3 automated_decryption_pipeline.py --download-first --days 7
"""

import argparse
import json
import base64
import csv
import os
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import subprocess

# Import existing decryption functionality
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

class AutomatedDecryptionPipeline:
    """Complete pipeline for downloading and decrypting Qualtrics survey data"""
    
    def __init__(self, private_key_path: str = './private_key.pem'):
        self.private_key_path = private_key_path
        self.private_key = None
        self.results = {
            'processed_files': [],
            'decrypted_responses': 0,
            'location_points': 0,
            'errors': []
        }
        
        # Survey configurations
        self.survey_configs = {
            'initial_survey_responses.csv': {
                'type': 'initial',
                'location_column': None,  # Initial survey doesn't have location data
                'output_prefix': 'initial_decrypted'
            },
            'biweekly_survey_responses.csv': {
                'type': 'biweekly',
                'location_column': 'Q18',  # Location data column
                'output_prefix': 'biweekly_decrypted'
            },
            'consent_form_responses.csv': {
                'type': 'consent',
                'location_column': None,  # Consent form doesn't have location data
                'output_prefix': 'consent_decrypted'
            }
        }
    
    def load_private_key(self, password: Optional[str] = None) -> bool:
        """Load RSA private key for decryption"""
        try:
            if not os.path.exists(self.private_key_path):
                print(f"❌ Private key file not found: {self.private_key_path}")
                return False
                
            with open(self.private_key_path, 'rb') as key_file:
                if password:
                    password = password.encode('utf-8')
                
                self.private_key = serialization.load_pem_private_key(
                    key_file.read(),
                    password=password,
                    backend=default_backend()
                )
            
            print(f"✅ Successfully loaded private key from {self.private_key_path}")
            return True
            
        except Exception as e:
            print(f"❌ Error loading private key: {e}")
            self.results['errors'].append(f"Key loading error: {e}")
            return False
    
    def decrypt_aes_key(self, encrypted_key_b64: str) -> Optional[bytes]:
        """Decrypt AES key using RSA private key"""
        try:
            encrypted_key = base64.b64decode(encrypted_key_b64)
            
            # Try OAEP padding first (newer, more secure)
            try:
                aes_key = self.private_key.decrypt(
                    encrypted_key,
                    padding.OAEP(
                        mgf=padding.MGF1(algorithm=hashes.SHA256()),
                        algorithm=hashes.SHA256(),
                        label=None
                    )
                )
                return aes_key
            except Exception:
                # Fallback to PKCS1v15 padding (older format)
                aes_key = self.private_key.decrypt(
                    encrypted_key,
                    padding.PKCS1v15()
                )
                return aes_key
                
        except Exception as e:
            print(f"❌ Error decrypting AES key: {e}")
            return None
    
    def decrypt_location_data(self, encrypted_data_b64: str, aes_key: bytes) -> Optional[Dict]:
        """Decrypt location data using AES key"""
        try:
            encrypted_data = base64.b64decode(encrypted_data_b64)
            
            # Method 1: Try AES-CBC with IV (newer format)
            if len(encrypted_data) > 16:
                try:
                    iv = encrypted_data[:16]
                    encrypted_content = encrypted_data[16:]
                    
                    cipher = Cipher(
                        algorithms.AES(aes_key),
                        modes.CBC(iv),
                        backend=default_backend()
                    )
                    decryptor = cipher.decryptor()
                    padded_data = decryptor.update(encrypted_content) + decryptor.finalize()
                    
                    # Remove PKCS7 padding
                    padding_length = padded_data[-1]
                    unpadded_data = padded_data[:-padding_length]
                    
                    decrypted_json = unpadded_data.decode('utf-8')
                    return json.loads(decrypted_json)
                    
                except Exception:
                    pass  # Fall through to try XOR method
            
            # Method 2: XOR decryption (older format)
            decrypted_data = []
            for i in range(len(encrypted_data)):
                decrypted_data.append(encrypted_data[i] ^ aes_key[i % len(aes_key)])
            
            decrypted_json = bytes(decrypted_data).decode('utf-8')
            return json.loads(decrypted_json)
            
        except Exception as e:
            print(f"❌ Error decrypting location data: {e}")
            return None
    
    def process_csv_file(self, csv_path: str, output_dir: str = './decrypted_data') -> bool:
        """Process a single CSV file and decrypt all encrypted data"""
        
        if not os.path.exists(csv_path):
            print(f"❌ CSV file not found: {csv_path}")
            return False
        
        filename = os.path.basename(csv_path)
        survey_config = None
        
        # Find matching survey configuration
        for pattern, config in self.survey_configs.items():
            if pattern in filename or filename.endswith(pattern):
                survey_config = config
                break
        
        if not survey_config:
            print(f"⚠️ Unknown survey file type: {filename}")
            survey_config = {
                'type': 'unknown',
                'location_column': None,
                'output_prefix': 'unknown_decrypted'
            }
        
        print(f"\n📊 Processing {survey_config['type']} survey: {filename}")
        
        # Create output directory
        os.makedirs(output_dir, exist_ok=True)
        
        # Prepare output files
        output_responses = os.path.join(output_dir, f"{survey_config['output_prefix']}_responses.csv")
        output_locations = os.path.join(output_dir, f"{survey_config['output_prefix']}_locations.csv")
        
        decrypted_responses = []
        location_data_points = []
        
        try:
            with open(csv_path, 'r', encoding='utf-8') as file:
                # Handle Qualtrics CSV format (skip header rows)
                reader = csv.reader(file)
                all_rows = list(reader)
                
                # Find the actual header row (usually row 3, after metadata)
                header_row_idx = 0
                for i, row in enumerate(all_rows[:5]):
                    if any('ResponseId' in str(cell) for cell in row):
                        header_row_idx = i
                        break
                
                headers = all_rows[header_row_idx]
                data_rows = all_rows[header_row_idx + 1:]
                
                print(f"📋 Found {len(data_rows)} responses to process")
                
                # Process each response
                for row_idx, row in enumerate(data_rows):
                    if len(row) < len(headers):
                        continue  # Skip incomplete rows
                    
                    response_data = dict(zip(headers, row))
                    response_id = response_data.get('ResponseId', f'row_{row_idx}')
                    
                    # Create decrypted response record
                    decrypted_response = response_data.copy()
                    
                    # Process location data if present
                    if survey_config['location_column']:
                        location_column = survey_config['location_column']
                        encrypted_location = response_data.get(location_column, '')
                        
                        if encrypted_location and encrypted_location.startswith('{"encryptedData"'):
                            locations = self._decrypt_response_location(
                                encrypted_location, response_id
                            )
                            
                            if locations:
                                location_data_points.extend(locations)
                                # Replace encrypted data with summary
                                decrypted_response[location_column] = f"DECRYPTED: {len(locations)} location points"
                                print(f"✅ Decrypted {len(locations)} location points for {response_id}")
                            else:
                                decrypted_response[location_column] = "DECRYPTION_FAILED"
                                print(f"❌ Failed to decrypt location data for {response_id}")
                    
                    decrypted_responses.append(decrypted_response)
                
                # Save decrypted responses
                if decrypted_responses:
                    self._save_csv(output_responses, decrypted_responses, headers)
                    print(f"📁 Saved {len(decrypted_responses)} decrypted responses to: {output_responses}")
                
                # Save location data
                if location_data_points:
                    location_headers = ['response_id', 'timestamp', 'latitude', 'longitude', 
                                     'accuracy', 'altitude', 'speed', 'heading']
                    self._save_csv(output_locations, location_data_points, location_headers)
                    print(f"📍 Saved {len(location_data_points)} location points to: {output_locations}")
                
                # Update results
                self.results['processed_files'].append(filename)
                self.results['decrypted_responses'] += len(decrypted_responses)
                self.results['location_points'] += len(location_data_points)
                
                return True
                
        except Exception as e:
            print(f"❌ Error processing {filename}: {e}")
            self.results['errors'].append(f"Processing error in {filename}: {e}")
            return False
    
    def _decrypt_response_location(self, encrypted_location: str, response_id: str) -> List[Dict]:
        """Decrypt location data for a single response"""
        try:
            # Parse encrypted package
            encrypted_package = json.loads(encrypted_location)
            encrypted_data_b64 = encrypted_package['encryptedData']
            encrypted_key_b64 = encrypted_package['encryptedKey']
            
            # Decrypt AES key
            aes_key = self.decrypt_aes_key(encrypted_key_b64)
            if not aes_key:
                return []
            
            # Decrypt location data
            location_data = self.decrypt_location_data(encrypted_data_b64, aes_key)
            if not location_data:
                return []
            
            # Extract location points
            locations = []
            if 'locationData' in location_data:
                for loc in location_data['locationData']:
                    locations.append({
                        'response_id': response_id,
                        'timestamp': loc.get('timestamp', ''),
                        'latitude': loc.get('latitude', ''),
                        'longitude': loc.get('longitude', ''),
                        'accuracy': loc.get('accuracy', ''),
                        'altitude': loc.get('altitude', ''),
                        'speed': loc.get('speed', ''),
                        'heading': loc.get('heading', '')
                    })
            
            return locations
            
        except Exception as e:
            print(f"❌ Error decrypting location for {response_id}: {e}")
            return []
    
    def _save_csv(self, filepath: str, data: List[Dict], headers: List[str]) -> None:
        """Save data to CSV file"""
        with open(filepath, 'w', newline='', encoding='utf-8') as file:
            writer = csv.DictWriter(file, fieldnames=headers)
            writer.writeheader()
            for row in data:
                # Only write columns that exist in headers
                filtered_row = {k: v for k, v in row.items() if k in headers}
                writer.writerow(filtered_row)
    
    def run_download_first(self, download_args: List[str]) -> bool:
        """Run the download script first"""
        try:
            download_cmd = ['python3', 'download_qualtrics_data.py'] + download_args
            print(f"🔄 Running download command: {' '.join(download_cmd)}")
            
            result = subprocess.run(download_cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                print("✅ Download completed successfully")
                print(result.stdout)
                return True
            else:
                print(f"❌ Download failed: {result.stderr}")
                self.results['errors'].append(f"Download error: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ Error running download: {e}")
            self.results['errors'].append(f"Download execution error: {e}")
            return False
    
    def process_directory(self, input_dir: str, output_dir: str = './decrypted_data') -> bool:
        """Process all CSV files in a directory"""
        
        if not os.path.exists(input_dir):
            print(f"❌ Input directory not found: {input_dir}")
            return False
        
        # Find all CSV files
        csv_files = []
        for filename in os.listdir(input_dir):
            if filename.endswith('.csv'):
                csv_files.append(os.path.join(input_dir, filename))
        
        if not csv_files:
            print(f"❌ No CSV files found in {input_dir}")
            return False
        
        print(f"📂 Found {len(csv_files)} CSV files to process")
        
        success_count = 0
        for csv_file in csv_files:
            print(f"\\n{'='*60}")
            if self.process_csv_file(csv_file, output_dir):
                success_count += 1
        
        print(f"\\n🎉 Processed {success_count}/{len(csv_files)} files successfully")
        return success_count > 0
    
    def print_summary(self) -> None:
        """Print processing summary"""
        print(f"\\n{'='*60}")
        print("📊 DECRYPTION PIPELINE SUMMARY")
        print(f"{'='*60}")
        print(f"Files processed: {len(self.results['processed_files'])}")
        print(f"Responses decrypted: {self.results['decrypted_responses']}")
        print(f"Location points extracted: {self.results['location_points']}")
        print(f"Errors encountered: {len(self.results['errors'])}")
        
        if self.results['processed_files']:
            print(f"\\n📁 Processed files:")
            for filename in self.results['processed_files']:
                print(f"   ✅ {filename}")
        
        if self.results['errors']:
            print(f"\\n❌ Errors:")
            for error in self.results['errors']:
                print(f"   • {error}")


def main():
    parser = argparse.ArgumentParser(
        description='Automated decryption pipeline for Qualtrics survey data',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s --input ./data                    Process all CSV files in ./data
  %(prog)s --file survey_responses.csv       Process specific file
  %(prog)s --download-first --days 7         Download last 7 days then decrypt
  %(prog)s --download-first --all            Download all data then decrypt
        """
    )
    
    # Input options
    parser.add_argument('--input', default='./data',
                       help='Input directory containing CSV files (default: ./data)')
    
    parser.add_argument('--file', 
                       help='Process specific CSV file')
    
    parser.add_argument('--output', default='./decrypted_data',
                       help='Output directory for decrypted data (default: ./decrypted_data)')
    
    # Download integration
    parser.add_argument('--download-first', action='store_true',
                       help='Run download script first, then decrypt')
    
    parser.add_argument('--days', type=int,
                       help='Download data from last N days (use with --download-first)')
    
    parser.add_argument('--all', action='store_true',
                       help='Download all survey data (use with --download-first)')
    
    parser.add_argument('--survey', choices=['initial', 'biweekly', 'consent'],
                       help='Download specific survey (use with --download-first)')
    
    # Security options
    parser.add_argument('--private-key', default='./private_key.pem',
                       help='Path to RSA private key file (default: ./private_key.pem)')
    
    parser.add_argument('--password', 
                       help='Private key password (will prompt if not provided)')
    
    args = parser.parse_args()
    
    # Create pipeline
    pipeline = AutomatedDecryptionPipeline(args.private_key)
    
    # Get private key password if needed
    password = args.password
    if not password and os.path.exists(args.private_key):
        # Check if key is encrypted by trying to load without password
        try:
            with open(args.private_key, 'rb') as f:
                key_data = f.read()
                if b'ENCRYPTED' in key_data:
                    import getpass
                    password = getpass.getpass("Enter private key password: ")
        except:
            pass
    
    # Load private key
    if not pipeline.load_private_key(password):
        print("❌ Failed to load private key. Exiting.")
        return 1
    
    # Run download first if requested
    if args.download_first:
        download_args = []
        
        if args.all:
            download_args.append('--all')
        elif args.survey:
            download_args.extend(['--survey', args.survey])
        else:
            print("❌ Must specify --all or --survey when using --download-first")
            return 1
        
        if args.days:
            download_args.extend(['--days', str(args.days)])
        
        download_args.extend(['--output', args.input])
        
        if not pipeline.run_download_first(download_args):
            print("❌ Download failed. Exiting.")
            return 1
    
    # Process data
    success = False
    if args.file:
        success = pipeline.process_csv_file(args.file, args.output)
    else:
        success = pipeline.process_directory(args.input, args.output)
    
    # Print summary
    pipeline.print_summary()
    
    return 0 if success else 1


if __name__ == '__main__':
    sys.exit(main())