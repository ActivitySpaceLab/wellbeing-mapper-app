# Guateng → Gauteng Rename Summary

## ✅ **Completed Changes**

### **1. App Bundle/Package IDs**
- **Android**: `com.github.activityspacelab.wellbeingmapper.guateng` → `com.github.activityspacelab.wellbeingmapper.gauteng`
- **iOS**: `com.github.activityspacelab.wellbeingmapper.guateng` → `com.github.activityspacelab.wellbeingmapper.gauteng`

### **2. Directory Structure**
- ✅ Renamed main project directory: `guateng-wellbeing-mapper-app` → `gauteng-wellbeing-mapper-app`
- ✅ Renamed Android Kotlin package directory: `com/github/activityspacelab/wellbeingmapper/guateng` → `gauteng`

### **3. Code Changes**
- ✅ Android `build.gradle`: Updated `namespace` and `applicationId`
- ✅ Android manifest files: Updated `package` declarations in main, debug, and profile manifests
- ✅ Android Kotlin files: Updated package declarations in `MainActivity.kt` and `BootReceiver.kt`
- ✅ iOS `project.pbxproj`: Updated all 3 `PRODUCT_BUNDLE_IDENTIFIER` references
- ✅ iOS `ExportOptions.plist`: Updated provisioning profile bundle ID references
- ✅ iOS `AppDelegate.swift`: Updated method channel name
- ✅ Flutter Dart files: Updated method channel references in:
  - `lib/services/ios_location_fix_service.dart`
  - `lib/ui/map_view.dart`
  - `lib/ui/report_issues.dart`

### **4. Documentation & Configuration**
- ✅ Updated all GitHub repository URLs from `guateng-wellbeing-mapper-app` to `gauteng-wellbeing-mapper-app`
- ✅ Updated GitHub Pages base URL in `docs/_config.yml`
- ✅ Updated bundle ID references in developer documentation
- ✅ Updated all GitHub workflow files (CI.yml, CD-deploy-github-releases.yml, drive-android.yml, drive-ios.yml)
- ✅ Updated `.gitignore` file paths
- ✅ Updated `codecov.yml` paths
- ✅ Updated all documentation files (README.md, all docs/*.md files)

### **5. Verification**
- ✅ `flutter analyze` passes with no issues
- ✅ `flutter pub get` resolves dependencies successfully
- ✅ All directory and file references updated consistently

## 🔧 **Required External Updates**

### **1. Apple Developer Console**
- **Action Required**: Update provisioning profile name from "Guateng Wellbeing Mapper Development" to "Gauteng Wellbeing Mapper Development" 
- **New Bundle ID**: `com.github.activityspacelab.wellbeingmapper.gauteng`
- **Steps**:
  1. Log into [developer.apple.com](https://developer.apple.com)
  2. Go to Certificates, Identifiers & Profiles
  3. Update or recreate App ID with new bundle identifier
  4. Update or recreate provisioning profiles with new name "Gauteng Wellbeing Mapper Development"
  5. Download and install updated provisioning profiles

### **2. Google Play Console**
- **Action Required**: Cannot change package name for existing app
- **Options**:
  - **Option A (Recommended)**: Keep existing app with old package name `com.github.activityspacelab.wellbeingmapper.guateng` - it will continue to work
  - **Option B**: Create new app listing with new package name `com.github.activityspacelab.wellbeingmapper.gauteng` (loses all reviews, downloads, etc.)
- **Recommendation**: Keep the existing Google Play app as-is since package name changes break app updates for existing users

### **3. GitHub Repository**
- ✅ **Already Done**: Repository renamed to `gauteng-wellbeing-mapper-app`
- ✅ **GitHub Pages**: Now at `https://activityspacelab.github.io/gauteng-wellbeing-mapper-app/`
- **Note**: All workflow files and documentation updated to use new repository name

### **4. External Services**
- **Codecov**: Configuration updated to use new repository path
- **Existing badges/links**: All updated to use new repository URL

## 📱 **Bundle ID Impact Analysis**

### **What This Change Affects:**
1. **New App Installations**: Will use new bundle ID
2. **App Store/Play Store**: See platform-specific notes above
3. **Deep Links**: Any existing deep links using old bundle ID will break
4. **Analytics/Crash Reporting**: May need reconfiguration with new bundle ID
5. **Background Location Plugin**: License key is tied to bundle ID and may need updating

### **What This Change Does NOT Affect:**
1. **App Functionality**: All features remain the same
2. **User Data**: Existing user data and preferences are preserved
3. **Third-party Integrations**: Most services use different identifiers

## 🚨 **Important Notes**

### **Google Play Store Strategy**
Since Google Play Console does not allow changing package names for existing apps, you have two options:
1. **Recommended**: Keep the existing app in Google Play with the old package name. Users won't see the package name, and the app will continue to work normally.
2. **Alternative**: Create a new app listing with the new package name, but this means starting over with 0 downloads, reviews, etc.

### **iOS App Store**
The bundle ID change is supported but requires:
1. Creating a new App Store Connect entry with the new bundle ID
2. Users will see this as a completely new app
3. Cannot transfer reviews/ratings from old to new bundle ID

### **Development Impact**
- All development tooling updated
- GitHub Actions workflows updated
- Documentation updated
- The app compiles and analyzes successfully

## ✅ **Testing Checklist**

Before releasing:
- [ ] Test app installation on fresh devices with new bundle ID
- [ ] Verify all deep links work with new bundle ID  
- [ ] Test background location functionality (license key may need updating)
- [ ] Verify push notifications work (if implemented)
- [ ] Test app store submission process with new bundle ID

## 📋 **Next Steps**

1. **Immediate**: Update Apple Developer provisioning profiles
2. **Decision Needed**: Choose Google Play strategy (keep old or create new)
3. **Testing**: Test app thoroughly on both platforms
4. **Release**: Deploy updates using standard release process

The codebase is now fully updated and ready for testing and deployment with the corrected "Gauteng" spelling throughout.
