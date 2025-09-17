#!/usr/bin/env python3
"""
Qualtrics Data Download Script
==============================

This script automatically downloads survey response data from Qualtrics using their API.
It supports all three surveys used in the Gauteng Wellbeing Mapper project:
- Initial Demographics Survey
- Biweekly Wellbeing Survey  
- Consent Form Survey

Features:
- Bulk data export for analysis
- Automated CSV download and processing
- Configurable date ranges
- Progress tracking and retry logic
- Structured output files

Usage:
    python download_qualtrics_data.py [options]
    
Examples:
    # Download all data
    python download_qualtrics_data.py --all
    
    # Download specific survey data
    python download_qualtrics_data.py --survey initial
    
    # Download data from last 30 days
    python download_qualtrics_data.py --days 30
    
    # Download to custom directory
    python download_qualtrics_data.py --output /path/to/data/
"""

import argparse
import json
import os
import time
import zipfile
from datetime import datetime, timedelta
from typing import Dict, List, Optional
import requests
import pandas as pd
from pathlib import Path

class QualtricsDataDownloader:
    """Download survey response data from Qualtrics API"""
    
    def __init__(self, api_token: str, base_url: str = "https://pretoria.eu.qualtrics.com/API/v3"):
        self.api_token = api_token
        self.base_url = base_url
        self.session = requests.Session()
        self.session.headers.update({
            'X-API-TOKEN': api_token,
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        })
        
        # Survey IDs from the app configuration
        self.surveys = {
            'initial': {
                'id': 'SV_8pudN8qTI6iQKY6',
                'name': 'Initial Demographics Survey',
                'filename': 'initial_survey_responses.csv'
            },
            'biweekly': {
                'id': 'SV_aXmfOtAIRmIVdfU', 
                'name': 'Biweekly Wellbeing Survey',
                'filename': 'biweekly_survey_responses.csv'
            },
            'consent': {
                'id': 'SV_eWjaIVtwRLEMNGS',
                'name': 'Consent Form Survey', 
                'filename': 'consent_form_responses.csv'
            }
        }
    
    def download_survey_responses(self, survey_key: str, output_dir: str = './data', 
                                start_date: Optional[datetime] = None, 
                                end_date: Optional[datetime] = None) -> bool:
        """Download responses for a specific survey"""
        
        if survey_key not in self.surveys:
            print(f"❌ Unknown survey key: {survey_key}")
            print(f"Available surveys: {list(self.surveys.keys())}")
            return False
            
        survey = self.surveys[survey_key]
        survey_id = survey['id']
        survey_name = survey['name']
        
        print(f"\n📊 Downloading {survey_name} data...")
        print(f"Survey ID: {survey_id}")
        
        try:
            # Step 1: Create export request
            export_id = self._create_export_request(survey_id, start_date, end_date)
            if not export_id:
                return False
                
            # Step 2: Wait for export to complete
            download_url = self._wait_for_export_completion(survey_id, export_id)
            if not download_url:
                return False
                
            # Step 3: Download the file
            output_path = os.path.join(output_dir, survey['filename'])
            success = self._download_export_file(download_url, output_path)
            
            if success:
                print(f"✅ {survey_name} data downloaded to: {output_path}")
                # Show basic stats
                self._show_data_stats(output_path)
                return True
            else:
                return False
                
        except Exception as e:
            print(f"❌ Error downloading {survey_name}: {e}")
            return False
    
    def _create_export_request(self, survey_id: str, start_date: Optional[datetime], 
                              end_date: Optional[datetime]) -> Optional[str]:
        """Create a data export request in Qualtrics"""
        
        # Build request payload
        payload = {
            'format': 'csv',
            'compress': False,
            'useLabels': True,
            'seenUnansweredRecode': -999,
            'multiselectSeenUnansweredRecode': -999,
            'includeDisplayOrder': True
        }
        
        # Add date filters if specified
        if start_date or end_date:
            payload['dateRange'] = {}
            if start_date:
                payload['dateRange']['startDate'] = start_date.isoformat() + 'Z'
            if end_date:
                payload['dateRange']['endDate'] = end_date.isoformat() + 'Z'
        
        try:
            response = self.session.post(
                f"{self.base_url}/surveys/{survey_id}/export-responses",
                json=payload
            )
            
            if response.status_code == 200:
                result = response.json()
                export_id = result['result']['progressId'] 
                print(f"🔄 Export request created: {export_id}")
                return export_id
            else:
                print(f"❌ Failed to create export request: {response.status_code}")
                print(f"Response: {response.text}")
                return None
                
        except Exception as e:
            print(f"❌ Error creating export request: {e}")
            return None
    
    def _wait_for_export_completion(self, survey_id: str, export_id: str, 
                                   max_wait_time: int = 300) -> Optional[str]:
        """Wait for export to complete and return download URL"""
        
        print("⏳ Waiting for export to complete...")
        start_time = time.time()
        
        while time.time() - start_time < max_wait_time:
            try:
                response = self.session.get(
                    f"{self.base_url}/surveys/{survey_id}/export-responses/{export_id}"
                )
                
                if response.status_code == 200:
                    result = response.json()
                    status = result['result']['status']
                    
                    if status == 'complete':
                        download_url = result['result']['fileId']
                        print(f"✅ Export completed! File ID: {download_url}")
                        return download_url
                    elif status == 'failed':
                        print(f"❌ Export failed: {result.get('result', {}).get('error', 'Unknown error')}")
                        return None
                    else:
                        print(f"🔄 Export status: {status}")
                        
                else:
                    print(f"❌ Error checking export status: {response.status_code}")
                    return None
                    
            except Exception as e:
                print(f"❌ Error checking export status: {e}")
                return None
            
            time.sleep(5)  # Wait 5 seconds before checking again
        
        print(f"⏰ Export timeout after {max_wait_time} seconds")
        return None
    
    def _download_export_file(self, file_id: str, output_path: str) -> bool:
        """Download the exported file"""
        
        # Create output directory if it doesn't exist
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        
        try:
            response = self.session.get(
                f"{self.base_url}/surveys/export-responses/{file_id}/file",
                stream=True
            )
            
            if response.status_code == 200:
                # Check if it's a zip file
                content_type = response.headers.get('content-type', '')
                if 'zip' in content_type:
                    # Handle zip file
                    zip_path = output_path.replace('.csv', '.zip')
                    with open(zip_path, 'wb') as f:
                        for chunk in response.iter_content(chunk_size=8192):
                            f.write(chunk)
                    
                    # Extract CSV from zip
                    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
                        csv_files = [f for f in zip_ref.namelist() if f.endswith('.csv')]
                        if csv_files:
                            zip_ref.extract(csv_files[0], os.path.dirname(output_path))
                            # Rename to expected filename
                            extracted_path = os.path.join(os.path.dirname(output_path), csv_files[0])
                            os.rename(extracted_path, output_path)
                            os.remove(zip_path)  # Clean up zip file
                        else:
                            print("❌ No CSV file found in zip archive")
                            return False
                else:
                    # Direct CSV file
                    with open(output_path, 'wb') as f:
                        for chunk in response.iter_content(chunk_size=8192):
                            f.write(chunk)
                
                print(f"📁 File downloaded: {output_path}")
                return True
            else:
                print(f"❌ Failed to download file: {response.status_code}")
                print(f"Response: {response.text}")
                return False
                
        except Exception as e:
            print(f"❌ Error downloading file: {e}")
            return False
    
    def _show_data_stats(self, csv_path: str) -> None:
        """Show basic statistics about the downloaded data"""
        try:
            df = pd.read_csv(csv_path)
            
            # Skip Qualtrics header rows if present
            if df.iloc[0].astype(str).str.contains('ImportId').any():
                df = df.iloc[2:]  # Skip first 2 rows (headers)
                df.reset_index(drop=True, inplace=True)
            
            print(f"📈 Data Statistics:")
            print(f"   Total responses: {len(df)}")
            print(f"   Columns: {len(df.columns)}")
            
            # Show date range if RecordedDate column exists
            date_columns = [col for col in df.columns if 'recorded' in col.lower() or 'date' in col.lower()]
            if date_columns:
                date_col = date_columns[0]
                df[date_col] = pd.to_datetime(df[date_col], errors='coerce')
                valid_dates = df[date_col].dropna()
                if len(valid_dates) > 0:
                    print(f"   Date range: {valid_dates.min()} to {valid_dates.max()}")
            
        except Exception as e:
            print(f"❌ Error reading downloaded file for stats: {e}")
    
    def download_all_surveys(self, output_dir: str = './data', 
                           start_date: Optional[datetime] = None,
                           end_date: Optional[datetime] = None) -> Dict[str, bool]:
        """Download all survey data"""
        
        print(f"\n🚀 Starting bulk download of all survey data...")
        print(f"Output directory: {output_dir}")
        if start_date:
            print(f"Start date: {start_date}")
        if end_date:
            print(f"End date: {end_date}")
        
        results = {}
        
        for survey_key in self.surveys:
            success = self.download_survey_responses(
                survey_key, output_dir, start_date, end_date
            )
            results[survey_key] = success
            
            # Add delay between downloads to be nice to API
            if survey_key != list(self.surveys.keys())[-1]:  # Not the last one
                print("⏳ Waiting 10 seconds before next download...")
                time.sleep(10)
        
        print(f"\n📊 Download Summary:")
        for survey_key, success in results.items():
            survey_name = self.surveys[survey_key]['name']
            status = "✅ Success" if success else "❌ Failed"
            print(f"   {survey_name}: {status}")
        
        return results
    
    def list_surveys(self) -> None:
        """List available surveys"""
        print("\n📋 Available Surveys:")
        for key, survey in self.surveys.items():
            print(f"   {key}: {survey['name']} (ID: {survey['id']})")


