#!/usr/bin/env python3
"""
Quick Pipeline Test - Uses Existing Data
========================================

This script runs the data processing pipeline using your existing downloaded and decrypted data.
Perfect for testing when you already have fresh data downloaded.

Usage:
    PRIVATE_KEY_PASSWORD='your_password' python quick_pipeline_test.py
"""

import os
import sys
import subprocess
import shutil
from pathlib import Path

def main():
    print("🚀 Quick Pipeline Test - Using Existing Data")
    print("=" * 50)
    
    base_dir = Path(__file__).parent
    
    # Check if we have existing data
    test_decrypted = base_dir / "test_decrypted"
    test_structured = base_dir / "test_data" / "structured_data"
    
    if not test_decrypted.exists():
        print("❌ No test_decrypted directory found. Please run download and decrypt first.")
        return 1
    
    # Clean structured data directory
    if test_structured.exists():
        shutil.rmtree(test_structured)
    test_structured.mkdir(parents=True)
    
    print("📊 Running CSV creation with image extraction...")
    
    # Run CSV creation
    cmd = [
        sys.executable,
        str(base_dir / "create_survey_csvs.py"),
        "--input", str(test_decrypted),
        "--output", str(test_structured),
        "--download-images",
        "--report",
        "--validate"
    ]
    
    result = subprocess.run(cmd, cwd=str(base_dir))
    
    if result.returncode == 0:
        print("\n🎉 Pipeline test completed successfully!")
        print(f"📍 Results saved to: {test_structured}")
        
        # Count results
        csv_files = list(test_structured.glob("*.csv"))
        image_files = list(test_structured.glob("images/*.jpg"))
        
        print(f"📄 CSV files created: {len(csv_files)}")
        print(f"📷 Images extracted: {len(image_files)}")
        
        return 0
    else:
        print("❌ Pipeline test failed!")
        return 1

if __name__ == "__main__":
    sys.exit(main())