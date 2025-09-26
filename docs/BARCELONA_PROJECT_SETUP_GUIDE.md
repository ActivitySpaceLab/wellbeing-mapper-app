# Barcelona Wellbeing Mapper - Project Setup Guide

## Project Structure and Setup Strategy

### Current Gauteng Structure (Causing Issues)
```
gauteng-wellbeing-mapper-app/           # Outer directory
├── gauteng-wellbeing-mapper-app/       # Flutter app directory (confusing nesting)
│   ├── lib/
│   ├── pubspec.yaml
│   └── assets/
├── app_screenshots/                    # Gets accidentally bundled into app
├── data_analysis_toolkit/
├── archive/
└── README.md
```

**Problems:**
- 🚫 Confusing nested directory structure
- 🚫 Screenshots accidentally bundled into app (doubled app size)
- 🚫 Non-standard Flutter project layout
- 🚫 Harder for development tools and CI/CD

### Recommended Barcelona Structure (Industry Standard)
```
barcelona-wellbeing-mapper-app/         # Flutter app root
├── lib/                               # Flutter source code
├── pubspec.yaml                       # Dependencies and config
├── assets/                            # App assets (bundled)
├── android/                           # Android platform code
├── ios/                               # iOS platform code
├── docs/                              # Documentation
├── scripts/                           # Data management scripts
├── project_assets/                    # Non-app files (NOT bundled)
│   ├── screenshots/
│   ├── app_store_assets/
│   └── design_mockups/
├── .github/                           # GitHub workflows
├── README.md
└── .gitignore
```

**Benefits:**
- ✅ Standard Flutter structure - tools expect this
- ✅ No asset bundling issues - project_assets/ won't be included in builds
- ✅ Better IDE support - VS Code, Android Studio work correctly
- ✅ Simpler deployment - CI/CD tools understand this structure
- ✅ Cleaner Git operations - easier to manage .gitignore rules

## Project Creation Strategy

### Recommended: Option 1 - Fork Gauteng Project

**Why fork gauteng-wellbeing-mapper-app (not space_mapper):**
1. 🔄 **Bidirectional sync capability** - Changes can flow both ways
2. 📈 **Most mature codebase** - Has all recent fixes (location persistence, real-time updates, iOS permissions)
3. 🎯 **Shared improvements** - Bug fixes benefit both projects
4. 🔧 **Easy customization** - Modify Barcelona while maintaining merge capability

### Setup Commands

```bash
# 1. Fork gauteng-wellbeing-mapper-app on GitHub as barcelona-wellbeing-mapper-app

# 2. Clone and restructure
git clone https://github.com/yourusername/barcelona-wellbeing-mapper-app.git
cd barcelona-wellbeing-mapper-app

# 3. Move Flutter app contents to root (fix structure)
mv gauteng-wellbeing-mapper-app/* .
mv gauteng-wellbeing-mapper-app/.* . 2>/dev/null || true
rmdir gauteng-wellbeing-mapper-app

# 4. Create proper directory structure
mkdir -p project_assets/{screenshots,app_store_assets,design_mockups}
mkdir -p scripts
mkdir -p docs

# 5. Move non-app files to proper locations
mv app_screenshots/ project_assets/screenshots/
mv data_analysis_toolkit/ scripts/
mv archive/ project_assets/archive/

# 6. Set up multiple remotes for syncing
git remote add gauteng https://github.com/yourusername/gauteng-wellbeing-mapper-app.git
git remote add space_mapper https://github.com/yourusername/space_mapper.git

# 7. Set up proper .gitignore (exclude build artifacts, keep source assets)
# Note: project_assets/, scripts/, and docs/ should be tracked in Git
# Flutter won't bundle them because they're not in pubspec.yaml assets section
```

## Key Changes Needed for Barcelona

### 1. App Identity & Configuration
```bash
# Update package names
# Android: android/app/build.gradle
applicationId "com.yourdomain.barcelonawellbeingmapper"

# iOS: ios/Runner.xcodeproj/project.pbxproj
PRODUCT_BUNDLE_IDENTIFIER = com.yourdomain.barcelonawellbeingmapper;

# App names
# pubspec.yaml
name: barcelona_wellbeing_mapper
description: Barcelona wellbeing mapping research app

# Android flavors: android/app/build.gradle
productFlavors {
    production {
        applicationId "com.yourdomain.barcelonawellbeingmapper"
        resValue "string", "app_name", "Barcelona Wellbeing Mapper"
    }
    beta {
        applicationId "com.yourdomain.barcelonawellbeingmapper.beta"
        resValue "string", "app_name", "Barcelona Wellbeing Mapper Beta"
    }
}
```