def main():
    parser = argparse.ArgumentParser(
        description='Download survey response data from Qualtrics',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s --all                    Download all survey data
  %(prog)s --survey initial         Download initial survey data only
  %(prog)s --survey biweekly        Download biweekly survey data only
  %(prog)s --days 30                Download data from last 30 days
  %(prog)s --start 2024-01-01       Download data from specific start date
  %(prog)s --end 2024-12-31         Download data up to specific end date
  %(prog)s --output ./my_data/      Save to custom directory

Environment Variables:
  QUALTRICS_API_TOKEN              Your Qualtrics API token
  QUALTRICS_BASE_URL               Qualtrics API base URL (optional)
        """
    )
    
    # API configuration
    parser.add_argument('--api-token', 
                       default=os.environ.get('QUALTRICS_API_TOKEN', ''),
                       help='Qualtrics API token (default: from QUALTRICS_API_TOKEN env var)')
    
    parser.add_argument('--base-url',
                       default=os.environ.get('QUALTRICS_BASE_URL', 'https://pretoria.eu.qualtrics.com/API/v3'),
                       help='Qualtrics API base URL (default: from QUALTRICS_BASE_URL env var)')
    
    # Survey selection
    parser.add_argument('--all', action='store_true',
                       help='Download all survey data')
    
    parser.add_argument('--survey', choices=['initial', 'biweekly', 'consent'],
                       help='Download specific survey data')
    
    parser.add_argument('--list', action='store_true',
                       help='List available surveys and exit')
    
    # Date filtering
    parser.add_argument('--days', type=int,
                       help='Download data from last N days')
    
    parser.add_argument('--start', type=str,
                       help='Start date (YYYY-MM-DD)')
    
    parser.add_argument('--end', type=str,
                       help='End date (YYYY-MM-DD)')
    
    # Output configuration
    parser.add_argument('--output', default='./data',
                       help='Output directory (default: ./data)')
    
    args = parser.parse_args()
    
    # Check for API token
    if not args.api_token:
        print("❌ Error: No Qualtrics API token provided")
        print("Set the QUALTRICS_API_TOKEN environment variable or use --api-token")
        print("\nTo get your API token:")
        print("1. Log into Qualtrics")
        print("2. Go to Account Settings > Qualtrics IDs")
        print("3. Generate a new API token")
        print("4. Export QUALTRICS_API_TOKEN='your_token_here'")
        return
    
    # Create downloader
    downloader = QualtricsDataDownloader(args.api_token, args.base_url)
    
    # Handle list command
    if args.list:
        downloader.list_surveys()
        return
    
    # Validate arguments
    if not args.all and not args.survey:
        print("❌ Error: Must specify either --all or --survey")
        parser.print_help()
        return
    
    # Parse date arguments
    start_date = None
    end_date = None
    
    if args.days:
        end_date = datetime.now()
        start_date = end_date - timedelta(days=args.days)
    
    if args.start:
        try:
            start_date = datetime.fromisoformat(args.start)
        except ValueError:
            print(f"❌ Invalid start date format: {args.start} (use YYYY-MM-DD)")
            return
    
    if args.end:
        try:
            end_date = datetime.fromisoformat(args.end)
        except ValueError:
            print(f"❌ Invalid end date format: {args.end} (use YYYY-MM-DD)")
            return
    
    # Execute download
    if args.all:
        results = downloader.download_all_surveys(args.output, start_date, end_date)
        success_count = sum(1 for success in results.values() if success)
        total_count = len(results)
        print(f"\n🎉 Bulk download completed: {success_count}/{total_count} surveys successful")
    else:
        success = downloader.download_survey_responses(args.survey, args.output, start_date, end_date)
        if success:
            print(f"\n🎉 Download completed successfully!")
        else:
            print(f"\n❌ Download failed!")


if __name__ == '__main__':
    # Check dependencies
    try:
        import pandas as pd
        import requests
    except ImportError as e:
        print(f"❌ Missing required dependency: {e}")
        print("Install with: pip install pandas requests")
        exit(1)
    
    main()