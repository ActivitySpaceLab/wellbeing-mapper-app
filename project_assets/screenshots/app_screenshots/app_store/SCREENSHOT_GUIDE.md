# Apple App Store Screenshots Manual Capture Guide

## Overview
This guide helps you capture high-quality screenshots for Apple App Store submission using the iOS Simulator.

## Prerequisites
✅ iOS Simulator running (iPhone 16 Plus for 6.7" display screenshots)
✅ Wellbeing Mapper app running on simulator
✅ Screenshots folder prepared: `screenshots/app_store/`

## Required Screenshots for App Store

### 1. iPhone 6.7" Display (iPhone 15 Pro Max, 14 Pro Max, etc.)
**Resolution**: 1290 × 2796 pixels
**Simulator**: iPhone 16 Plus (currently running)

### 2. iPhone 6.1" Display (iPhone 15 Pro, 14 Pro, etc.)  
**Resolution**: 1179 × 2556 pixels
**Simulator**: iPhone 15 Pro

### 3. iPhone 5.5" Display (iPhone 8 Plus) - Optional
**Resolution**: 1242 × 2208 pixels
**Simulator**: iPhone 8 Plus

## Screenshot Sequence

### Screenshot 1: App Mode Selection (Home/Welcome Screen)
**File Name**: `01_app_mode_selection.png`
**Description**: First screen users see - showcases privacy-focused modes
**What to capture**: 
- App Mode selection screen showing Private Mode, App Testing Mode, Research Mode
- Clean interface highlighting privacy options
- App logo and branding

### Screenshot 2: Main Dashboard with Location Tracking
**File Name**: `02_main_dashboard.png`
**Description**: Main app interface with location tracking controls
**What to capture**:
- Home screen with location tracking toggle
- App status indicators
- Clean, professional interface
- Navigation drawer icon visible

### Screenshot 3: Side Menu with Features
**File Name**: `03_side_menu_features.png`
**Description**: App features overview through side drawer
**What to capture**:
- Open side drawer showing all app features
- Wellbeing Map, Timeline, Export Data options
- Clear feature organization

### Screenshot 4: Wellbeing Map View
**File Name**: `04_wellbeing_map.png`
**Description**: Interactive map showing wellbeing data visualization
**What to capture**:
- Map view with wellbeing data points (if available)
- Clean map interface
- Professional data visualization

### Screenshot 5: Wellbeing Timeline
**File Name**: `05_wellbeing_timeline.png`
**Description**: Timeline/chart view of wellbeing trends
**What to capture**:
- Timeline or chart visualization
- Clear data presentation
- User-friendly analytics interface

### Screenshot 6: Research Mode Features
**File Name**: `06_research_mode.png`
**Description**: Research participation features (if applicable)
**What to capture**:
- Research mode interface
- Survey options
- Professional research features

### Screenshot 7: Privacy and Data Control
**File Name**: `07_privacy_controls.png`
**Description**: Data export and privacy controls
**What to capture**:
- Data export interface
- Privacy settings
- User control over data

## How to Take Screenshots

### Using iOS Simulator:
1. **Command + S** in Simulator window to save screenshot
2. Screenshots save to Desktop by default
3. Rename files according to the naming convention above

### Using Simulator Menu:
1. Device → Screenshot
2. Save to designated folder

### Important Notes:
- Take screenshots in **portrait orientation**
- Ensure **status bar is clean** (good signal, full battery shown)
- **No personal data** should be visible
- Use **light theme** for better App Store presentation
- **High resolution** - don't resize or compress

## File Organization

Save screenshots in this structure:
```
screenshots/app_store/
├── iPhone-15-Pro-Max/     # 6.7" display screenshots
├── iPhone-15-Pro/         # 6.1" display screenshots  
├── iPhone-8-Plus/         # 5.5" display screenshots
└── README.md              # This file
```

## App Store Requirements Checklist

### Technical Requirements:
- [ ] PNG format
- [ ] RGB color space
- [ ] No transparency
- [ ] Correct resolution for each device size

### Content Requirements:
- [ ] Show actual app functionality
- [ ] No misleading features
- [ ] Professional appearance
- [ ] No placeholder text
- [ ] Clear, readable text
- [ ] Good contrast and visibility

### Best Practices:
- [ ] Show key app value propositions
- [ ] Highlight unique features
- [ ] Professional, polished appearance
- [ ] Consistent visual style
- [ ] No sensitive user data
- [ ] Focus on user benefits

## Next Steps

1. **Capture all required screenshots** for iPhone 16 Plus (6.7" display)
2. **Switch to iPhone 15 Pro simulator** for 6.1" display screenshots
3. **Switch to iPhone 8 Plus simulator** for 5.5" display screenshots (optional)
4. **Review and organize** all screenshots
5. **Upload to App Store Connect**

## Simulator Commands

To switch simulators:
```bash
# Stop current simulator
# Start iPhone 15 Pro for 6.1" display
fvm flutter emulators --launch apple_ios_simulator

# Then run app on specific simulator:
fvm flutter run -d [SIMULATOR_ID]
```

## Troubleshooting

**If app doesn't show expected content:**
- Navigate through app modes (Private → Research) to see all features
- Trigger wellbeing surveys if needed for data visualization
- Use demo data if available

**If screenshots are wrong resolution:**
- Verify simulator device type matches requirements
- Use Simulator's native screenshot feature (Cmd+S)
- Don't resize images after capture

**For best results:**
- Use newest iOS version simulators
- Ensure app is in release mode for best performance
- Clear simulator data between captures if needed