### 2. Server Integration (Major Change)
- **Remove**: `lib/services/qualtrics_service.dart`
- **Create**: `lib/services/barcelona_server_service.dart`
- **Update**: Survey submission logic in survey screens
- **Modify**: Data sync endpoints and authentication

### 3. Configuration Files
```dart
// lib/util/env.dart - Update endpoints
class ENV {
  static const String API_BASE_URL = "https://your-barcelona-server.com/api";
  static const String DEFAULT_SAMPLE_ID = "barcelona_study_2025";
  // Remove Qualtrics URLs
}
```

### 4. Asset Bundling Fix
```yaml
# pubspec.yaml - Be explicit about bundled assets
flutter:
  assets:
    - assets/images/        # Only include specific directories
    - lang/                 # Don't use wildcards
    
# Note: project_assets/ will NOT be bundled (outside app structure)
```

### 5. Asset Bundling Strategy
**Key Point**: Keep `docs/`, `scripts/`, and `project_assets/` in Git, but prevent Flutter from bundling them.

**How it works**:
- ✅ Git tracks: `docs/`, `scripts/`, `project_assets/` (needed for development)
- ✅ Flutter bundles: Only what's in `pubspec.yaml` → `assets:` section
- ✅ .gitignore excludes: Build artifacts (`.apk`, `build/`, etc.)

```gitignore
# Build outputs and artifacts (not source assets)
build_outputs/
*.apk
*.aab
*.ipa
coverage/

# Standard Flutter build ignores  
.dart_tool/
.packages
build/
ios/Flutter/Generated.xcconfig
android/.gradle/
```

## Workflow Benefits

### Syncing Between Projects
```bash
# Pull improvements from Gauteng version
git pull gauteng main

# Push improvements back to Gauteng
git push gauteng feature/shared-improvements

# Eventually contribute back to space_mapper
git push space_mapper feature/location-fixes

# Cherry-pick specific features
git cherry-pick <commit-hash>
```

### Development Workflow
1. **Develop in Barcelona** with proper structure
2. **Share bug fixes** back to Gauteng via Git
3. **Pull new features** from Gauteng as needed
4. **Contribute improvements** to space_mapper when ready

## Action Plan

### Phase 1: Project Setup
1. ✅ Fork gauteng-wellbeing-mapper-app on GitHub
2. ✅ Clone and restructure directories
3. ✅ Update app identifiers and branding
4. ✅ Set up proper .gitignore rules

### Phase 2: Core Changes
1. 🔄 Remove Qualtrics integration
2. 🔄 Implement Barcelona server sync
3. 🔄 Update configuration endpoints
4. 🔄 Test core functionality

### Phase 3: Barcelona Customization
1. 🔄 Configure Barcelona-specific maps/tiles
2. 🔄 Update survey content and flow
3. 🔄 Set up Barcelona research protocols
4. 🔄 Deploy and test

## Why This Approach Works

### For Gauteng Project:
- ✅ **Keep existing structure** - don't risk breaking stable deployment
- ✅ **Receive improvements** from Barcelona development
- ✅ **Maintain current workflows** without disruption

### For Barcelona Project:
- ✅ **Start with proven codebase** - all recent fixes included
- ✅ **Use proper structure** - better development experience
- ✅ **Easy customization** - remove Qualtrics, add server sync
- ✅ **Future-proof** - template for additional city projects

### For Future Projects:
- ✅ **Barcelona becomes template** with proper structure
- ✅ **Shared improvements** across all city projects
- ✅ **Easier maintenance** with standardized setup

## Troubleshooting

### If Asset Bundling Issues Persist:
```bash
# Check what's being bundled
flutter analyze
flutter assemble --output=build/app/outputs

# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --analyze-size
```

### If Git Sync Issues:
```bash
# Reset to clean state
git fetch --all
git reset --hard origin/main

# Resolve merge conflicts
git merge gauteng/main
# Fix conflicts in IDE
git add .
git commit -m "Merge improvements from Gauteng"
```

---

**Note**: This guide assumes you have Git, Flutter, and development environment already set up. Start with Phase 1 and test each phase before proceeding to the next.