# Data Analysis Toolkit

This directory contains all tools and documentation for downloading, decrypting, and analyzing data from the Gauteng Wellbeing Mapper study.

## 📁 Directory Structure

### `qualtrics_tools/`
Tools for downloading and working with Qualtrics survey data:
- `download_qualtrics_data.py` - Download survey responses from Qualtrics API
- `requirements-qualtrics.txt` - Python dependencies for Qualtrics tools

### `decryption_tools/`
Tools for decrypting and processing encrypted survey data:
- `automated_decryption_pipeline.py` - Main automated decryption script
- `decrypt_survey_data.py` - Core decryption functionality
- `test_hybrid_decryption.py` - Test script for decryption verification
- Sample data files and encryption keys for testing

### `structure_tools/`
Tools for analyzing and structuring processed data:
- `create_structured_tables.py` - Convert decrypted data to structured formats
- `analyze_encryption_limits.py` - Analyze encryption performance and limits
- `realistic_location_analysis.py` - Location data analysis tools
- `encryption_limits_report.md` - Report on encryption analysis results

## 📖 Documentation

- `AUTOMATED_DECRYPTION_GUIDE.md` - Complete guide for automated decryption pipeline
- `QUALTRICS_DOWNLOAD_GUIDE.md` - Guide for downloading data from Qualtrics
- `STRUCTURED_DATA_GUIDE.md` - Guide for creating structured analysis-ready data

## 🚀 Quick Start

1. **Download Qualtrics Data:**
   ```bash
   cd qualtrics_tools
   pip install -r requirements-qualtrics.txt
   python download_qualtrics_data.py
   ```

2. **Decrypt Survey Data:**
   ```bash
   cd decryption_tools
   python automated_decryption_pipeline.py
   ```

3. **Create Structured Tables:**
   ```bash
   cd structure_tools
   python create_structured_tables.py
   ```

## 📋 Requirements

- Python 3.8+
- Required packages listed in respective requirements files
- Valid Qualtrics API credentials (for download tools)
- Encryption keys (for decryption tools)

## 🔐 Security Notes

- Keep encryption keys secure and never commit them to version control
- Ensure Qualtrics API credentials are properly protected
- All decrypted data should be handled according to research data protocols

## 🆘 Support

For issues with these tools, check the individual guides in each directory or refer to the main project documentation.