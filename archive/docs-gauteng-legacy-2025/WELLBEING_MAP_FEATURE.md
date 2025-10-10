# Wellbeing Map Feature

## Overview
The Wellbeing Map feature allows users to visualize their 5-question wellbeing survey responses geographically. Each survey response is scored from 0-5 based on the number of "Yes" answers, and displayed as colored points on an interactive map.

## Features

### Wellbeing Score Calculation
- **5 Questions**: Each with Yes/No answers
  1. "Do you feel cheerful and in good spirits right now?"
  2. "Do you feel calm and relaxed right now?"
  3. "Do you feel active and vigorous right now?"
  4. "Did you wake up today feeling fresh and rested?"
  5. "Has your life today been filled with things that interest you?"

- **Scoring**: Each "Yes" = 1 point, "No" = 0 points
- **Total Score Range**: 0-5 points
- **Categories**: 
  - 0 = Very Low
  - 1 = Low  
  - 2 = Below Average
  - 3 = Average
  - 4 = Good
  - 5 = Excellent

### Map Visualization

#### Point Mode (Default)
- Displays individual survey responses as colored circles
- Color coding from red (low wellbeing) to green (high wellbeing)
- Point size: 30px diameter with score number displayed
- Tap points to see detailed survey information

#### Heat Map Mode
- Semi-transparent circles with size based on wellbeing score
- Larger circles indicate higher wellbeing scores
- Overlapping areas show wellbeing density

#### Color Legend
- **Red (0 points)**: Very low wellbeing
- **Red-Orange (1 point)**: Low wellbeing  
- **Orange (2 points)**: Below average
- **Amber (3 points)**: Average wellbeing
- **Light Green (4 points)**: Good wellbeing
- **Green (5 points)**: Excellent wellbeing

### Statistics Panel
- **Total Surveys**: Count of surveys with location data
- **Average Score**: Mean wellbeing score across all responses
- **Highest Score**: Best wellbeing score recorded

### User Interface
- **Access**: Available from side menu → "Wellbeing Map"
- **Toggle Views**: Tap scatter plot/heat map icon to switch modes
- **Refresh**: Reload survey data with refresh icon
- **Map Controls**: Standard pinch-to-zoom and pan
- **Survey Details**: Tap any point to see full survey responses

## Technical Implementation

### New Files
- `lib/ui/wellbeing_map_view.dart`: Main map interface
- Enhanced `lib/models/wellbeing_survey_models.dart`: Added scoring methods

### Dependencies
- Uses existing `flutter_map` package for map rendering
- Integrates with existing `WellbeingSurveyService` for data access
- Location data from existing survey capture system

### Data Requirements
- Only displays surveys that have location data (latitude/longitude)
- Requires at least one completed wellbeing survey with location
- Uses OpenStreetMap tiles for base map

## User Benefits

### Personal Insights
- **Spatial Patterns**: See where wellbeing is typically higher/lower
- **Location Awareness**: Understand environmental influences on mood
- **Trend Visualization**: Track wellbeing changes across different locations
- **Personal Analytics**: Identify beneficial vs. challenging environments

### Research Value
- **Mobility-Wellbeing Correlation**: Visual patterns help researchers
- **Environmental Psychology**: Link places to psychological states
- **Intervention Planning**: Identify locations needing support
- **Policy Development**: Inform urban planning decisions

## Privacy & Data
- **Local Storage**: All visualization uses locally stored data
- **No Additional Tracking**: Uses existing survey location capture
- **User Control**: Data shown only when user explicitly takes surveys
- **Research Mode**: Anonymized data can be shared with research teams

## Future Enhancements
- Time-based filtering (show specific date ranges)
- Advanced heat map rendering with proper density algorithms
- Export map visualizations as images
- Integration with environmental data layers
- Comparison with other users (anonymized, research participants only)

---

*This feature enhances the existing wellbeing survey system by adding spatial visualization capabilities, helping users understand the relationship between their locations and psychological wellbeing.*
