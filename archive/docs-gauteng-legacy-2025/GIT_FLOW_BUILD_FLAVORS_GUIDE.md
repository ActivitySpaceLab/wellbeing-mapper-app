# Git Flow + Build Flavors Implementation Guide

## Overview

This document explains the new Git Flow + Build Flavors approach implemented for the Gauteng Wellbeing Mapper app. This system separates production releases from beta testing builds using build-time configuration instead of runtime mode switching.

## Key Benefits

✅ **Clean Production Releases**: Production builds only include Private and Research modes  
✅ **Comprehensive Beta Testing**: Beta builds include all modes including App Testing  
✅ **Side-by-side Installation**: Different bundle identifiers allow both versions on same device  
✅ **App Store Ready**: Production builds are clean and ready for store submission  
✅ **Developer Friendly**: Easy switching between flavors during development  

## Branch Strategy (Git Flow)

### Branch Structure
- **`main`** → Production releases (App Store)
- **`develop`** → Integration branch for development  
- **`beta`** → Beta testing releases
- **`feature/*`** → Feature development branches
- **`hotfix/*`** → Production hotfixes

### Workflow
1. Develop features in `feature/*` branches
2. Merge features to `develop` for integration testing
3. Create beta releases from `develop` branch
4. Merge stable `develop` to `main` for production releases
5. Use `hotfix/*` branches for urgent production fixes

## Build Flavors

### Production Flavor
```bash
./build-flavors.sh production android
./build-flavors.sh production ios
```

**Configuration:**
- App Name: "Gauteng Wellbeing Mapper"
- Bundle ID: `com.github.activityspacelab.wellbeingmapper.gauteng`
- Available Modes: Private, Research only
- Build Flag: `APP_FLAVOR=production`

### Beta Flavor
```bash
./build-flavors.sh beta android
./build-flavors.sh beta ios
```

**Configuration:**
- App Name: "Gauteng Wellbeing Mapper Beta"
- Bundle ID: `com.github.activityspacelab.wellbeingmapper.gauteng.beta`
- Available Modes: Private, Research, App Testing
- Build Flag: `APP_FLAVOR=beta`

## File Structure Changes

### Android Configuration
```
android/app/build.gradle
├── flavorDimensions "default"
├── productFlavors {
│   ├── production { ... }
│   └── beta { ... }
└── }
```

### iOS Configuration
```
ios/Runner/
├── Info-Production.plist  (Production configuration)
├── Info-Beta.plist        (Beta configuration)
└── Info.plist            (Active configuration, copied during build)
```

### Flutter Code
```
lib/services/app_mode_service.dart
├── appFlavor detection via String.fromEnvironment('APP_FLAVOR')
├── getAvailableModes() → Returns modes based on build flavor
└── Build-time mode validation
```

## Usage Instructions

### 1. Building Different Flavors

**Build Production APK:**
```bash
cd gauteng-wellbeing-mapper-app
./build-flavors.sh production android
```

**Build Beta iOS:**
```bash
cd gauteng-wellbeing-mapper-app
./build-flavors.sh beta ios
```

**Build All Platforms:**
```bash
cd gauteng-wellbeing-mapper-app
./build-flavors.sh production all
./build-flavors.sh beta all
```

### 2. Development Testing

**Run in Production Mode:**
```bash
flutter run --dart-define=APP_FLAVOR=production
```

**Run in Beta Mode:**
```bash
flutter run --dart-define=APP_FLAVOR=beta
```

### 3. Release Process

**Beta Release Process:**
1. Ensure `develop` branch is stable
2. Merge `develop` to `beta` branch
3. Build beta flavor: `./build-flavors.sh beta all`
4. Distribute beta build to testers
5. Collect feedback and fix issues in `develop`

**Production Release Process:**
1. Ensure `beta` testing is complete
2. Merge `develop` to `main` branch
3. Build production flavor: `./build-flavors.sh production all`
4. Submit to App Store / Play Store
5. Tag release: `git tag v1.x.x`

