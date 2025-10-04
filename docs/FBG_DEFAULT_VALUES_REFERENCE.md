# Flutter Background Geolocation (FBG) Default Values Reference

This document provides a comprehensive reference of Flutter Background Geolocation library default values, extracted from the official library source code and documentation.

**Source Analysis Date:** October 4, 2025  
**FBG Library Version:** Based on flutter_background_geolocation-master copy  

## Core Geolocation Settings

| Setting | Default Value | Description |
|---------|---------------|-------------|
| `desiredAccuracy` | Not explicitly set | Uses platform defaults, typically `DESIRED_ACCURACY_HIGH (-1)` |
| `distanceFilter` | Auto-calculated (elastic) | Elastically auto-calculated based on speed. When speed increases, distanceFilter increases |
| `stationaryRadius` | Not explicitly set | Platform-specific, typically ~25m |
| `locationTimeout` | `60` seconds | Default timeout when requesting a location before giving up |
| `disableElasticity` | `false` | Allows automatic, speed-based distanceFilter elasticity |
| `elasticityMultiplier` | Not explicitly set | Multiplier for elastic distanceFilter calculation |
| `useSignificantChangesOnly` | `false` | Records location every 500-1000m when true (cellular tower spacing) |

## Activity Recognition Settings

| Setting | Default Value | Description |
|---------|---------------|-------------|
| `stopTimeout` | `5` minutes | Wait time before transitioning to stationary state after detecting STILL |
| `activityRecognitionInterval` | `10000` ms (10 seconds) | Time between activity detections (Android primarily) |
| `minimumActivityRecognitionConfidence` | `75`% | Confidence threshold to trigger motion change events |
| `activityType` | Not explicitly set | iOS activity type, typically `ACTIVITY_TYPE_OTHER (1)` |
| `disableStopDetection` | `false` | Whether to disable accelerometer-based stop detection |
| `stopDetectionDelay` | `0` (no delay) | Delay before stop-detection system activates |

## HTTP & Persistence Settings

| Setting | Default Value | Description |
|---------|---------------|-------------|
| `autoSync` | `true` | Automatically upload locations to server |
| `autoSyncThreshold` | `0` (no threshold) | Number of locations to batch before HTTP upload |
| `batchSync` | `false` | Whether to batch multiple locations in single HTTP request |
| `maxBatchSize` | `-1` (no maximum) | Maximum number of records per batch request |
| `persistMode` | `PERSIST_MODE_ALL (2)` | Persist both geofence and location events |
| `maxDaysToPersist` | Not explicitly set | Days to store locations in SQLite database |
| `maxRecordsToPersist` | `-1` (no limit) | Maximum records to persist in database |
| `locationsOrderDirection` | `ASC` | Order for database location selection (oldest first) |
| `httpTimeout` | `60000` ms (60 seconds) | HTTP request timeout |
| `method` | `POST` | HTTP method for server requests |

## Application Behavior Settings

| Setting | Default Value | Description |
|---------|---------------|-------------|
| `stopOnTerminate` | `true` | Stop tracking when app terminates |
| `startOnBoot` | `false` | Resume tracking after device reboot |
| `enableHeadless` | `false` | Enable headless background operation |
| `heartbeatInterval` | Not explicitly set | Rate for heartbeat events (60s minimum on Android) |
| `preventSuspend` | `false` | Prevent iOS app suspension during tracking |

## Geofencing Settings

| Setting | Default Value | Description |
|---------|---------------|-------------|
| `geofenceProximityRadius` | `1000` meters (minimum) | Proximity radius for geofence activation |
| `maxMonitoredGeofences` | iOS: `20`, Android: `100` | Platform maximum for simultaneous geofence monitoring |
| `geofenceInitialTriggerEntry` | `true` | Trigger geofence immediately if already inside |
| `geofenceModeHighAccuracy` | `false` | Use high-accuracy mode for geofence transitions |

## Accuracy & Filtering Settings

| Setting | Default Value | Description |
|---------|---------------|-------------|
| `desiredOdometerAccuracy` | `100` meters | Accuracy threshold for odometer calculations |
| `allowIdenticalLocations` | `false` | Allow recording same location multiple times |
| `speedJumpFilter` | `300` m/s (Android) | Reject locations with impossible speed changes |

## iOS-Specific Settings

| Setting | Default Value | Description |
|---------|---------------|-------------|
| `pausesLocationUpdatesAutomatically` | Platform default | iOS automatic location pause behavior |
| `locationAuthorizationRequest` | `Always` | Desired location permission level |
| `disableLocationAuthorizationAlert` | `false` | Show location permission upgrade dialogs |
| `showsBackgroundLocationIndicator` | Platform default | Show iOS blue location indicator |
| `disableMotionActivityUpdates` | `false` | Disable iOS motion activity updates |

