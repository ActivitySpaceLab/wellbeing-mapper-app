# Installation Guide

The Gauteng Wellbeing Mapper app is available for both Android and iOS devices. Choose the installation method that best suits your device and preferences.

## Android Installation Options

### Option 1: Google Play Store (Recommended)

The easiest way to install the app on Android devices is through the official Google Play Store.

**Steps:**
1. Open the **Google Play Store** app on your Android device
2. Search for **"Gauteng Wellbeing Mapper"** or visit the direct link: [https://play.google.com/store/apps/details?id=com.github.activityspacelab.wellbeingmapper.gauteng](https://play.google.com/store/apps/details?id=com.github.activityspacelab.wellbeingmapper.gauteng)
3. Tap **"Install"**
4. Wait for the app to download and install automatically
5. Open the app from your home screen or app drawer

**Benefits:**
- Automatic updates
- Verified and secure installation
- Easy to find and install
- Works on all Google-certified Android devices

### Option 2: Manual APK Installation

If you cannot access Google Play Store or prefer to install directly from our releases, you can download the APK file from our GitHub repository.

**When to use this method:**
- Devices without Google Play Services (e.g., some Huawei devices)
- Corporate devices with restricted app store access
- Users who prefer direct installation from source

**Steps:**

#### Step 1: Download the APK
1. Visit our [GitHub Releases page](https://github.com/palmergp/gauteng-wellbeing-mapper-app/releases)
2. Find the latest release (marked with a green "Latest" tag)
3. Download the **Android APK** file. You may see multiple APK files - choose based on your device:

   **Universal APK (Recommended):**
   - `app-production-release.apk` or `gauteng-wellbeing-mapper-production-android.apk`
   - **This works on all Android devices** - choose this if unsure
   - Slightly larger file size but compatible with all devices

   **Architecture-Specific APKs (Advanced Users):**
   If available, you can choose a smaller, device-specific file:
   - `app-arm64-v8a-release.apk` - **Most modern Android devices** (2017+)
   - `app-armeabi-v7a-release.apk` - **Older Android devices** (2012-2017)
   - `app-x86_64-release.apk` - **Emulators and some tablets**

   **How to check your device architecture:**
   - In doubt? Use the universal APK
   - Modern phones (Galaxy S8+, Pixel 2+, OnePlus 5+) use arm64-v8a
   - Older phones typically use armeabi-v7a

#### Step 2: Enable Installation from Unknown Sources
1. Open **Settings** on your Android device
2. Navigate to **Security** or **Privacy & Security**
3. Enable **"Install unknown apps"** or **"Unknown sources"**
4. Select your file manager app and allow it to install apps

*Note: The exact location of this setting varies by Android version and manufacturer.*

#### Step 3: Install the APK
1. Open your **File Manager** or **Downloads** app
2. Locate the downloaded APK file
3. Tap on the APK file
4. Tap **"Install"**
5. Wait for installation to complete
6. Tap **"Open"** to launch the app

### Huawei Devices (Special Instructions)

Huawei devices released after May 2019 typically don't have Google Play Services. We are looking into adding the app to the **Huawei AppGallery** but we have not done so yet. For now:

1. **Use the Manual APK Installation method** described above
2. **For EMUI 10+**: You may need to go to **Settings > Apps > Special access > Install unknown apps** and enable it for your file manager

**Huawei-specific troubleshooting:**
- If you get security warnings, these are normal for APK installations
- Make sure you have at least 100MB of free storage space
- Some Huawei devices require enabling "Developer options" first

## iOS Installation

### TestFlight

Currently, the iOS version is available through Apple's TestFlight program.

**Steps:**
1. **Install TestFlight** from the App Store (if not already installed)
2. Join our program by visiting: [https://testflight.apple.com/join/JXdaTSNU](https://testflight.apple.com/join/JXdaTSNU)
3. Tap **"Accept"** to join. (TestFlight characterizes the app as a Beta version but this is the same production version that we have on Google Play.)
4. **Install** Gauteng Wellbeing Mapper through TestFlight
5. Open the app from your home screen

**Benefits of TestFlight:**
- Access to latest features and improvements
- Direct feedback channel to developers
- Automatic beta updates

**Note about App Store:** We are working on making the app available through the regular App Store. Check back for updates or contact the research team for timeline information.

## Installation Troubleshooting

### Common Issues and Solutions

**Android Issues:**
- **"App not installed" error**: Make sure you have enough storage space (at least 100MB free)
- **"Parse error"**: The APK file may be corrupted - try downloading it again
- **Can't find "Unknown sources"**: Look for "Install unknown apps" in newer Android versions
- **Installation blocked**: Some antivirus apps block APK installation - temporarily disable them during installation

**iOS Issues:**
- **TestFlight link doesn't work**: Make sure you have TestFlight installed first
- **"Unable to install" error**: Check that you have enough storage space and a stable internet connection
- **Beta full**: If you get a message that the beta is full, contact the research team

**General Issues:**
- **App won't open**: Restart your device and try again
- **Crashes on startup**: Make sure your device meets minimum requirements (Android 7.0+ or iOS 12.0+)
- **Can't enter participant code**: Make sure you're typing the code exactly as provided, including correct capitalization

### Getting Help

If you encounter issues not covered in this guide:

1. **Check our documentation**: Visit [our documentation website](https://palmergp.github.io/gauteng-wellbeing-mapper-app/) for additional help
2. **Contact the research team**: Reach out through the contact information provided in your study materials
3. **Report a bug**: Use the feedback option within the app (if accessible) or contact the research team

## Updating the App

### Google Play Store Updates
- Updates are automatic if you have auto-update enabled
- Manual updates: Open Google Play Store → Search for the app → Tap "Update" if available

### APK Updates
- Download the new APK file from our releases page
- Install over the existing app (your settings and data will be preserved)
- No need to uninstall the old version first

### TestFlight Updates
- TestFlight will notify you when new beta versions are available
- Open TestFlight and tap "Update" next to the app

## System Requirements

### Android
- **Minimum Version**: Android 7.0 (API level 24)
- **Recommended**: Android 9.0 or higher
- **Storage**: At least 100MB free space
- **Permissions**: Location access (for core functionality)

### iOS
- **Minimum Version**: iOS 12.0
- **Recommended**: iOS 14.0 or higher
- **Storage**: At least 100MB free space
- **Permissions**: Location access (for core functionality)

## Privacy and Security

All versions of the app (Google Play, APK, and TestFlight) contain the same privacy and security features:
- End-to-end encryption for sensitive data
- Local data storage with encryption
- Minimal data collection
- No third-party tracking

For detailed privacy information, see our [Privacy Policy](PRIVACY.md).
