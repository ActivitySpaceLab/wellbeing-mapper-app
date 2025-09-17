# Structured Data Tables Guide

This guide explains how to use the `create_structured_tables.py` script to organize decrypted survey data into clean, analysis-ready tables for research purposes.

## Overview

The structured data tables system transforms the output from the automated decryption pipeline into four normalized, relational tables optimized for research analysis:

1. **participants** - Master participant demographics table
2. **biweekly_responses** - Time-series wellbeing survey data
3. **consent_records** - Data sharing consent tracking
4. **location_tracks** - GPS location data with temporal organization

## Prerequisites

1. **Decrypted survey data** from the automated decryption pipeline
2. **Python 3.7+** with pandas: `pip install pandas`
3. **Input data structure**: CSV files from decryption pipeline

## Expected Input Files

The script looks for these files in the input directory:
- `initial_decrypted_responses.csv` - Demographics survey data
- `biweekly_decrypted_responses.csv` - Wellbeing survey responses
- `biweekly_decrypted_locations.csv` - Extracted GPS location points
- `consent_decrypted_responses.csv` - Consent form responses

## Usage Examples

### Basic Processing
```bash
# Process all decrypted data with default settings
python3 create_structured_tables.py --input ./decrypted_data

# Custom input and output directories
python3 create_structured_tables.py --input ./my_decrypted_data --output ./analysis_ready_data
```

### Database Generation
```bash
# Create SQLite database for analysis
python3 create_structured_tables.py --input ./decrypted_data --database research_data.db

# Create database with custom name and location
python3 create_structured_tables.py --input ./decrypted_data --database ./databases/wellbeing_study.db
```

### Output Format Control
```bash
# Generate only CSV files (no JSON)
python3 create_structured_tables.py --input ./decrypted_data --csv-only

# Generate only JSON files (no CSV)
python3 create_structured_tables.py --input ./decrypted_data --json-only

# Generate detailed summary report
python3 create_structured_tables.py --input ./decrypted_data --summary
```

## Output Structure

### File Organization
```
structured_data/
├── participants.csv              # Demographics table
├── biweekly_responses.csv        # Survey responses table
├── consent_records.csv           # Consent tracking table
├── location_tracks.csv           # GPS location data table
├── participants.json             # JSON format (optional)
├── biweekly_responses.json       # JSON format (optional)
├── consent_records.json          # JSON format (optional)
├── location_tracks.json          # JSON format (optional)
└── data_summary.md               # Processing summary report
```

### SQLite Database (if requested)
```
research_data.db
├── participants (table)
├── biweekly_responses (table)
├── consent_records (table)
└── location_tracks (table)
```

## Table Schemas

### 1. Participants Table
**Purpose**: Master demographics and participant information

| Column | Type | Description |
|--------|------|-------------|
| participant_id | TEXT | Unique participant identifier |
| age | INTEGER | Participant age |
| gender | TEXT | Gender identity |
| ethnicity | TEXT | Ethnic background |
| education | TEXT | Education level |
| employment | TEXT | Employment status |
| income | TEXT | Income bracket |
| household_size | INTEGER | Number of household members |
| location_area | TEXT | General geographic area |
| registration_date | TEXT | Date of study enrollment |
| consent_status | TEXT | Current consent status |

### 2. Biweekly Responses Table
**Purpose**: Time-series wellbeing and activity data

| Column | Type | Description |
|--------|------|-------------|
| response_id | TEXT | Unique response identifier |
| participant_id | TEXT | Links to participants table |
| submission_date | TEXT | Survey submission date |
| survey_week | INTEGER | Week number in study |
| happiness_score | REAL | Happiness rating (0-10) |
| stress_level | REAL | Stress level rating |
| life_satisfaction | REAL | Life satisfaction score |
| health_rating | REAL | Self-reported health rating |
| activity_level | TEXT | Physical activity description |
| places_visited | INTEGER | Number of places visited |
| travel_distance | REAL | Total travel distance |
| transport_modes | TEXT | Transportation methods used |
| social_interactions | INTEGER | Number of social interactions |
| green_space_time | REAL | Time spent in green spaces |
| indoor_time | REAL | Time spent indoors |
| has_location_data | BOOLEAN | Whether GPS data is available |
| location_points_count | INTEGER | Number of GPS points collected |
| data_quality_score | REAL | Data completeness metric |

