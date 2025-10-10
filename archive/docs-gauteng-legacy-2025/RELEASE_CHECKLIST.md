# Wellbeing Mapper Release Checklist v0.1.0

## 📱 Pre-Release Verification

### ✅ Code Quality
- [ ] All location permission dialogs updated with consistent messaging
- [ ] Android and iOS location usage descriptions match
- [ ] Export Data menu item moved to correct position
- [ ] Initial survey flow with skip functionality working
- [ ] Background location permissions properly requested

### ✅ Build Status
- [x] Android App Bundle built successfully (41.9MB)
- [x] Android APKs built for all architectures
- [x] iOS app built successfully (69.8MB)
- [x] All dependencies up to date

### ✅ Version Information
- **App Version**: 0.1.0+1
- **Bundle ID**: com.github.activityspacelab.wellbeingmapper.gauteng
- **Min SDK**: Android API 21 / iOS 12.0
- **Target SDK**: Android API 35 / iOS Latest

## 🤖 Android Release (Google Play Store)

### Play Console Setup
- [ ] Create app in Google Play Console
- [ ] App name: "Wellbeing Mapper"
- [ ] Default language: en-ZA (English - South Africa)
- [ ] Category: Health & Fitness
- [ ] Content rating completed

### Store Listing
- [ ] Short description: "A privacy-focused app for mapping your mental wellbeing"
- [ ] Full description written
- [ ] Screenshots uploaded (minimum 2)
- [ ] App icon uploaded (512x512px)
- [ ] Feature graphic created (1024x500px)
- [ ] Privacy policy URL added

### Data Safety (Critical for Health Apps)
- [ ] Location data collection declared
- [ ] Health & fitness data collection declared
- [ ] Personal info collection declared
- [ ] Data encryption in transit/at rest specified
- [ ] Research purpose clearly explained

### Testing Tracks
- [ ] Internal testing set up (up to 100 testers)
- [ ] Closed testing track created for beta (up to 2,000 testers)
- [ ] Beta testers added via email or Google Groups

### Upload Files
- [ ] Upload: `build/app/outputs/bundle/release/app-release.aab`
- [ ] Release notes written for beta

## 🍎 iOS Release (App Store Connect)

### App Store Connect Setup
- [ ] Create app in App Store Connect
- [ ] App name: "Wellbeing Mapper"
- [ ] Primary language: English (South Africa) or English
- [ ] Bundle ID: com.github.activityspacelab.wellbeingmapper.gauteng
- [ ] Category: Health & Fitness

### App Information
- [ ] Subtitle/promotional text
- [ ] Description written
- [ ] Keywords optimized
- [ ] Support URL provided
- [ ] Privacy policy URL added

### Pricing and Availability
- [ ] Set to Free
- [ ] Geographic availability set (focus on South Africa)

### App Privacy
- [ ] Data collection practices declared
- [ ] Location data usage explained
- [ ] Health data usage explained
- [ ] Research context clearly stated

### Build Preparation
- [ ] Open Xcode with project
- [ ] Set Team and Provisioning Profile
- [ ] Archive app in Xcode
- [ ] Upload to App Store Connect via Xcode or Application Loader

### TestFlight Beta
- [ ] Beta app review submitted
- [ ] External testing groups created
- [ ] Beta testers added via email
- [ ] Test information and instructions provided

## 🔗 GitHub Release

### Repository Preparation
- [ ] All changes committed and pushed
- [ ] Version tag created (v0.1.0)
- [ ] Release notes written

### Release Assets
- [ ] Android AAB: `app-release.aab`
- [ ] Android APK (ARM64): `app-arm64-v8a-release.apk`
- [ ] iOS IPA (after Xcode archive): `WellbeingMapper.ipa`
- [ ] Source code zip/tar.gz (auto-generated)

### Release Notes Template
```markdown
# Wellbeing Mapper v0.1.0 - Beta Release

## 🎉 First Beta Release

This is the initial beta release of Wellbeing Mapper for the Gauteng study site.

### ✨ Features
- Privacy-focused location tracking
- Wellbeing survey system with skip functionality
- Wellbeing map visualization
- Wellbeing timeline tracking
- Data export capabilities
- Multiple app modes (Private, App Testing, Research)

### 📱 Downloads
- **Android**: Upload to Google Play Store (Beta)
- **iOS**: Upload to App Store Connect (TestFlight)

### 🔧 Technical Details
- Minimum Android: API 21 (Android 5.0)
- Minimum iOS: 12.0
- Background location tracking
- End-to-end encryption for research data

### 🧪 Beta Testing
This is a beta release for testing purposes. Please report issues via the app's "Report an Issue" feature.
```

## 📋 Post-Release Tasks

### Monitoring
- [ ] Monitor crash reports in Firebase/Crashlytics
- [ ] Track beta tester feedback
- [ ] Monitor app store reviews
- [ ] Check analytics for user behavior

### Documentation
- [ ] Update user documentation
- [ ] Create troubleshooting guides
- [ ] Prepare FAQ for common issues

### Iteration Planning
- [ ] Collect and prioritize feedback
- [ ] Plan next version features
- [ ] Schedule regular beta updates

## 🚨 Important Notes

1. **Location Permissions**: App requests background location - ensure clear explanation in store listings
2. **Health Data**: App collects wellbeing data - compliance with health data regulations required
3. **Research Context**: Clearly explain academic research purpose in all materials
4. **Privacy**: Emphasize local data storage and user control
5. **Geographic Focus**: App is designed for Gauteng study - consider regional marketing

## 📞 Support Contacts

- Technical Issues: [Your email]
- Research Questions: [Research team contact]
- App Store Issues: [Support email]

---

**Release Date**: [Date]
**Release Manager**: [Your name]
**Version**: 0.1.0+1
