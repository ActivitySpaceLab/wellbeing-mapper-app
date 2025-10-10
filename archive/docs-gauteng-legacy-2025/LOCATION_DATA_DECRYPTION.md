---
layout: default
title: Location Data Decryption
description: How to decrypt location data from Qualtrics survey exports
---

# Location Data Decryption Tool for Researchers

This guide explains how to decrypt location data collected through the Wellbeing Mapper app and exported from Qualtrics surveys.

## Overview

The Wellbeing Mapper app encrypts all location data using a hybrid RSA+AES encryption system before uploading through a secure proxy server to Qualtrics. This ensures participant privacy during data transmission and storage. As a researcher, you need to decrypt this data using your private key to analyze the location information.

## What You'll Need

- **Your RSA private key file** (the `.pem` file you used to generate the public key for the app)
- **Qualtrics CSV export** containing the encrypted location data
- **Python 3.6 or higher** installed on your computer
- **Basic computer skills** (running commands, finding files)

## Quick Start

### Step 1: Install Python
If you don't have Python installed:
1. Go to [python.org](https://python.org/downloads/)
2. Download Python 3.6 or newer for your operating system
3. **Important**: During installation, check "Add Python to PATH"
4. Complete the installation

### Step 2: Download the Decryption Tool
1. Download the following files from the project repository:
   - `decrypt_location_data.py` - Main decryption tool
   - `requirements.txt` - Required Python libraries
   - `test_decryption.py` - Test script (optional)

2. Save these files to a folder on your computer

### Step 3: Install Required Libraries
1. Open Command Prompt (Windows) or Terminal (Mac/Linux)
2. Navigate to the folder with the decryption tool:
   ```bash
   cd path/to/your/folder
   ```
3. Install the required cryptography library:
   ```bash
   pip install -r requirements.txt
   ```
   Or manually:
   ```bash
   pip install cryptography
   ```

### Step 4: Prepare Your Files
1. **Export data from Qualtrics**:
   - Go to Data & Analysis in your Qualtrics survey
   - Click "Export & Import" → "Export Data"
   - Choose CSV format
   - Download the file

2. **Locate your private key**:
   - Find the `.pem` file you created when setting up encryption
   - This should be named something like `gauteng_private_key.pem`

3. **Organize your files**:
   Place these files in the same folder as the decryption tool:
   - Your private key file (`.pem`)
   - Your Qualtrics CSV export
   - The `decrypt_location_data.py` script

## Using the Decryption Tool

### Basic Usage
1. Open Command Prompt/Terminal and navigate to your folder
2. Run the decryption tool:
   ```bash
   python decrypt_location_data.py
   ```
3. Follow the on-screen prompts:
   - The tool will automatically find your key and CSV files
   - Select the correct files if multiple options are found
   - Enter your private key password if it's encrypted
   - Wait for processing to complete

### Example Session
```
🗺️  WELLBEING MAPPER LOCATION DATA DECRYPTION TOOL
================================================================

This tool will decrypt location data from your Qualtrics survey export.
Make sure you have:
  ✓ Your RSA private key file (.pem format)
  ✓ CSV export from Qualtrics with encrypted location data

🔍 Looking for files in current directory...

📁 Found 1 potential private key file(s):
   1. gauteng_private_key.pem
✅ Using: gauteng_private_key.pem

📁 Found 1 CSV file(s):
   1. WellbeingMapper_Survey_Export_20250811.csv
✅ Using: WellbeingMapper_Survey_Export_20250811.csv

🔑 Loading private key...
✅ Successfully loaded private key from gauteng_private_key.pem

📊 Processing Qualtrics CSV export...
Processing row 3...
Processing row 4...
Processing row 5...

✅ Processing complete!
   Successfully processed: 15 rows
   Errors: 2 rows
   Total location points extracted: 342

💾 Saving decrypted data...
✅ Decrypted location data saved to: decrypted_locations_20250811_143022.csv

🎉 SUCCESS!
   Decrypted location data saved to: decrypted_locations_20250811_143022.csv
   Total location points: 342
   You can now open this file in Excel or any spreadsheet program.
```

## Understanding the Output

The decrypted CSV file contains one row per location point with the following columns:

| Column | Description | Example |
|--------|-------------|---------|
| `participant_code` | Participant identifier from survey | `PARTICIPANT_001` |
| `participant_uuid` | Unique participant ID | `550e8400-e29b-41d4-a716-446655440000` |
| `survey_date` | When the survey was submitted | `2025-08-11 14:25:45` |
| `timestamp` | When this location was recorded | `2025-08-11T10:30:00Z` |
| `latitude` | GPS latitude coordinate | `-26.2041` |
| `longitude` | GPS longitude coordinate | `28.0473` |
| `accuracy` | GPS accuracy in meters | `5.0` |
| `speed` | Speed in m/s (if available) | `1.2` |
| `heading` | Direction of travel in degrees | `45.0` |
| `altitude` | Elevation in meters (if available) | `1753.0` |

### Data Analysis Tips
- **Timestamp format**: All timestamps are in ISO 8601 format (UTC)
- **Coordinate system**: Uses WGS84 (standard GPS coordinates)
- **Accuracy**: Lower numbers indicate better GPS accuracy
- **Missing data**: Empty cells indicate data not available from GPS
- **Multiple points**: Each participant may have multiple location points per survey

## Troubleshooting

### Common Issues and Solutions

#### "cryptography library not found"
**Problem**: Python can't find the cryptography library
**Solution**: 
```bash
pip install cryptography
```
If that fails, try:
```bash
pip install --upgrade pip
pip install cryptography
```

#### "Private key file not found"
**Problem**: The tool can't locate your private key
**Solutions**:
- Ensure your `.pem` file is in the same folder as the script
- Check the file name doesn't have hidden characters
- Try entering the full file path when prompted

#### "Error decrypting data"
**Problem**: Decryption is failing
**Possible causes and solutions**:
- **Wrong private key**: Ensure you're using the key that matches the public key in the app
- **Incorrect password**: If your key is encrypted, verify the password
- **Corrupted data**: Re-export the CSV from Qualtrics
- **No location data**: Participants may not have shared location data

#### "No location data found"
**Problem**: The tool processes the CSV but finds no location data
**Check**:
- Participants had location sharing enabled in the app
- The CSV export includes the location data columns
- You're using the correct survey (not a test survey)

#### "Permission denied" errors
**Problem**: Can't read/write files
**Solutions**:
- Run Command Prompt/Terminal as administrator (Windows)
- Check file permissions and ensure files aren't opened in Excel
- Move files to a folder you have write access to

### Advanced Usage

#### Password-Protected Private Keys
If your private key is encrypted with a password:
1. The tool will automatically detect this
2. You'll be prompted to enter the password
3. The password is not displayed as you type (security feature)

#### Custom File Locations
If your files are in different locations:
1. Run the tool: `python decrypt_location_data.py`
2. When prompted, enter the full path to your files
3. Use forward slashes (/) even on Windows: `C:/Users/YourName/Desktop/key.pem`

#### Batch Processing Multiple Files
To process multiple CSV exports:
1. Place all CSV files in the same folder
2. Run the tool multiple times, selecting different CSV files each time
3. The tool creates timestamped output files so they won't overwrite each other

## Testing the Tool

Before processing real data, you can test the tool:

1. Run the test script to create sample data:
   ```bash
   python test_decryption.py
   ```

2. This creates:
   - `test_private_key.pem` - Sample private key
   - `test_qualtrics_export.csv` - Sample encrypted data

3. Test the decryption:
   ```bash
   python decrypt_location_data.py
   ```

4. Verify it creates a decrypted output file with sample location data

## Security Considerations

### Protecting Your Private Key
- **Never share** your private key file with anyone
- **Store securely** on encrypted drives or secure folders
- **Backup safely** using encrypted storage (not cloud storage)
- **Use strong passwords** if encrypting your private key file

### Handling Decrypted Data
- **Delete processed files** after analysis if they contain sensitive data
- **Use secure computers** - avoid public or shared computers
- **Follow institutional policies** for handling participant data
- **Consider encryption** for storing decrypted files long-term

### Data Retention
- Check your research ethics approval for data retention requirements
- Consider automated deletion of decrypted files after analysis
- Document your data handling procedures for ethics compliance

## Integration with Analysis Software

### Excel/Spreadsheet Software
The decrypted CSV files can be opened directly in:
- Microsoft Excel
- Google Sheets
- LibreOffice Calc

Tips for Excel:
- Use "Data" → "Text to Columns" if coordinates appear in one cell
- Format timestamp columns as "Date/Time" for proper sorting
- Use "Data" → "Remove Duplicates" if needed

### Statistical Software

#### R
```r
# Load decrypted location data
locations <- read.csv("decrypted_locations_20250811_143022.csv")

# Convert timestamps
locations$timestamp <- as.POSIXct(locations$timestamp, format="%Y-%m-%dT%H:%M:%SZ")

# Basic analysis
summary(locations)
plot(locations$longitude, locations$latitude)
```

#### Python (pandas)
```python
import pandas as pd
import matplotlib.pyplot as plt

# Load data
df = pd.read_csv('decrypted_locations_20250811_143022.csv')

# Convert timestamps
df['timestamp'] = pd.to_datetime(df['timestamp'])

# Basic visualization
plt.scatter(df['longitude'], df['latitude'])
plt.xlabel('Longitude')
plt.ylabel('Latitude')
plt.show()
```

#### SPSS
1. Open SPSS
2. File → Open → Data
3. Select your decrypted CSV file
4. Follow the import wizard to set variable types

### GIS Software
For spatial analysis, import into:
- **QGIS** (free): Layer → Add Layer → Add Delimited Text Layer
- **ArcGIS**: File → Add Data → Add XY Data
- **R (sf package)**: Use `st_as_sf()` with longitude/latitude columns

## Support and Documentation

### Getting Help
1. **Check this documentation** for common issues
2. **Verify your setup** using the test script
3. **Contact the development team** with:
   - Error messages (copy/paste the exact text)
   - Your operating system and Python version
   - Steps you followed before the error occurred

### Reporting Issues
When reporting problems, include:
- Error messages
- Python version: `python --version`
- Operating system
- File sizes and formats you're working with

### Updates and Maintenance
- Check for updated versions of the decryption tool
- Update the cryptography library periodically: `pip install --upgrade cryptography`
- Review this documentation for new features or procedures

## Privacy and Ethics Note

This decryption tool is designed to help researchers analyze location data while maintaining participant privacy. Always:
- Follow your institutional ethics approval
- Respect participant consent preferences
- Use decrypted data only for approved research purposes
- Implement appropriate data security measures
- Delete unnecessary copies of sensitive data

The encryption system ensures data is protected during transmission and storage, but researchers must handle decrypted data responsibly according to ethical guidelines and legal requirements.