### 3. Consent Records Table
**Purpose**: Data sharing permissions and legal compliance

| Column | Type | Description |
|--------|------|-------------|
| consent_id | TEXT | Unique consent record identifier |
| participant_id | TEXT | Links to participants table |
| consent_date | TEXT | Date consent was given |
| consent_type | TEXT | Type of consent (initial, updated, etc.) |
| data_sharing_approved | BOOLEAN | Permission to share anonymized data |
| location_sharing_approved | BOOLEAN | Permission to collect GPS data |
| research_contact_approved | BOOLEAN | Permission for follow-up contact |
| data_retention_period | TEXT | How long data can be stored |
| informed_consent_version | TEXT | Version of consent form used |
| withdrawal_date | TEXT | Date consent was withdrawn (if applicable) |
| withdrawal_reason | TEXT | Reason for withdrawal |

### 4. Location Tracks Table
**Purpose**: GPS location data with temporal and spatial analysis fields

| Column | Type | Description |
|--------|------|-------------|
| track_id | TEXT | Unique track point identifier |
| participant_id | TEXT | Links to participants table |
| response_id | TEXT | Links to biweekly_responses table |
| timestamp | TEXT | Exact timestamp of GPS reading |
| latitude | REAL | GPS latitude coordinate |
| longitude | REAL | GPS longitude coordinate |
| accuracy | REAL | GPS accuracy in meters |
| altitude | REAL | Elevation in meters |
| speed | REAL | Movement speed in m/s |
| heading | REAL | Direction of movement in degrees |
| date | TEXT | Date component (YYYY-MM-DD) |
| time | TEXT | Time component (HH:MM:SS) |
| day_of_week | TEXT | Day name (Monday, Tuesday, etc.) |
| hour_of_day | INTEGER | Hour (0-23) for temporal analysis |
| stay_point | BOOLEAN | Whether this is a stationary location |
| activity_type | TEXT | Inferred activity (walking, driving, etc.) |
| location_context | TEXT | Inferred location type (home, work, etc.) |

## Data Processing Features

### Automatic Column Detection
The script automatically detects and maps survey columns from different formats:
- **Qualtrics export format** (Q1, Q2, Q3, etc.)
- **Named columns** (age, gender, happiness_score, etc.)
- **Alternative naming** (participant_id, participantId, ResponseId)

### Data Type Conversion
- **Intelligent type casting**: Strings to numbers, dates, booleans
- **Missing value handling**: Null/empty values properly handled
- **Data validation**: Invalid entries logged as quality issues

### Temporal Organization
Location data is automatically enhanced with temporal fields:
- **Date/time separation** for easier filtering
- **Day of week analysis** for weekly patterns
- **Hour of day** for circadian rhythm studies

### Quality Assurance
- **Data completeness tracking** for each participant
- **Error logging** for processing issues
- **Summary statistics** in processing report

## Analysis Integration

### Python/Pandas Analysis
```python
import pandas as pd

# Load structured data
participants = pd.read_csv('structured_data/participants.csv')
responses = pd.read_csv('structured_data/biweekly_responses.csv')
locations = pd.read_csv('structured_data/location_tracks.csv')

# Example: Happiness trends over time
happiness_trends = responses.groupby(['participant_id', 'submission_date'])['happiness_score'].mean()

# Example: Location activity patterns
hourly_activity = locations.groupby('hour_of_day').size()

# Example: Demographic analysis
age_happiness = responses.merge(participants, on='participant_id').groupby('age')['happiness_score'].mean()
```

