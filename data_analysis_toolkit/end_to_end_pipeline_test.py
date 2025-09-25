#!/usr/bin/env python3
"""
End-to-End Data Pipeline Test Script
===================================

This script runs the complete data analysis pipeline for the Gauteng Wellbeing Mapper project:
1. Download survey data from Qualtrics
2. Decrypt the downloaded data
3. Create structured analysis-ready tables

The script provides comprehensive testing and validation at each step, making it easy to verify
that the entire data processing pipeline is working correctly.

Features:
- Automatic cleanup and fresh start for testing
- Progress tracking and detailed logging
- Validation at each pipeline step
- Configurable data ranges for testing
- Summary report generation

Usage:
    python3 end_to_end_pipeline_test.py [options]
    
Examples:
    # Run full pipeline test (last 7 days of data)
    python3 end_to_end_pipeline_test.py
    
    # Test with last 30 days of data
    python3 end_to_end_pipeline_test.py --days 30
    
    # Test with all available data
    python3 end_to_end_pipeline_test.py --all-data
    
    # Clean run (remove all previous data first)
    python3 end_to_end_pipeline_test.py --clean
    
    # Generate detailed report
    python3 end_to_end_pipeline_test.py --report

Environment Variables Required:
    QUALTRICS_API_TOKEN     Your Qualtrics API token
    PRIVATE_KEY_PASSWORD    Password for the encrypted private key (optional, will prompt if not set)

Output:
    - Raw Qualtrics data in ./qualtrics_data/
    - Decrypted data in ./decrypted_data/ 
    - Structured tables in ./structured_data/
    - Test report in ./pipeline_test_report.txt
"""

import argparse
import os
import sys
import subprocess
import shutil
import json
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import time

