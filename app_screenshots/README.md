# 📸 Wellbeing Mapper Screenshot System

This directory contains an automated screenshot capture system for the Wellbeing Mapper application. The system provides both automated and manual screenshot generation capabilities to document the app's user interface and features.

## 🎯 Overview

The screenshot system captures key screens and user flows of the Wellbeing Mapper app, including:

- **Participation Selection**: Private mode, Barcelona research, Gauteng research
- **Survey Interface**: Different survey types and form interactions
- **Map Views**: Location tracking and visualization
- **Settings & Configuration**: App settings and data upload screens
- **Data Management**: Upload status and privacy controls
- **Information Screens**: Consent forms, privacy policy, help screens

## 🚀 Quick Start

### Prerequisites

- Flutter 3.27.1 with FVM (recommended) or system Flutter installation
- iOS Simulator or Android Emulator (for automated testing)
- Xcode (for iOS screenshots) or Android Studio (for Android screenshots)

### Basic Usage

1. **Generate report and setup environment:**
   ```bash
   ./generate_screenshots.sh
   ```

2. **Manual screenshot capture:**
   ```bash
   ./generate_screenshots.sh --manual
   ```

3. **Show detailed instructions:**
   ```bash
   ./generate_screenshots.sh --instructions
   ```

4. **Automated capture (experimental):**
   ```bash
   ./generate_screenshots.sh --automated
   ```

## 📁 Directory Structure

```
screenshots/
├── manual/              # Manually captured screenshots
├── automated/           # Automated capture results
│   └── run_YYYYMMDD_HHMMSS/  # Timestamped runs
├── organized/           # Auto-organized screenshots
│   ├── by_type/        # Organized by screen type
│   └── by_date/        # Organized by capture date
├── report.html         # Generated HTML report
└── README.md           # This documentation
```

## 🛠 System Components

### 1. Integration Test (`integration_test/screenshot_test.dart`)

The automated screenshot system uses Flutter integration tests to:
- Launch the app in test mode
- Navigate through different screens
- Capture screenshots at key interaction points
- Handle various app states (loading, error, success)

Key features:
- **Smart Navigation**: Automatically finds and interacts with UI elements
- **Fallback Strategies**: Multiple approaches for each screen capture
- **Error Handling**: Continues execution even if some screens are inaccessible
- **Debug Output**: Provides detailed logging for troubleshooting

### 2. Screenshot Generator Script (`generate_screenshots.sh`)

A comprehensive bash script that:
- Checks prerequisites (Flutter, FVM, project structure)
- Prepares the screenshot environment
- Runs automated or manual capture workflows
- Organizes captured screenshots
- Generates HTML reports

### 3. Configuration (`screenshots.yaml`)

Defines device configurations and capture settings:
- Target devices (iPhone 15 Pro, Pixel 8, etc.)
- Screenshot quality and format settings
- Output directory structure
- Test parameters

## 📱 Manual Screenshot Instructions

### iOS Simulator
1. Open iOS Simulator
2. Run the app: `fvm flutter run`
3. Navigate to desired screen
4. Capture: **Cmd+S** or **Device > Screenshot**
5. Screenshots saved to Desktop by default

### Android Emulator
1. Open Android Emulator
2. Run the app: `fvm flutter run`
3. Navigate to desired screen
4. Capture: Click camera icon in emulator controls
5. Or use **Tools > Screenshot** from menu

### Physical Devices
- **iOS**: Power + Volume Up buttons
- **Android**: Power + Volume Down buttons

## 🔧 Technical Details

### Integration Test Architecture

The screenshot test system uses a modular approach:

```dart
// Each test captures a specific app area
testWidgets('01 - App Launch and Home Screen', (tester) async {
  app.main();
  await tester.pumpAndSettle(Duration(seconds: 3));
  await binding.takeScreenshot('01_home_screen');
});
```

### Automated Navigation Strategy

The system employs multiple strategies to navigate the app:

1. **Text-based navigation**: Searches for specific text elements
2. **Icon-based navigation**: Finds common icons (settings, menu, etc.)
3. **Widget-type navigation**: Locates specific widget types
4. **Fallback approaches**: Alternative methods when primary fails

### Error Handling

- **Graceful degradation**: Continues capturing even if some screens fail
- **Comprehensive logging**: Detailed output for debugging
- **Multiple fallbacks**: Alternative capture methods for each screen
- **State management**: Handles various app initialization states

