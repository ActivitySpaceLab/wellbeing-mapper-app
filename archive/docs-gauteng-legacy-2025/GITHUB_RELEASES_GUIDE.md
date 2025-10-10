# GitHub Releases with Git Flow + Build Flavors

This document explains how our GitHub Releases system integrates with the Git Flow + Build Flavors approach for automated beta and production releases.

## 🏗️ Release Workflow Overview

We now have **two separate GitHub Actions workflows** for different types of releases:

### 1. Beta Releases (`CD-deploy-beta-releases.yml`)
- **Trigger**: Git tags with `-beta` suffix (e.g., `v1.2.0-beta1`, `v1.2.0-beta2`)
- **Build Flavor**: Beta flavor with beta app configurations
- **Release Type**: GitHub prerelease (marked as beta)
- **Purpose**: Testing, feedback collection, internal distribution

### 2. Production Releases (`CD-deploy-github-releases.yml`)
- **Trigger**: Git tags without `-beta` suffix (e.g., `v1.2.0`, `v2.0.0`)
- **Build Flavor**: Production flavor with production app configurations
- **Release Type**: GitHub stable release
- **Purpose**: Official public releases, app store distribution

## 🔄 Git Flow Integration

This system perfectly integrates with our Git Flow branching strategy:

### Development Flow
```
develop branch → feature/hotfix branches → develop
                     ↓
               release/1.2.0 branch
                     ↓
              main branch (production)
```

### Release Tagging Strategy
```
1. Create release branch: release/1.2.0
2. Tag beta releases: v1.2.0-beta1, v1.2.0-beta2, v1.2.0-beta3
3. Merge to main and tag production: v1.2.0
```

## 📱 Build Flavors Integration

Each workflow uses our build flavors system:

### Beta Releases
- **Android**: Different package name (`com.app.gauteng_wellbeing_mapper_app.beta`)
- **iOS**: Different bundle ID (`com.app.gautengWellbeingMapperApp.beta`)
- **App Name**: "Wellbeing Mapper Beta"
- **App Icon**: Beta variant with badge
- **Features**: All features enabled for testing

### Production Releases
- **Android**: Production package name (`com.app.gauteng_wellbeing_mapper_app`)
- **iOS**: Production bundle ID (`com.app.gautengWellbeingMapperApp`)
- **App Name**: "Wellbeing Mapper"
- **App Icon**: Clean production icon
- **Features**: Stable, tested features only

## 🚀 How to Create Releases

### Creating a Beta Release

1. **Prepare Release Branch**:
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b release/1.2.0
   ```

2. **Update Version** (if needed):
   ```bash
   # Update pubspec.yaml version to 1.2.0+X
   # Commit version changes
   git add pubspec.yaml
   git commit -m "chore: bump version to 1.2.0 for release"
   ```

3. **Create Beta Tags**:
   ```bash
   # Create and push beta tags
   git tag v1.2.0-beta1
   git push origin v1.2.0-beta1
   
   # After fixes/changes
   git tag v1.2.0-beta2
   git push origin v1.2.0-beta2
   ```

4. **Automated Beta Build**: GitHub Actions automatically:
   - Builds beta flavors for Android and iOS
   - Creates GitHub prerelease with beta APKs
   - Includes comprehensive beta testing instructions

### Creating a Production Release

1. **Finalize Release Branch**:
   ```bash
   # After beta testing is complete
   git checkout release/1.2.0
   # Make final adjustments if needed
   ```

2. **Merge to Main**:
   ```bash
   git checkout main
   git merge release/1.2.0
   ```

3. **Create Production Tag**:
   ```bash
   git tag v1.2.0
   git push origin v1.2.0
   ```

4. **Automated Production Build**: GitHub Actions automatically:
   - Builds production flavors for Android and iOS
   - Creates GitHub stable release with production APKs
   - Includes official release documentation

### Post-Release Cleanup
```bash
# Merge release back to develop
git checkout develop
git merge release/1.2.0

# Clean up release branch
git branch -d release/1.2.0
git push origin --delete release/1.2.0
```

## 📦 Release Artifacts

### Beta Release Artifacts
- Multiple `app-beta-*.apk` files (Android - different architectures automatically optimized)
- `app-beta-release.aab` (Android App Bundle)
- `wellbeing-mapper-beta-ios.zip` (iOS app archive)
- Source code archives (automatic)

### Production Release Artifacts
- Multiple `app-production-*.apk` files (Android - different architectures automatically optimized)
- `app-production-release.aab` (Android App Bundle for Play Store)
- `wellbeing-mapper-production-ios.zip` (iOS app archive)
- Source code archives (automatic)

## 🔍 Quality Assurance

Both workflows include comprehensive quality checks:

### Automated Validation
- ✅ **Version Consistency**: Git tag matches pubspec.yaml version
- ✅ **Code Analysis**: Flutter analyze for code quality
- ✅ **Test Execution**: Full test suite execution
- ✅ **iOS Entitlements**: Location permission validation
- ✅ **Build Verification**: Successful flavor-specific builds

### Release Type Validation
- **Beta Workflow**: Only accepts tags with `-beta` suffix
- **Production Workflow**: Rejects tags with `-beta` suffix
- **Prevents Cross-contamination**: Ensures correct workflow execution

## 📖 Release Documentation

### Beta Releases Include
- 🧪 Beta testing instructions and expectations
- 📱 Installation guides for all platforms
- 🔒 Privacy and data handling for testing
- 💡 How to provide effective feedback
- ⚠️ Beta limitations and warnings

### Production Releases Include
- 🚀 Official release announcement
- 📱 Complete installation instructions
- 🔒 Privacy and security information
- 🆚 Production vs beta comparison
- 📞 Official support contact information

## 🛠️ Maintenance and Troubleshooting

### Common Issues

**Version Mismatch Error**:
- Ensure pubspec.yaml version matches git tag (without beta suffix)
- Update version before creating tags

**Build Flavor Errors**:
- Verify build-flavors.sh script is executable
- Check Android and iOS configurations are properly set up

**Entitlements Validation Failure**:
- Ensure iOS entitlements file exists and is linked
- Verify all required location permission keys are present

**Artifact Path Issues**:
- Confirm flavor-specific build output paths match workflow expectations
- Check that build-flavors.sh generates expected artifact names

### Workflow Monitoring

Monitor releases in:
- **GitHub Actions**: Check workflow execution status
- **GitHub Releases**: Verify artifacts and release notes
- **Build Logs**: Review detailed build output for issues

## 🔄 Future Enhancements

Potential improvements to consider:
- **Automated Changelog**: Generate release notes from commit messages
- **Test Device Matrix**: Test on multiple Android versions/devices
- **Performance Benchmarks**: Include app performance metrics
- **Security Scanning**: Automated vulnerability scanning
- **App Store Integration**: Direct upload to app stores

## 📚 Related Documentation

- [Git Flow + Build Flavors Guide](GIT_FLOW_BUILD_FLAVORS_GUIDE.md)
- [Beta Testing Guide](BETA_TESTING_GUIDE.md)
- [Release Checklist](RELEASE_CHECKLIST.md)
- [Developer Guide](DEVELOPER_GUIDE.md)