class PipelineTestRunner:
    """Orchestrates and tests the complete data analysis pipeline"""
    
    def __init__(self, base_dir: str = None):
        """Initialize the pipeline test runner"""
        self.base_dir = Path(base_dir) if base_dir else Path(__file__).parent
        self.qualtrics_dir = self.base_dir / "qualtrics_tools"
        self.decryption_dir = self.base_dir / "decryption_tools" 
        self.structure_dir = self.base_dir / "structure_tools"
        
        # Output directories
        self.output_dirs = {
            'qualtrics_data': self.base_dir / "test_data" / "qualtrics_data",
            'decrypted_data': self.base_dir / "test_data" / "decrypted_data",
            'structured_data': self.base_dir / "test_data" / "structured_data"
        }
        
        # Test results
        self.test_results = {
            'start_time': None,
            'end_time': None,
            'steps': {
                'download': {'status': 'pending', 'start_time': None, 'end_time': None, 'details': {}},
                'decrypt': {'status': 'pending', 'start_time': None, 'end_time': None, 'details': {}},
                'structure': {'status': 'pending', 'start_time': None, 'end_time': None, 'details': {}}
            },
            'summary': {}
        }
    
    def setup_test_environment(self, clean: bool = False):
        """Set up the testing environment"""
        print("🔧 Setting up test environment...")
        
        if clean:
            print("   Cleaning previous test data...")
            if (self.base_dir / "test_data").exists():
                shutil.rmtree(self.base_dir / "test_data")
        
        # Create output directories
        for dir_name, dir_path in self.output_dirs.items():
            dir_path.mkdir(parents=True, exist_ok=True)
            print(f"   Created directory: {dir_path}")
    
    def validate_environment(self):
        """Validate that all required components are available"""
        print("✅ Validating environment...")
        
        # Check API token
        api_token = os.environ.get('QUALTRICS_API_TOKEN', '')
        if not api_token:
            raise ValueError("QUALTRICS_API_TOKEN environment variable not set")
        print(f"   API token: {'*' * (len(api_token) - 4) + api_token[-4:]}")
        
        # Check required scripts
        required_scripts = [
            self.qualtrics_dir / "download_qualtrics_data.py",
            self.decryption_dir / "automated_decryption_pipeline.py", 
            self.structure_dir / "create_structured_tables.py"
        ]
        
        for script in required_scripts:
            if not script.exists():
                raise FileNotFoundError(f"Required script not found: {script}")
            print(f"   Found script: {script.name}")
    
    def run_download_step(self, days: Optional[int] = None, all_data: bool = False):
        """Run the Qualtrics data download step"""
        print("\n📥 Step 1: Downloading Qualtrics data...")
        step_info = self.test_results['steps']['download']
        step_info['start_time'] = datetime.now()
        
        try:
            # Build command
            cmd = [
                sys.executable,
                str(self.qualtrics_dir / "download_qualtrics_data.py"),
                "--output", str(self.output_dirs['qualtrics_data'])
            ]
            
            if all_data:
                cmd.append("--all")
            elif days:
                cmd.extend(["--days", str(days)])
            else:
                cmd.extend(["--days", "7"])  # Default to 7 days
            
            print(f"   Running: {' '.join(cmd)}")
            
            # Run the download
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=str(self.qualtrics_dir))
            
            step_info['end_time'] = datetime.now()
            
            if result.returncode == 0:
                step_info['status'] = 'success'
                print("   ✅ Download completed successfully")
                
                # Count downloaded files
                downloaded_files = list(self.output_dirs['qualtrics_data'].glob("*.csv"))
                step_info['details']['files_downloaded'] = len(downloaded_files)
                step_info['details']['file_list'] = [f.name for f in downloaded_files]
                
                print(f"   📄 Downloaded {len(downloaded_files)} files:")
                for file in downloaded_files:
                    print(f"      - {file.name}")
                    
            else:
                step_info['status'] = 'failed'
                step_info['details']['error'] = result.stderr
                print(f"   ❌ Download failed: {result.stderr}")
                return False
                
        except Exception as e:
            step_info['status'] = 'failed'
            step_info['details']['error'] = str(e)
            step_info['end_time'] = datetime.now()
            print(f"   ❌ Download failed with exception: {e}")
            return False
            
        return True
    
    def run_decryption_step(self):
        """Run the data decryption step"""
        print("\n🔐 Step 2: Decrypting survey data...")
        step_info = self.test_results['steps']['decrypt']
        step_info['start_time'] = datetime.now()
        
        try:
            # Build command
            cmd = [
                sys.executable,
                str(self.decryption_dir / "automated_decryption_pipeline.py"),
                "--input", str(self.output_dirs['qualtrics_data']),
                "--output", str(self.output_dirs['decrypted_data'])
            ]
            
            # Add password if provided via environment variable
            private_key_password = os.environ.get('PRIVATE_KEY_PASSWORD', '')
            if private_key_password:
                cmd.extend(["--password", private_key_password])
                print(f"   Running: {' '.join(cmd[:-1])} --password [HIDDEN]")
            else:
                print(f"   Running: {' '.join(cmd)}")
                print("   Note: If prompted for password, set PRIVATE_KEY_PASSWORD environment variable")
            
            # Run the decryption
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=str(self.decryption_dir))
            
            step_info['end_time'] = datetime.now()
            
            if result.returncode == 0:
                step_info['status'] = 'success'
                print("   ✅ Decryption completed successfully")
                
                # Count decrypted files
                decrypted_files = list(self.output_dirs['decrypted_data'].glob("*.csv"))
                step_info['details']['files_decrypted'] = len(decrypted_files)
                step_info['details']['file_list'] = [f.name for f in decrypted_files]
                
                print(f"   📄 Decrypted {len(decrypted_files)} files:")
                for file in decrypted_files:
                    print(f"      - {file.name}")
                    
            else:
                step_info['status'] = 'failed'
                step_info['details']['error'] = result.stderr
                print(f"   ❌ Decryption failed: {result.stderr}")
                return False
                
        except Exception as e:
            step_info['status'] = 'failed'
            step_info['details']['error'] = str(e)
            step_info['end_time'] = datetime.now()
            print(f"   ❌ Decryption failed with exception: {e}")
            return False
            
        return True
    
    def run_structure_step(self):
        """Run the data structuring step"""
        print("\n📊 Step 3: Creating survey CSV files...")
        step_info = self.test_results['steps']['structure']
        step_info['start_time'] = datetime.now()
        
        try:
            # Build command
            cmd = [
                sys.executable,
                str(self.base_dir / "create_survey_csvs.py"),
                "--input", str(self.output_dirs['decrypted_data']),
                "--output", str(self.output_dirs['structured_data']),
                "--report", "--validate"
            ]
            
            print(f"   Running: {' '.join(cmd)}")
            
            # Run the CSV creation
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=str(self.base_dir))
            
            step_info['end_time'] = datetime.now()
            
            if result.returncode == 0:
                step_info['status'] = 'success'
                print("   ✅ CSV creation completed successfully")
                
                # Count CSV files
                csv_files = list(self.output_dirs['structured_data'].glob("*.csv"))
                json_files = list(self.output_dirs['structured_data'].glob("*.json"))
                step_info['details']['csv_files'] = len(csv_files)
                step_info['details']['json_files'] = len(json_files)
                step_info['details']['file_list'] = [f.name for f in csv_files + json_files]
                
                print(f"   📄 Created {len(csv_files)} CSV files:")
                for file in csv_files:
                    print(f"      - {file.name}")
                    
            else:
                step_info['status'] = 'failed'
                step_info['details']['error'] = result.stderr
                print(f"   ❌ CSV creation failed: {result.stderr}")
                return False
                
        except Exception as e:
            step_info['status'] = 'failed' 
            step_info['details']['error'] = str(e)
            step_info['end_time'] = datetime.now()
            print(f"   ❌ Structuring failed with exception: {e}")
            return False
            
        return True
    
    def generate_summary_report(self):
        """Generate a summary report of the test run"""
        print("\n📋 Generating summary report...")
        
        # Calculate total runtime
        total_runtime = self.test_results['end_time'] - self.test_results['start_time']
        
        # Build summary
        summary = {
            'total_runtime_seconds': total_runtime.total_seconds(),
            'total_runtime_formatted': str(total_runtime),
            'overall_success': all(step['status'] == 'success' for step in self.test_results['steps'].values()),
            'steps_completed': sum(1 for step in self.test_results['steps'].values() if step['status'] == 'success'),
            'total_steps': len(self.test_results['steps'])
        }
        
        self.test_results['summary'] = summary
        
        # Print summary
        print(f"\n🎯 Pipeline Test Summary")
        print(f"   Overall Status: {'✅ SUCCESS' if summary['overall_success'] else '❌ FAILED'}")
        print(f"   Total Runtime: {summary['total_runtime_formatted']}")
        print(f"   Steps Completed: {summary['steps_completed']}/{summary['total_steps']}")
        
        for step_name, step_info in self.test_results['steps'].items():
            status_icon = '✅' if step_info['status'] == 'success' else '❌' if step_info['status'] == 'failed' else '⏸️'
            print(f"   {step_name.capitalize()}: {status_icon} {step_info['status']}")
            
            if step_info['status'] == 'success' and 'files_downloaded' in step_info['details']:
                print(f"      Files: {step_info['details']['files_downloaded']} downloaded")
            elif step_info['status'] == 'success' and 'files_decrypted' in step_info['details']:
                print(f"      Files: {step_info['details']['files_decrypted']} decrypted")
            elif step_info['status'] == 'success' and 'csv_files' in step_info['details']:
                print(f"      Files: {step_info['details']['csv_files']} CSV files created")
        
        return summary
    
    def save_detailed_report(self):
        """Save a detailed JSON report"""
        report_file = self.base_dir / "pipeline_test_report.json"
        with open(report_file, 'w') as f:
            json.dump(self.test_results, f, indent=2, default=str)
        print(f"   📄 Detailed report saved to: {report_file}")
    
    def run_full_pipeline(self, days: Optional[int] = None, all_data: bool = False, clean: bool = False):
        """Run the complete pipeline test"""
        print("🚀 Starting End-to-End Pipeline Test")
        print("=" * 50)
        
        self.test_results['start_time'] = datetime.now()
        
        try:
            # Setup
            self.setup_test_environment(clean=clean)
            self.validate_environment()
            
            # Run pipeline steps
            if not self.run_download_step(days=days, all_data=all_data):
                return False
                
            if not self.run_decryption_step():
                return False
                
            if not self.run_structure_step():
                return False
            
            return True
            
        finally:
            self.test_results['end_time'] = datetime.now()
            summary = self.generate_summary_report()
            self.save_detailed_report()
            
            return summary['overall_success']