## App Mode Behavior

### Production Builds (`APP_FLAVOR=production`)
- **Available Modes**: Private, Research
- **Hidden Features**: App Testing mode completely unavailable
- **UI**: Clean interface without beta/testing indicators
- **Data**: Only production-ready data collection modes

### Beta Builds (`APP_FLAVOR=beta`)
- **Available Modes**: Private, Research, App Testing
- **Extended Features**: Full testing capabilities available
- **UI**: "Beta" branding in app name and descriptions
- **Data**: Includes test data collection modes

## Code Implementation Details

### AppModeService Changes
```dart
// Build flavor detection
static const String appFlavor = String.fromEnvironment('APP_FLAVOR', defaultValue: 'production');

// Flavor-based mode availability
static List<AppMode> getAvailableModes() {
  if (isBetaBuild) {
    return [AppMode.private, AppMode.research, AppMode.appTesting];
  } else {
    return [AppMode.private, AppMode.research];
  }
}
```

### Validation
- Mode switching validates against available modes for current flavor
- Stored modes are validated on app startup
- Invalid modes automatically fallback to Private mode

## Deployment Strategy

### App Store Submission
1. Use **production** flavor builds only
2. Ensure `main` branch is used for production builds
3. Test production build thoroughly before submission
4. Production builds will not show App Testing mode

### Beta Testing Distribution
1. Use **beta** flavor builds for all testing
2. Beta builds can be distributed via TestFlight, Firebase App Distribution, etc.
3. Beta and production apps can coexist on same device
4. Beta builds include full testing capabilities

## Troubleshooting

### Common Issues

**Wrong mode available in build:**
- Check `APP_FLAVOR` dart-define parameter
- Verify correct build script usage
- Check AppModeService.appFlavor value

**iOS build using wrong Info.plist:**
- Ensure build script is copying correct Info.plist file
- Check that Info-Production.plist and Info-Beta.plist exist
- Verify iOS build process in build-flavors.sh

**Android build wrong app name/ID:**
- Check productFlavors configuration in android/app/build.gradle
- Verify flavor parameter matches (production/beta)
- Ensure gradle build is using correct flavor

### Debug Commands

**Check current flavor in app:**
```dart
print('Current app flavor: ${AppModeService.appFlavor}');
print('Is beta build: ${AppModeService.isBetaBuild}');
print('Available modes: ${AppModeService.getAvailableModes()}');
```

**Verify build configuration:**
```bash
# Check Android APK name
ls build/app/outputs/flutter-apk/

# Check Android bundle name  
ls build/app/outputs/bundle/

# Check current iOS Info.plist
cat ios/Runner/Info.plist | grep -A 1 CFBundleDisplayName
```

## Migration Notes

### From Previous System
- **Runtime mode switching** → **Build-time flavor configuration**
- **Single app with mode selection** → **Separate production/beta apps**
- **Hardcoded beta phase flag** → **Dynamic flavor detection**
- **Manual mode management** → **Automatic mode availability**

### Benefits of New System
1. **Cleaner production releases** without testing features
2. **Proper beta testing** with full feature sets
3. **App Store compliance** with clear production builds
4. **Side-by-side testing** of production and beta versions
5. **Automated flavor validation** prevents incorrect mode access

## Future Enhancements

### Planned Improvements
- [ ] Automated CI/CD pipeline for flavor builds
- [ ] App Store Connect API integration for automated uploads
- [ ] Firebase App Distribution integration for beta releases
- [ ] Automated testing on different flavors
- [ ] Release notes generation based on Git commits

### Development Workflow Integration
- [ ] VS Code tasks for quick flavor switching
- [ ] Git hooks for automatic flavor validation
- [ ] Documentation website updates for release process
- [ ] Team notification system for new releases

---

**Last Updated**: January 2025  
**Version**: 1.0  
**Author**: GitHub Copilot (Implementation Guide)
