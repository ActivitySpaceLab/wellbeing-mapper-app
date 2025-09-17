# Automated Decryption Pipeline Guide

This guide explains how to use the `automated_decryption_pipeline.py` script to automatically process downloaded Qualtrics data and decrypt all survey responses.

## Overview

The automated decryption pipeline provides a complete solution for processing encrypted survey data from the Gauteng Wellbeing Mapper project. It can:

- **Automatically decrypt all survey responses** from downloaded CSV files
- **Extract and organize location data** from biweekly surveys  
- **Integrate with the download script** for a complete end-to-end workflow
- **Process multiple files in batch** for efficient data processing
- **Generate structured output** with separate files for different data types

## Prerequisites

1. **Python 3.7+** with required packages:
   ```bash
   pip install cryptography pandas requests
   ```

2. **RSA Private Key** for decryption (usually `private_key.pem`)

3. **Downloaded survey data** (CSV files from Qualtrics)

## Key Features

### Survey Type Detection
The pipeline automatically detects and processes three survey types:
- **Initial Demographics Survey** (`initial_survey_responses.csv`)
- **Biweekly Wellbeing Survey** (`biweekly_survey_responses.csv`) - includes encrypted location data
- **Consent Form Survey** (`consent_form_responses.csv`)

### Output Files
For each processed survey, the pipeline generates:
- **`*_decrypted_responses.csv`** - All survey responses with readable data
- **`*_decrypted_locations.csv`** - Extracted location points (biweekly surveys only)

## Usage Examples

### Basic Processing

```bash
# Process all CSV files in ./data directory
python3 automated_decryption_pipeline.py --input ./data

# Process a specific file
python3 automated_decryption_pipeline.py --file biweekly_survey_responses.csv

# Save to custom output directory
python3 automated_decryption_pipeline.py --input ./data --output ./my_decrypted_data
```

### Integrated Download + Decrypt Workflow

```bash
# Download all data and decrypt immediately
python3 automated_decryption_pipeline.py --download-first --all

# Download last 30 days and decrypt
python3 automated_decryption_pipeline.py --download-first --days 30

# Download specific survey and decrypt
python3 automated_decryption_pipeline.py --download-first --survey biweekly
```

### Advanced Options

```bash
# Use custom private key location
python3 automated_decryption_pipeline.py --private-key /path/to/my_key.pem --input ./data

# Provide password on command line (not recommended for production)
python3 automated_decryption_pipeline.py --password mypassword --input ./data

# Full workflow with custom paths
python3 automated_decryption_pipeline.py \
  --download-first --all \
  --private-key ./keys/private_key.pem \
  --input ./raw_data \
  --output ./processed_data
```

## Decryption Process

### 1. Survey Response Processing
- Reads CSV files exported from Qualtrics
- Handles Qualtrics header rows and metadata
- Processes each survey response individually
- Maintains all original survey data while decrypting encrypted fields

### 2. Location Data Decryption
For biweekly surveys containing encrypted location data:
- **Detects encrypted location packages** in survey responses
- **Decrypts AES keys** using RSA private key (supports both OAEP and PKCS1v15 padding)
- **Decrypts location data** using recovered AES keys (supports both AES-CBC and XOR methods)
- **Extracts individual location points** with coordinates, timestamps, and metadata
- **Organizes location data** into structured CSV format

### 3. Output Generation
- **Decrypted responses**: Original survey data with encrypted fields replaced by readable summaries
- **Location data**: Separate file with one row per location point, including:
  - Response ID (links back to survey response)
  - Timestamp
  - Latitude/Longitude coordinates
  - Accuracy, altitude, speed, heading (when available)

## File Structure

### Input Files (from Qualtrics export)
```
data/
├── initial_survey_responses.csv      # Demographics data
├── biweekly_survey_responses.csv     # Wellbeing + encrypted location data
└── consent_form_responses.csv        # Consent responses
```

### Output Files (after decryption)
```
decrypted_data/
├── initial_decrypted_responses.csv   # Decrypted demographics
├── biweekly_decrypted_responses.csv  # Decrypted wellbeing data
├── biweekly_decrypted_locations.csv  # Extracted location points
└── consent_decrypted_responses.csv   # Decrypted consent data
```

## Integration with Research Workflow

### Complete Data Processing Pipeline
```bash
# 1. Download latest survey data
export QUALTRICS_API_TOKEN='your_token_here'
python3 download_qualtrics_data.py --all --output ./raw_data

# 2. Decrypt all survey responses
python3 automated_decryption_pipeline.py --input ./raw_data --output ./processed_data

# 3. Analysis-ready data is now available in ./processed_data
```

### Automated Daily Processing
Create a script for regular data processing:
```bash
#!/bin/bash
# daily_data_processing.sh

DATE=$(date +%Y-%m-%d)
export QUALTRICS_API_TOKEN='your_token_here'

# Create dated directories
mkdir -p "./data/$DATE/raw"
mkdir -p "./data/$DATE/processed" 

# Download and decrypt latest data
python3 automated_decryption_pipeline.py \
  --download-first --days 1 \
  --input "./data/$DATE/raw" \
  --output "./data/$DATE/processed"

echo "✅ Data processing completed for $DATE"
```

## Error Handling and Troubleshooting

### Common Issues

**Private Key Errors**
- Ensure private key file exists and is readable
- Check if key is password-protected and provide password
- Verify key format is correct PEM format

**Decryption Failures**
- Check that encrypted data format matches expected structure
- Verify AES key decryption is successful
- Some responses may have corrupted encryption data (logged as errors)

**File Processing Issues**
- Ensure CSV files are valid Qualtrics exports
- Check file permissions for input and output directories
- Verify sufficient disk space for output files

### Debug Information

The pipeline provides comprehensive progress tracking:
- **File processing status** for each CSV file
- **Decryption success/failure** for individual responses
- **Summary statistics** showing total responses and location points processed
- **Detailed error reporting** for troubleshooting

### Sample Output
```
📊 Processing biweekly survey: biweekly_survey_responses.csv
📋 Found 150 responses to process
✅ Decrypted 25 location points for P4H001
✅ Decrypted 18 location points for P4H002
❌ Failed to decrypt location data for P4H003
📁 Saved 150 decrypted responses to: ./decrypted_data/biweekly_decrypted_responses.csv
📍 Saved 1,245 location points to: ./decrypted_data/biweekly_decrypted_locations.csv

📊 DECRYPTION PIPELINE SUMMARY
============================================================
Files processed: 3
Responses decrypted: 450
Location points extracted: 1,245
Errors encountered: 2
```

## Security Considerations

- **Private key protection**: Store private key securely and use strong passwords
- **Data handling**: Process data in secure environments according to research protocols
- **Output security**: Ensure decrypted data is stored securely and access-controlled
- **Key rotation**: Follow institutional policies for cryptographic key management

## Performance Notes

- **Batch processing**: The pipeline efficiently processes large numbers of responses
- **Memory usage**: Large location datasets may require substantial memory
- **Processing time**: Decryption time scales with the number of responses and location points
- **Parallel processing**: Currently single-threaded but could be enhanced for parallel processing

## Support and Maintenance

For issues with the automated decryption pipeline:
1. **Check error messages** in the pipeline output for specific issues
2. **Verify prerequisites** (Python packages, private key, file permissions)
3. **Test with small data sets** to isolate problems
4. **Review security settings** if encountering permission issues