## Android-Specific Settings

| Setting | Default Value | Description |
|---------|---------------|-------------|
| `locationUpdateInterval` | Not explicitly set | Interval for location update requests |
| `fastestLocationUpdateInterval` | Not explicitly set | Fastest interval to accept location updates |
| `deferTime` | `0` (no defer) | Delay location delivery for batching |
| `enableTimestampMeta` | `false` | Add timestamp metadata to locations |
| `foregroundService` | `true` (enforced Android 8+) | Run as foreground service |

## Logging & Debug Settings

| Setting | Default Value | Description |
|---------|---------------|-------------|
| `debug` | `false` | Enable debug mode with sounds/notifications |
| `logLevel` | `LOG_LEVEL_OFF (0)` in production | Logging verbosity level |
| `logMaxDays` | `3` days | Days to retain logs in database |
| `reset` | `false` | Force apply config on each app launch |

## Notification Settings (Android)

| Setting | Default Value | Description |
|---------|---------------|-------------|
| `notificationPriority` | `NOTIFICATION_PRIORITY_DEFAULT (0)` | Foreground service notification priority |
| `notificationTitle` | Platform default | Notification title text |
| `notificationText` | Platform default | Notification body text |

## Constants Reference

### Desired Accuracy Constants
```dart
DESIRED_ACCURACY_NAVIGATION = -2  // Highest accuracy
DESIRED_ACCURACY_HIGH = -1        // High accuracy  
DESIRED_ACCURACY_MEDIUM = 10      // Medium accuracy (10m)
DESIRED_ACCURACY_LOW = 100        // Low accuracy (100m)
DESIRED_ACCURACY_VERY_LOW = 1000  // Very low accuracy (1000m)
DESIRED_ACCURACY_LOWEST = 3000    // Lowest accuracy (3000m)
```

### Activity Type Constants
```dart
ACTIVITY_TYPE_OTHER = 1                    // General activity
ACTIVITY_TYPE_AUTOMOTIVE_NAVIGATION = 2    // Driving navigation
ACTIVITY_TYPE_FITNESS = 3                  // Walking/running/cycling
ACTIVITY_TYPE_OTHER_NAVIGATION = 4         // Other navigation
ACTIVITY_TYPE_AIRBORNE = 5                 // Flying
```

### Persist Mode Constants
```dart
PERSIST_MODE_ALL = 2         // Persist both location and geofence events (DEFAULT)
PERSIST_MODE_LOCATION = 1    // Persist only location events
PERSIST_MODE_GEOFENCE = -1   // Persist only geofence events  
PERSIST_MODE_NONE = 0        // Persist nothing
```

### Log Level Constants
```dart
LOG_LEVEL_OFF = 0       // No logging
LOG_LEVEL_ERROR = 1     // Error messages only
LOG_LEVEL_WARNING = 2   // Warnings and errors
LOG_LEVEL_INFO = 3      // Info, warnings, and errors
LOG_LEVEL_DEBUG = 4     // Debug and above
LOG_LEVEL_VERBOSE = 5   // All logging
```

## Example App Configuration

The official FBG example app uses these key settings:
```dart
bg.BackgroundGeolocation.ready(bg.Config(
    // Logging & Debug
    debug: true,
    logLevel: bg.Config.LOG_LEVEL_VERBOSE,
    
    // Geolocation options
    desiredAccuracy: bg.Config.DESIRED_ACCURACY_NAVIGATION,
    distanceFilter: 10.0,
    
    // Activity recognition options
    stopTimeout: 5,
    
    // HTTP & Persistence
    autoSync: true,
    
    // Application options
    stopOnTerminate: false,
    startOnBoot: true,
    enableHeadless: true,
    heartbeatInterval: 60
));
```

## Key Insights

1. **Elastic Distance Filtering**: By default, FBG automatically adjusts `distanceFilter` based on movement speed
2. **Conservative Defaults**: Most defaults prioritize battery life over frequency
3. **Platform Differences**: iOS and Android have different capabilities and defaults
4. **Geofencing Priority**: Library designed with geofencing as primary use case
5. **Background Limitations**: Newer Android versions enforce stricter background execution limits

## Notes

- Some defaults are not explicitly documented and rely on platform-specific behaviors
- The library is designed to work well "out of the box" for most tracking scenarios
- Production apps should typically use `logLevel: LOG_LEVEL_OFF` for performance
- Always test configuration changes thoroughly on target devices and OS versions

---

**Last Updated:** October 4, 2025  
**Source:** Flutter Background Geolocation library master branch analysis