## 📊 Generated Reports

The system generates comprehensive HTML reports including:

- **Screenshot Gallery**: Visual preview of all captured images
- **Capture Statistics**: Count of manual vs automated screenshots
- **Project Metadata**: Flutter version, timestamp, feature coverage
- **Interactive Elements**: Click to view full-size screenshots
- **Organization Tools**: Screenshots organized by type and date

## 🎨 Screenshot Best Practices

### Essential Screenshots to Capture

1. **🚀 App Launch Flow**
   - Splash screen
   - Loading states
   - First-time user experience

2. **🔘 Participation Selection**
   - All three modes: Private, Barcelona, Gauteng
   - Selection highlights
   - Confirmation screens

3. **📝 Survey Interface**
   - Empty survey form
   - Partially filled survey
   - Completed survey
   - Different question types
   - Site-specific questions (Gauteng health assessment)

4. **🗺️ Map Features**
   - Map with no data
   - Map with location tracks
   - Different zoom levels
   - Location permission prompts

5. **⚙️ Settings & Configuration**
   - Main settings screen
   - Data upload interface
   - Privacy settings
   - Consent management

6. **📊 Data Management**
   - Upload progress
   - Upload success/failure states
   - Data export options
   - Encryption status indicators

### Quality Guidelines

- **Consistency**: Use same device orientation and settings
- **Coverage**: Capture both empty and populated states
- **Clarity**: Ensure UI elements are clearly visible
- **Context**: Include relevant surrounding UI elements
- **Variations**: Capture light/dark themes if supported

## 🔍 Troubleshooting

### Common Issues

**Integration Test Fails to Start:**
```bash
# Check Flutter installation
fvm flutter doctor

# Verify dependencies
fvm flutter pub get

# Check test file syntax
fvm flutter analyze integration_test/screenshot_test.dart
```

**Screenshots Not Generated:**
```bash
# Check permissions
ls -la screenshots/

# Verify app can launch
fvm flutter run --debug

# Check for error logs
cat screenshots/automated/*/test_output.log
```

**Empty Screenshot Directory:**
```bash
# Run manual capture mode
./generate_screenshots.sh --manual

# Check device connectivity
fvm flutter devices

# Verify simulator/emulator is running
```

### Debug Mode

Enable verbose output by editing the script:
```bash
# Add debug flag to Flutter commands
set -x  # Enable bash debug mode
```

## 🚀 Advanced Usage

### Custom Screenshot Workflows

Create custom test scenarios by modifying `integration_test/screenshot_test.dart`:

```dart
testWidgets('Custom Workflow - Data Upload Process', (tester) async {
  // Launch app
  app.main();
  await tester.pumpAndSettle();
  
  // Navigate to specific workflow
  await navigateToDataUpload(tester);
  
  // Capture each step
  await binding.takeScreenshot('upload_01_initial');
  await proceedWithUpload(tester);
  await binding.takeScreenshot('upload_02_progress');
  
  // Handle completion
  await waitForUploadComplete(tester);
  await binding.takeScreenshot('upload_03_complete');
});
```

### Batch Processing

Generate screenshots for multiple configurations:

```bash
# Capture for all modes
for mode in private barcelona gauteng; do
  PARTICIPATION_MODE=$mode ./generate_screenshots.sh --automated
done
```

### CI/CD Integration

Add screenshot generation to your CI pipeline:

```yaml
# .github/workflows/screenshots.yml
- name: Generate Screenshots
  run: |
    ./generate_screenshots.sh --automated
    
- name: Upload Screenshots
  uses: actions/upload-artifact@v3
  with:
    name: app-screenshots
    path: screenshots/
```

## 📚 Related Documentation

- [App Architecture](../docs/ARCHITECTURE.md) - Understanding the app structure
- [Testing Guide](../docs/DEVELOPER_GUIDE.md) - General testing practices
- [CI/CD Setup](../.github/workflows/CI.yml) - Automated testing pipeline

## 🤝 Contributing

When adding new features to the app:

1. Update the integration test to capture new screens
2. Add manual screenshot instructions for new workflows
3. Update this README with new screenshot requirements
4. Regenerate screenshots and verify visual documentation

## 📄 License

This screenshot system is part of the Wellbeing Mapper project and follows the same licensing terms.