### SQLite Analysis
```sql
-- Load database
sqlite3 research_data.db

-- Happiness by age group
SELECT 
    CASE 
        WHEN age < 25 THEN '18-24'
        WHEN age < 35 THEN '25-34'
        WHEN age < 45 THEN '35-44'
        ELSE '45+'
    END as age_group,
    AVG(happiness_score) as avg_happiness
FROM participants p
JOIN biweekly_responses r ON p.participant_id = r.participant_id
GROUP BY age_group;

-- Location patterns by day of week
SELECT 
    day_of_week,
    COUNT(*) as location_points,
    AVG(speed) as avg_speed
FROM location_tracks
GROUP BY day_of_week
ORDER BY CASE day_of_week
    WHEN 'Monday' THEN 1
    WHEN 'Tuesday' THEN 2
    WHEN 'Wednesday' THEN 3
    WHEN 'Thursday' THEN 4
    WHEN 'Friday' THEN 5
    WHEN 'Saturday' THEN 6
    WHEN 'Sunday' THEN 7
END;
```

### R Analysis
```r
library(DBI)
library(RSQLite)
library(dplyr)

# Connect to database
con <- dbConnect(SQLite(), "research_data.db")

# Load tables
participants <- dbReadTable(con, "participants")
responses <- dbReadTable(con, "biweekly_responses")
locations <- dbReadTable(con, "location_tracks")

# Example analysis
happiness_by_demographics <- responses %>%
  left_join(participants, by = "participant_id") %>%
  group_by(gender, age) %>%
  summarise(avg_happiness = mean(happiness_score, na.rm = TRUE))

dbDisconnect(con)
```

## Complete Workflow Integration

### End-to-End Data Processing
```bash
#!/bin/bash
# complete_data_pipeline.sh

# 1. Download survey data
export QUALTRICS_API_TOKEN='your_token_here'
python3 download_qualtrics_data.py --all --output ./raw_data

# 2. Decrypt survey responses
python3 automated_decryption_pipeline.py --input ./raw_data --output ./decrypted_data

# 3. Create structured tables
python3 create_structured_tables.py --input ./decrypted_data --database wellbeing_study.db --summary

echo "✅ Complete data processing pipeline finished!"
echo "📊 Analysis-ready data available in:"
echo "   - CSV files: ./structured_data/"
echo "   - SQLite database: wellbeing_study.db"
echo "   - Summary report: ./structured_data/data_summary.md"
```

### Automated Research Workflow
```bash
#!/bin/bash
# daily_research_update.sh

DATE=$(date +%Y-%m-%d)

# Create dated directory structure
mkdir -p "./research_data/$DATE"

# Process latest data
python3 create_structured_tables.py \
  --input ./decrypted_data \
  --output "./research_data/$DATE" \
  --database "./research_data/$DATE/daily_data.db" \
  --summary

# Generate research dashboard (if you have one)
# python3 generate_research_dashboard.py --data "./research_data/$DATE"

echo "✅ Daily research data update completed for $DATE"
```

## Data Privacy and Ethics

### Privacy Protection
- **Participant IDs**: Use anonymized identifiers only
- **Location data**: Ensure proper aggregation for privacy
- **Demographic data**: Consider data minimization principles
- **Consent tracking**: Maintain accurate consent records

### Research Compliance
- **Data retention**: Follow institutional data retention policies
- **Access control**: Implement appropriate database security
- **Data sharing**: Only share data with proper consent
- **Documentation**: Maintain detailed processing logs

## Troubleshooting

### Common Issues

**Missing Input Files**
- Ensure decryption pipeline completed successfully
- Check file naming matches expected patterns
- Verify file permissions and accessibility

**Data Quality Issues**
- Review `data_summary.md` for detailed error information
- Check source data for formatting problems
- Validate participant ID consistency across surveys

**Performance Issues**
- Large location datasets may require substantial memory
- Consider processing in batches for very large studies
- Use SQLite database for efficient querying of large datasets

### Debug Mode
Add print statements or use Python debugger to trace processing:
```python
# In the script, add debug output
print(f"Processing participant: {participant_id}")
print(f"Found columns: {list(row.index)}")
print(f"Extracted values: {happiness_score}, {stress_level}")
```

## Support and Maintenance

For issues with structured data tables:
1. **Check processing logs** in the summary report
2. **Validate input data** format and completeness
3. **Test with small datasets** to isolate problems
4. **Review column mapping** configurations if data format changes