# Data Analysis Toolkit

Complete end-to-end pipeline for processing encrypted survey data from the Gauteng Wellbeing Mapper study, including **automated image extraction** from encrypted submissions.

## 🎯 **QUICK START - Complete Pipeline with Images**

**Run this single command to process all survey data including images:**

```bash
python end_to_end_pipeline_test.py
```

**✅ WORKING: The pipeline downloads, decrypts, and extracts images in one command! You'll be prompted for the decryption password.**

**🚨 Quick Alternative: If you have existing data, use the quick pipeline:**
```bash
python quick_pipeline_test.py
```

This automatically downloads ALL available data, decrypts, and extracts everything including images. **Results are saved to:**
- 📊 **Survey data**: `test_data/structured_data/*.csv`
- 📷 **Extracted images**: `test_data/structured_data/images/*.jpg`
- 📋 **Analysis report**: `test_data/structured_data/processing_report.json`

---

## 📁 **Directory Structure**

### **Main Scripts**
- `end_to_end_pipeline_test.py` - **⭐ MAIN SCRIPT** - Complete automated pipeline
- `create_survey_csvs.py` - Convert decrypted data to CSV format with image extraction
- `validate_survey_data.py` - Data validation and quality checks

### **Tool Directories**
- `qualtrics_tools/` - Qualtrics API download tools
- `decryption_tools/` - Hybrid RSA/AES decryption pipeline  
- `structure_tools/` - Data analysis and structuring tools
- `survey_csvs/` - Legacy CSV creation tools (deprecated)

### **Output Directories** 
- `test_data/structured_data/` - **📍 YOUR FINAL RESULTS GO HERE**
  - `biweekly_survey.csv` - Processed biweekly wellbeing surveys
  - `initial_survey.csv` - Processed initial demographic surveys  
  - `consent.csv` - Processed consent responses
  - `location_data.csv` - GPS location tracking data
  - `images/` - **📷 Extracted survey images with descriptive filenames**

## 🖼️ **Image Processing Features**

The toolkit now includes **complete image encryption/decryption**:

✅ **Images are encrypted** with survey data in the mobile app  
✅ **Images are transmitted securely** through encrypted channels  
✅ **Images are automatically extracted** during data processing  
✅ **Images are saved** with descriptive filenames: `{ResponseId}_{SurveyType}_{OriginalName}.jpg`

### **Manual Image Extraction**

If you need to extract images separately:

```bash
python create_survey_csvs.py \
  --input test_data/decrypted_data \
  --output test_data/structured_data \
  --download-images \
  --report
```

**⚠️ Important:** Always use the `--download-images` flag to extract images!

## 🚀 **Step-by-Step Usage**

### **Option 1: Full Automated Pipeline (Recommended)**

```bash
# Run everything in one command
python end_to_end_pipeline_test.py
```

### **Option 2: Manual Step-by-Step**

```bash
# 1. Download from Qualtrics  
python qualtrics_tools/download_qualtrics_data.py --output raw_data --all

# 2. Decrypt survey data
PRIVATE_KEY_PASSWORD='your_password' python decryption_tools/automated_decryption_pipeline.py \
  --input raw_data --output decrypted_data --private-key ../untracked/private_key.pem

# 3. Extract images and create CSV files
python create_survey_csvs.py \
  --input decrypted_data --output final_data --download-images --report --validate
```

## 📊 **Understanding Your Results**

After running the pipeline, check these locations:

### **Survey Data (CSV Files)**
- `test_data/structured_data/biweekly_survey.csv` - Wellbeing survey responses
- `test_data/structured_data/initial_survey.csv` - Demographic data  
- `test_data/structured_data/consent.csv` - Consent form responses
- `test_data/structured_data/location_data.csv` - GPS tracking data

### **Images** 
- `test_data/structured_data/images/` - All images extracted from surveys
- **Filename format**: `R_41LokyAXnhlYMtM_biweekly_scaled_1000000057.jpg`
  - `R_41LokyAXnhlYMtM` = Qualtrics Response ID
  - `biweekly` = Survey type (biweekly/initial)  
  - `scaled_1000000057.jpg` = Original filename from mobile app

### **Reports**
- `test_data/structured_data/processing_report.json` - Detailed processing statistics
- `pipeline_test_report.json` - End-to-end pipeline results

## 📋 **Requirements**

- Python 3.8+
- Valid Qualtrics API credentials  
- Private encryption key (`../untracked/private_key.pem`)
- Internet connection for Qualtrics downloads

## 🔐 **Security & Setup**

1. **Environment Variables:**
   ```bash
   export PRIVATE_KEY_PASSWORD='your_decryption_password'
   export QUALTRICS_API_TOKEN='your_qualtrics_token'
   ```

2. **File Locations:**
   - Private key: `../untracked/private_key.pem` 
   - API credentials: Set as environment variables
   - **Never commit encryption keys to version control!**

## 🆘 **Troubleshooting**

### **No Images Extracted?**
- ✅ Use `--download-images` flag with `create_survey_csvs.py`
- ✅ Check `processing_report.json` for "Images processed" count
- ✅ Verify surveys actually contain images in the app

### **Decryption Fails?**  
- ✅ Enter your password when prompted during pipeline execution
- ✅ Verify private key path: `../untracked/private_key.pem`
- ✅ Check Qualtrics API credentials

### **Empty Downloads?**
- ✅ Use `--all` flag for full date range: `python download_qualtrics_data.py --all`
- ✅ Check Qualtrics API token permissions
- ✅ Verify survey responses exist in Qualtrics dashboard

## 📖 **Additional Documentation**

- `AUTOMATED_DECRYPTION_GUIDE.md` - Detailed decryption pipeline guide
- `QUALTRICS_DOWNLOAD_GUIDE.md` - Qualtrics API setup and usage
- `STRUCTURED_DATA_GUIDE.md` - Data structure and analysis guide

---

**🎉 Ready to analyze your data? Run `python end_to_end_pipeline_test.py` and check `test_data/structured_data/` for your results!**