def main():
    parser = argparse.ArgumentParser(
        description='End-to-end testing of the Gauteng Wellbeing Mapper data pipeline',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s                          Run test with last 7 days of data
  %(prog)s --days 30                Test with last 30 days 
  %(prog)s --all-data               Test with all available data
  %(prog)s --clean                  Clean previous data before testing
  %(prog)s --clean --days 30        Clean run with 30 days of data

Environment Variables Required:
  QUALTRICS_API_TOKEN              Your Qualtrics API token
  PRIVATE_KEY_PASSWORD             Password for encrypted private key (optional)
        """
    )
    
    # Data selection
    parser.add_argument('--days', type=int, default=7,
                       help='Number of days of data to download for testing (default: 7)')
    
    parser.add_argument('--all-data', action='store_true',
                       help='Download all available data instead of limited date range')
    
    # Test options
    parser.add_argument('--clean', action='store_true',
                       help='Remove all previous test data before starting')
    
    parser.add_argument('--base-dir', 
                       help='Base directory for the data analysis toolkit (default: script directory)')
    
    args = parser.parse_args()
    
    # Validate environment
    if not os.environ.get('QUALTRICS_API_TOKEN'):
        print("❌ Error: QUALTRICS_API_TOKEN environment variable not set")
        print("Please export your Qualtrics API token:")
        print("  export QUALTRICS_API_TOKEN='your_token_here'")
        sys.exit(1)
    
    # Run the test
    try:
        runner = PipelineTestRunner(base_dir=args.base_dir)
        success = runner.run_full_pipeline(
            days=args.days if not args.all_data else None,
            all_data=args.all_data,
            clean=args.clean
        )
        
        if success:
            print("\n🎉 Pipeline test completed successfully!")
            sys.exit(0)
        else:
            print("\n💥 Pipeline test failed!")
            sys.exit(1)
            
    except KeyboardInterrupt:
        print("\n⚠️ Test interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n💥 Test failed with error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()