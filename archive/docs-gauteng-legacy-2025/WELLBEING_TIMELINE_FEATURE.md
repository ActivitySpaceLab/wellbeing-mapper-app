# Wellbeing Timeline Feature

## Overview
The Wellbeing Timeline feature provides users with a comprehensive time-series visualization of their wellbeing survey responses, allowing them to track trends and patterns in their mental wellbeing over time.

## Features

### 📊 Time-Series Graph
- **X-axis**: Date of survey responses
- **Y-axis**: Wellbeing index (0-5 scale)
- **Interactive**: Tap on data points to see detailed information
- **Smooth curves**: Shows trends clearly with gradient fills

### 📅 Time Period Filtering
Users can view their data across different time periods:
- Last 7 days
- Last 30 days
- Last 3 months
- Last year
- All time

### 📈 Statistics Summary
Real-time statistics displayed at the top:
- **Latest Score**: Most recent wellbeing score
- **Average Score**: Mean score for selected period
- **Best Score**: Highest score achieved
- **Lowest Score**: Lowest score recorded
- **Trend Analysis**: Improving/Declining/Stable
- **Survey Count**: Total surveys in period

### 🎨 Visual Elements
- **Color-coded points**: Each data point colored by wellbeing score
- **Gradient background**: Visual emphasis on the trend area
- **Legend**: Clear scale showing color meanings (0-5)
- **Tooltips**: Detailed information on tap

### 🚫 Empty State
Friendly message when no survey data is available, encouraging users to take surveys.

## Technical Implementation

### Dependencies Added
```yaml
fl_chart: ^0.69.2  # For chart visualization
intl: ^0.19.0      # For date formatting (already available)
```

### Files Created/Modified

#### New Files
- `lib/ui/wellbeing_timeline_view.dart` - Main timeline view implementation

#### Modified Files
- `lib/ui/side_drawer.dart` - Added timeline navigation menu item
- `lib/models/route_generator.dart` - Added timeline route
- `pubspec.yaml` - Added fl_chart dependency

#### Test Files
- `test/widget/wellbeing_timeline_test.dart` - Comprehensive test suite

### Navigation
- **Menu Item**: "Wellbeing Timeline" in side drawer
- **Route**: `/wellbeing_timeline`
- **Icon**: Timeline icon with descriptive subtitle

## Data Integration

### Scoring System (Consistent with Map View)
- Each survey response contributes 0-5 points total
- Individual questions: 1 point for "Yes", 0 points for "No"
- **Score 0**: Very Low (Red)
- **Score 1**: Low (Orange-Red)
- **Score 2**: Moderate-Low (Orange)
- **Score 3**: Moderate (Yellow)
- **Score 4**: Good (Light Green)
- **Score 5**: Excellent (Green)

### Data Source
- Uses `WellbeingSurveyService.getAllWellbeingSurveys()`
- Filters by selected time period
- Sorts chronologically for proper timeline display

## User Experience

### Loading States
- Shows loading spinner while fetching data
- Graceful error handling with user-friendly messages

### Interactive Elements
- **Refresh Button**: Manual data refresh
- **Period Selector**: Dropdown for time range selection
- **Data Points**: Tap for detailed tooltips
- **Smooth Navigation**: Integrated with app navigation

### Responsive Design
- Adapts to different screen sizes
- Proper spacing and margins
- Clear typography and visual hierarchy

## Benefits for Users

### 🔍 Pattern Recognition
Users can identify:
- Daily/weekly patterns in wellbeing
- Seasonal trends
- Correlation with life events
- Long-term improvement or decline

### 📋 Self-Awareness
- Visual feedback on mental health journey
- Motivation through progress tracking
- Data-driven insights into wellbeing factors

### 🎯 Goal Setting
- Clear baseline establishment
- Progress monitoring
- Trend awareness for intervention

## Testing

### Test Coverage
- ✅ Widget rendering without errors
- ✅ Empty state display
- ✅ Wellbeing score calculations
- ✅ Category mappings
- ✅ Color assignments
- ✅ Data point interactions

### Manual Testing Recommended
1. Take multiple surveys with different responses
2. Verify timeline shows correct scores and colors
3. Test different time period filters
4. Check tooltip information accuracy
5. Validate trend calculations

## Future Enhancements

### Potential Additions
- **Export functionality**: Save charts as images
- **Annotations**: Add notes to specific dates
- **Correlations**: Overlay weather/location data
- **Goals**: Set and track wellbeing targets
- **Sharing**: Share progress with healthcare providers

## Compatibility
- ✅ iOS and Android compatible
- ✅ Works with existing wellbeing survey system
- ✅ Respects privacy settings
- ✅ Follows app's design patterns

---

## Quick Start Guide

1. **Access**: Open side menu → "Wellbeing Timeline"
2. **View Data**: Your survey responses appear as a line graph
3. **Filter**: Use the date range selector (top-right)
4. **Explore**: Tap data points for details
5. **Refresh**: Use refresh button for latest data

The timeline complements the existing Wellbeing Map feature, providing temporal insights alongside spatial visualization of your mental wellbeing journey.
