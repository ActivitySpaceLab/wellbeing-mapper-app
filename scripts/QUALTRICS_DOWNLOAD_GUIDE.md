# Qualtrics Data Download Guide

This guide explains how to use the `download_qualtrics_data.py` script to automatically download survey response data from your Qualtrics account.

## Prerequisites

1. **Python 3.7+** with pip installed
2. **Valid Qualtrics API Token** with survey access permissions
3. **Required Python packages**: `requests` and `pandas`

## Installation

1. Install required dependencies:
```bash
pip install -r requirements-qualtrics.txt
```

2. Get your Qualtrics API token:
   - Log into your Qualtrics account
   - Go to **Account Settings** > **Qualtrics IDs**
   - Click **Generate Token** under API section
   - Copy the generated token

3. Set your API token as an environment variable:
```bash
export QUALTRICS_API_TOKEN='your_token_here'
```

## Available Survey Data

The script downloads data from the unified Gauteng Wellbeing Mapper survey:

- **Survey ID**: SV_81uhgIyzv52qgdM
- **Survey Name**: Gauteng Wellbeing Mapper Survey
- **Data Types**: Contains three types of survey responses:
  - **Initial**: Initial Demographics Survey responses
  - **Biweekly**: Biweekly Wellbeing Survey responses
  - **Consent**: Consent Form responses

All survey types are stored in the same Qualtrics survey and differentiated by the `survey_type` column in the response data.

## Usage Examples

### List Survey Information
```bash
python3 download_qualtrics_data.py --info
```

### Download All Survey Data
```bash
python3 download_qualtrics_data.py --all
```

Note: The `--all` flag is the default behavior, so you can also simply run:
```bash
python3 download_qualtrics_data.py
```

### Download Data from Specific Time Periods
```bash
# Download data from last 30 days
python3 download_qualtrics_data.py --days 30

# Download data from specific date range
python3 download_qualtrics_data.py --start 2024-01-01 --end 2024-12-31

# Download recent data (last 7 days)
python3 download_qualtrics_data.py --days 7
```

### Custom Output Directory
```bash
# Save to custom directory
python3 download_qualtrics_data.py --output ./my_survey_data/

# Save with date range to organized folder
python3 download_qualtrics_data.py --days 30 --output ./data/monthly/
```

## Output Files

Downloaded data is saved as a single CSV file:

- `wellbeing_mapper_responses.csv` - All survey responses (initial, biweekly, consent)

The file includes:
- All response data with readable column labels
- Survey type differentiation via `survey_type` column
- Encrypted data in `encrypted_data` column (for responses with location data)
- Timestamp information in `timestamp` column
- Metadata (response ID, recorded date, etc.)
- Participant identifiers for data linking

## Data Structure

### CSV Format
- **Header row**: Question labels and metadata fields
- **Data rows**: One row per survey response
- **Survey Type**: Identified by `survey_type` column values:
  - `QID2_TEXT_initial` - Initial demographics survey
  - `QID2_TEXT_biweekly` - Biweekly wellbeing survey  
  - `QID2_TEXT_consent` - Consent form responses
- **Encrypted Data**: Location data stored in `encrypted_data` column (base64 encoded)
- **Missing values**: Coded as -999 for unanswered questions
- **Date format**: ISO 8601 format (YYYY-MM-DDTHH:MM:SSZ)

### Key Columns
All surveys include these metadata columns:
- `ResponseId` - Unique Qualtrics response identifier
- `RecordedDate` - When the response was submitted
- `DistributionChannel` - How the survey was accessed
- `UserLanguage` - Language used by participant

## Advanced Usage

### API Configuration
```bash
# Use custom API base URL (for different data centers)
python3 download_qualtrics_data.py --base-url https://your-datacenter.qualtrics.com/API/v3 --all

# Provide API token via command line
python3 download_qualtrics_data.py --api-token YOUR_TOKEN_HERE --all
```

### Automation
Create a cron job or scheduled task to automatically download data:

```bash
#!/bin/bash
# daily_data_download.sh

export QUALTRICS_API_TOKEN='your_token_here'
cd /path/to/your/project
python3 download_qualtrics_data.py --all --output ./data/$(date +%Y-%m-%d)/
```

## Integration with Decryption Pipeline

This script is designed to work with the existing decryption tools:

1. **Download data** using this script
2. **Decrypt survey responses** using `decrypt_csv_data.py`
3. **Decrypt location data** using `decrypt_location_data.py`
4. **Process structured data** for analysis

Example workflow:
```bash
# 1. Download latest data
python3 download_qualtrics_data.py --all --days 7

# 2. Decrypt the downloaded files
python3 decrypt_csv_data.py data/biweekly_survey_responses.csv

# 3. Extract location data
python3 decrypt_location_data.py data/biweekly_survey_responses.csv
```

## Troubleshooting

### Common Issues

**401 Unauthorized Error**
- Check your API token is correct and active
- Verify token has permissions for the surveys
- Ensure token hasn't expired

**Survey Not Found (404)**
- Verify survey IDs in the script match your Qualtrics surveys
- Check that surveys are published and active
- Ensure your account has access to the surveys

**Empty or No Data**
- Check the date range - there might be no responses in that period
- Verify surveys have been receiving responses
- Check if responses are in published state

**Network/Connection Issues**
- Verify internet connection
- Check if Qualtrics API is accessible from your network
- Try with a smaller date range to reduce download size

### Debug Mode
Add print statements or use Python debugger to trace issues:
```python
# In the script, add debug output
print(f"API Token: {self.api_token[:10]}...")  # Only show first 10 chars
print(f"Survey ID: {survey_id}")
print(f"Request URL: {self.base_url}/surveys/{survey_id}/export-responses")
```

## Security Notes

- **Never commit API tokens** to version control
- **Use environment variables** for production deployments
- **Rotate API tokens** regularly per your organization's policy
- **Limit token permissions** to only necessary surveys
- **Store downloaded data securely** according to data protection requirements

## Support

For issues with:
- **Script functionality**: Check error messages and troubleshooting section
- **Qualtrics API**: Refer to [Qualtrics API Documentation](https://api.qualtrics.com)
- **Survey configuration**: Verify survey IDs and permissions in Qualtrics dashboard