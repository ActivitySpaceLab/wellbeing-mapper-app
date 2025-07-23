# Wellbeing Mapper Documentation

Welcome to the Wellbeing Mapper developer documentation. This documentation is designed to help new developers quickly understand and start working with the Wellbeing Mapper codebase.

## What is Wellbeing Mapper?

Wellbeing Mapper is a privacy-focused mobile application built with Flutter that allows users to map their mental wellbeing in environmental & climate context. The app enables correlation of location data with mental health indicators to better understand how environmental and climate factors impact psychological wellbeing.

### Planet4Health Case Study

This application is part of the [Planet4Health project](https://planet4health.eu), specifically the case study on "[Mental wellbeing in environmental & climate context](https://planet4health.eu/mental-wellbeing-in-environmental-climate-context/)". The research addresses the growing recognition that environmental and climate changes contribute to rising mental health and psychosocial issues, including climate-related psychological distress.

### Research Objectives

The case study aims to:
- Collect and analyze mental wellbeing data alongside environmental data
- Develop comprehensive understanding of mental health impacts from environmental factors  
- Create integrated risk monitoring systems
- Map environmental hotspots affecting mental health
- Provide solutions for better preparedness and response capacity

## Prerequisites

### Flutter & Dart Version Requirements
This project requires **Flutter 3.27.1** with **Dart 3.6.0**. Due to dependency constraints, the app will only compile with these specific versions.

#### Using FVM (Recommended)
We strongly recommend using [FVM (Flutter Version Management)](https://fvm.app/) to manage Flutter versions:

```bash
# Install FVM if you haven't already
dart pub global activate fvm

# Use the correct Flutter version for this project
fvm use 3.27.1

# Verify the version
fvm flutter --version
```

#### Without FVM
Ensure you have Flutter 3.27.1 installed. Check your version with:
```bash
flutter --version
# Should show: Flutter 3.27.1 • Dart 3.6.0
```

If you have a different version, install Flutter 3.27.1 from the [Flutter releases page](https://docs.flutter.dev/release/archive).

## Documentation Structure

### 📚 Core Documentation

1. **[Developer Guide](DEVELOPER_GUIDE.md)** - Start here! Comprehensive guide covering:
   - Architecture overview
   - Core components explanation
   - File structure walkthrough
   - Key features breakdown
   - Getting started instructions
   - Development workflow
   - Testing approach

2. **[Architecture Documentation](ARCHITECTURE.md)** - Deep dive into the system design:
   - Layered architecture explanation
   - Component interaction patterns
   - Data flow architecture
   - Security architecture
   - Performance considerations
   - Future scalability planning

3. **[API Reference](API_REFERENCE.md)** - Complete API documentation:
   - Core class APIs
   - Database schemas and operations
   - UI component APIs
   - Background processing APIs
   - Utility functions
   - Error handling patterns

4. **[Flow Charts](FLOW_CHARTS.md)** - Visual representation of application flows:
   - Main application flow
   - Location tracking flow
   - Project participation flow
   - Background processing flow
   - Data synchronization flow
   - Error handling flow

## Quick Start for New Developers

### 1. First Time Setup
```bash
# Ensure you're using Flutter 3.27.1 with Dart 3.6.0
# If using FVM:
fvm use 3.27.1
fvm flutter --version

# Clone the repository
git clone [repository-url]
cd wellbeing-mapper-app/wellbeing-mapper-app

# Install dependencies (use fvm if you're using FVM)
fvm flutter pub get
# OR without FVM:
# flutter pub get

# Run the app (use fvm if you're using FVM)
fvm flutter run
# OR without FVM:
# flutter run
```

### 2. Understanding the Codebase
1. **Start with the [Developer Guide](DEVELOPER_GUIDE.md)** to get an overview
2. **Review the [Architecture](ARCHITECTURE.md)** to understand the system design
3. **Use the [Flow Charts](FLOW_CHARTS.md)** to visualize how components interact
4. **Reference the [API Documentation](API_REFERENCE.md)** when working with specific classes

### 3. Key Areas to Explore

#### Core Application Flow
- `main.dart` - Application entry point
- `ui/home_view.dart` - Main screen with location controls
- `ui/map_view.dart` - Interactive map display

#### Location Tracking
- `models/custom_locations.dart` - Location data management
- Background geolocation integration
- Database storage patterns

#### Project Participation
- `ui/project_*.dart` files - Project management interfaces
- `models/project.dart` - Project data structures
- QR code scanning and survey integration

## Architecture at a Glance

```
┌─────────────────────────────────────────┐
│                 UI Layer                │
│     HomeView, MapView, ProjectViews     │
├─────────────────────────────────────────┤
│              Business Logic             │
│   LocationManager, ProjectManager       │
├─────────────────────────────────────────┤
│               Data Layer                │
│    SQLite Databases, Models, Cache     │
├─────────────────────────────────────────┤
│             Platform Layer              │
│  Background Geolocation, Native APIs   │
└─────────────────────────────────────────┘
```

## Key Technologies

- **Flutter 3.27.1**: Cross-platform mobile framework
- **Dart 3.6.0**: Programming language
- **SQLite**: Local data storage
- **Background Geolocation**: Continuous location tracking
- **WebView**: Survey and external content integration
- **Mermaid**: Flow chart diagrams (in documentation)

## Core Features

### 🗺️ Location Tracking
- **Privacy-first**: All data stored locally by default
- **Battery optimized**: Smart sampling and motion detection
- **Background operation**: Continues tracking when app is closed
- **User control**: Easy enable/disable with clear status indicators

### 🔬 Citizen Science Participation
- **QR code enrollment**: Easy project joining
- **Selective sharing**: Users choose what data to share
- **Survey integration**: Seamless connection to research surveys
- **Multiple projects**: Support for simultaneous participation

### 📱 User Experience
- **Interactive map**: Real-time location visualization
- **Location history**: Chronological list with details
- **Multi-language**: Internationalization support
- **Offline capability**: Works without constant internet connection

## Development Workflow

### Adding New Features
1. **Understand the request** - Review requirements and existing patterns
2. **Design the data model** - Define data structures in `models/`
3. **Implement database layer** - Add operations in `db/`
4. **Create business logic** - Implement logic in service classes
5. **Build UI components** - Create interfaces in `ui/`
6. **Test thoroughly** - Unit, widget, and integration tests
7. **Update documentation** - Keep docs current with changes

### Working with Location Features
```dart
// Example: Processing new location data
class LocationService {
  static Future<void> handleNewLocation(bg.Location rawLocation) async {
    // 1. Create CustomLocation object
    CustomLocation location = await CustomLocation.createCustomLocation(rawLocation);
    
    // 2. Store in database
    await CustomLocationsManager.storeLocation(location);
    
    // 3. Update UI
    EventBus.fire('location_updated', location);
    
    // 4. Check project requirements
    await ProjectManager.checkLocationSharing(location);
  }
}
```

### Working with Projects
```dart
// Example: Adding new project integration
class ProjectIntegration {
  static Future<void> participateInProject(Project project) async {
    // 1. Store project information
    await ProjectDatabase.instance.createProject(project);
    
    // 2. Generate survey URL with user data
    String surveyUrl = project.generateSurveyUrl(userUUID);
    
    // 3. Launch WebView for survey
    Navigator.pushNamed(context, '/webview', arguments: {
      'url': surveyUrl,
      'project': project
    });
  }
}
```

## Testing Strategy

### Unit Tests (`test/unit/`)
- Individual class functionality
- Business logic validation
- Data model operations
- Utility function testing

### Widget Tests (`test/widget/`)
- UI component behavior
- User interaction testing
- State management verification

### Integration Tests (`integration_test/`)
- End-to-end workflows
- Location tracking scenarios
- Project participation flows
- Cross-component integration

### Running Tests
```bash
# All tests (use fvm if you're using FVM)
fvm flutter test
# OR without FVM:
# flutter test

# Specific test categories
fvm flutter test test/unit/
fvm flutter test test/widget/
fvm flutter test integration_test/
```

## Contributing Guidelines

### Before You Start
1. **Read this documentation** to understand the system
2. **Set up your development environment** with Flutter and dependencies
3. **Run existing tests** to ensure your setup is correct
4. **Explore the codebase** using the guides provided

### Making Changes
1. **Create a feature branch** from the main development branch
2. **Follow existing code patterns** and architectural decisions
3. **Write tests** for new functionality
4. **Update documentation** if you change APIs or behavior
5. **Run all tests** before submitting: `fvm flutter analyze && fvm flutter test` (or without `fvm` prefix if not using FVM)

### Pull Request Process
1. **Describe your changes** clearly in the PR description
2. **Reference any issues** that your changes address
3. **Include test results** and verify CI passes
4. **Request review** from maintainers
5. **Address feedback** promptly and thoroughly

## Troubleshooting Common Issues

### Version Issues
- **Flutter Version**: Must be exactly 3.27.1 with Dart 3.6.0
- **FVM Users**: Run `fvm use 3.27.1` in the project directory
- **Non-FVM Users**: Ensure `flutter --version` shows Flutter 3.27.1 • Dart 3.6.0
- **Dependency Conflicts**: These specific versions are required due to dependency constraints

### Build Issues
- Ensure Flutter 3.27.1 and Dart 3.6.0 are being used
- Run `fvm flutter clean && fvm flutter pub get` (or without `fvm` if not using FVM)
- Check platform-specific configurations (Android/iOS)
- Verify all required dependencies are compatible with Flutter 3.27.1

### Database Issues
- Check database migration scripts
- Verify data model compatibility
- Look for database lock/corruption issues
- Review transaction handling

## Support and Resources

### Internal Resources
- **Codebase**: Well-documented code with inline comments
- **Tests**: Comprehensive test suite with examples
- **Documentation**: This documentation set

### External Resources
- **Flutter Documentation**: [flutter.dev](https://flutter.dev)
- **Background Geolocation Plugin**: Plugin-specific documentation
- **SQLite**: Database operation references
- **Dart Language**: Language-specific resources

### Getting Help
1. **Search existing issues** in the repository
2. **Check the documentation** thoroughly
3. **Review similar implementations** in the codebase
4. **Ask specific questions** with context and examples
5. **Provide detailed information** about your environment and issue

## Project Structure Quick Reference

```
wellbeing-mapper-app/
├── lib/
│   ├── main.dart              # App entry point
│   ├── models/                # Data models and structures
│   ├── ui/                    # User interface screens
│   ├── db/                    # Database management
│   ├── util/                  # Utility functions
│   ├── components/            # Reusable UI components
│   └── external_projects/     # Project-specific implementations
├── test/                      # Test files
├── integration_test/          # Integration tests
├── android/                   # Android platform code
├── ios/                       # iOS platform code
└── docs/                      # This documentation
```

## Next Steps

1. **Read the [Developer Guide](DEVELOPER_GUIDE.md)** for comprehensive information
2. **Study the [Architecture](ARCHITECTURE.md)** to understand system design
3. **Explore the [Flow Charts](FLOW_CHARTS.md)** to visualize component interactions
4. **Reference the [API Documentation](API_REFERENCE.md)** while coding
5. **Start with small changes** to get familiar with the workflow
6. **Ask questions** and engage with the development community

Welcome to the Wellbeing Mapper development team! This documentation should provide you with everything you need to start contributing effectively to the project.
