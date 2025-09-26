# Qualtrics Tools

Tools for downloading and managing survey data from Qualtrics.

## Files

- **`download_qualtrics_data.py`** - Main script for downloading survey responses
- **`requirements-qualtrics.txt`** - Python dependencies

## Setup

1. Install dependencies:
   ```bash
   pip install -r requirements-qualtrics.txt
   ```

2. Set up Qualtrics API credentials:
   ```bash
   export QUALTRICS_API_TOKEN="your_api_token"
   export QUALTRICS_BASE_URL="your_base_url"
   ```

3. Run download script:
   ```bash
   python download_qualtrics_data.py
   ```

## Configuration

Edit the script to specify:
- Survey IDs to download
- Output directory for downloaded data
- Date ranges for data filtering

See `../QUALTRICS_DOWNLOAD_GUIDE.md` for detailed instructions.