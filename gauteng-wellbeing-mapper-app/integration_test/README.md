# Tablet Screenshot Configuration

This directory contains automated screenshot generation tools for creating Google Play Store tablet screenshots.

## Files Overview

### `tablet_screenshot_test.dart`
- **Purpose:** Flutter integration test for capturing app screenshots
- **Features:** 
  - Automatic device type detection (7-inch vs 10-inch tablet)
  - Smart screenshot naming based on device size
  - Comprehensive app flow coverage
  - Error handling and retry logic

### `run_tablet_screenshots.sh`
- **Purpose:** Simple script for connected devices
- **Usage:** `./screenshots/documentation/scripts/run_tablet_screenshots.sh`
- **Features:**
  - Works with your Samsung Galaxy Tab A (SM A536B)
  - Interactive device selection
  - Automatic screenshot organization
  - Summary report generation

### `generate_tablet_screenshots.sh`
- **Purpose:** Advanced script with emulator support
- **Usage:** `./screenshots/documentation/scripts/generate_tablet_screenshots.sh`
- **Features:**
  - Creates Android Virtual Devices (AVDs) for different tablet sizes
  - Automatic emulator management
  - Multiple device configuration support
  - Professional screenshot optimization

## Quick Start

### ⚠️ Apple Silicon Mac Users (M1/M2/M3)

**Android emulators don't work reliably on Apple Silicon Macs for tablet sizes.** Here are your best options:

#### Option 1: Web-Based Screenshots (Recommended)
```bash
# Generate web version and capture screenshots using browser DevTools
../screenshots/documentation/scripts/generate_web_tablet_screenshots.sh
```
- ✅ **Works immediately** on Apple Silicon
- ✅ **No emulator needed**
- ✅ **Professional quality** results
- ✅ **Free solution**

#### Option 2: Cloud Testing Services
```bash
# See ../CLOUD_TESTING_OPTIONS.md for:
# - Firebase Test Lab (Google) - Free tier available
# - BrowserStack App Live - Real devices via browser
# - AWS Device Farm - Enterprise solution
```

### Using Your Connected Samsung Tablet

1. **Connect your Samsung Galaxy Tab A:**
   ```bash
   # Enable USB debugging on your tablet
   # Connect via USB cable
   adb devices  # Verify connection
   ```

2. **Run the simple script:**
   ```bash
   ./screenshots/documentation/scripts/run_tablet_screenshots.sh
   ```

3. **Select your device** when prompted (device ID: `RZCW90B03FV`)

4. **Screenshots will be saved** to `screenshots/tablet_screenshots/run_YYYYMMDD_HHMMSS/`

### Using Android Emulators

1. **Ensure Android Studio is installed** with SDK tools

2. **Run the advanced script:**
   ```bash
   ./screenshots/documentation/scripts/generate_tablet_screenshots.sh
   ```

3. **Script will create and manage emulators** for:
   - 7-inch tablet (1920x1200 @ 320dpi)
   - 10-inch tablet (2560x1600 @ 320dpi)

## Device Type Detection

The test automatically detects device type based on screen dimensions:

- **Phone:** `logicalSize.shortestSide < 600`
- **7-inch tablet:** `600 <= logicalSize.shortestSide < 900`
- **10-inch tablet:** `logicalSize.shortestSide >= 900`

Screenshots are prefixed accordingly:
- `phone_01_participation_selection.png`
- `7inch_tablet_01_participation_selection.png`
- `10inch_tablet_01_participation_selection.png`

## Screenshot Coverage

The test captures these key app screens:

1. **Participation Selection** - Initial app mode selection
2. **Private Mode** - Main app interface in private mode
3. **Map Interface** - Interactive map with location data
4. **Survey Forms** - Data collection interfaces
5. **Research Modes** - Barcelona/Gauteng research participation
6. **Settings** - App configuration and preferences
7. **Data Visualization** - Charts and analytics (if available)

## Google Play Store Requirements

### 7-inch Tablets
- **Minimum:** 1080p (1920 x 1080)
- **Recommended:** 1920 x 1200 or higher
- **Orientation:** Landscape preferred

### 10-inch Tablets  
- **Minimum:** 1080p (1920 x 1080)
- **Recommended:** 2560 x 1600 or higher
- **Orientation:** Landscape preferred

### General Requirements
- **Format:** PNG or JPEG
- **Max file size:** 8MB per screenshot
- **Quantity:** 2-8 screenshots per device type
- **Content:** Must show actual app features, not placeholder data

## Troubleshooting

### No Screenshots Generated
```bash
# Check if integration_test package is available
flutter pub deps | grep integration_test

# Verify device connection
flutter devices

# Check test output logs
cat screenshots/tablet_screenshots/latest_run/*/test_output.log
```

### Device Not Detected
```bash
# Enable USB debugging on device
# Revoke USB debugging authorizations if needed
# Try different USB cable/port
adb kill-server && adb start-server
```

### Emulator Issues (Apple Silicon Macs)
```bash
# Android emulators don't work well on Apple Silicon for tablets
# Use web-based approach instead:
../screenshots/documentation/scripts/generate_web_tablet_screenshots.sh

# Or try cloud testing services (see ../CLOUD_TESTING_OPTIONS.md):
# - Firebase Test Lab (free tier)
# - BrowserStack (paid, real devices)
# - AWS Device Farm (enterprise)
```

## Advanced Usage

### Custom Device Configuration

Edit the test file to add custom device handling:

```dart
// In tablet_screenshot_test.dart
String getScreenshotPath(String screenName) {
  final size = binding.window.physicalSize;
  final devicePixelRatio = binding.window.devicePixelRatio;
  final logicalSize = size / devicePixelRatio;
  
  // Add custom device detection logic here
  String deviceType = 'custom_tablet';
  return '${deviceType}_${screenName}';
}
```

### Screenshot Optimization

For Play Store optimization:

```bash
# Using ImageMagick (install via brew install imagemagick)
for img in screenshots/*.png; do
  convert "$img" -quality 85 -strip "${img%.png}_optimized.png"
done

# Using built-in macOS tools
for img in screenshots/*.png; do
  sips -s format jpeg -s formatOptions 85 "$img" --out "${img%.png}.jpg"
done
```

## Support

If you encounter issues:

1. **Check the test logs** in the generated `test_output.log`
2. **Verify device compatibility** with `flutter doctor`
3. **Review screenshot file permissions** and storage space
4. **Test with a simple flutter app** first to isolate issues

For device-specific problems with your Samsung Galaxy Tab A, ensure:
- USB debugging is enabled
- Device is authorized for development
- Flutter can detect the device via `flutter devices`
