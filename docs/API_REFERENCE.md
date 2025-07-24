# Wellbeing Mapper - API Reference

## Overview

This document provides detailed information about the Wellbeing Mapper codebase APIs, including class methods, database schemas, encryption services, and integration points. This reference is intended for developers working on the codebase for the Planet4Health project case study on mental wellbeing in environmental & climate context.

The app now supports multi-site research participation with end-to-end encryption for secure data transmission to research servers in Barcelona, Spain and Gauteng, South Africa.

## Research Participation APIs

### ParticipationSettings

Manages user participation preferences and research site configuration.

```dart
class ParticipationSettings {
  final bool isResearchParticipant;
  final String? participantCode;        // Site-specific participant identifier
  final String? researchSite;          // 'barcelona' or 'gauteng'
  final DateTime createdAt;

  // Factory constructors
  factory ParticipationSettings.privateUser()
  factory ParticipationSettings.researchParticipant(String participantCode, String researchSite)
  
  // JSON serialization
  Map<String, dynamic> toJson()
  factory ParticipationSettings.fromJson(Map<String, dynamic> json)
}
```

### ConsentResponse

Handles informed consent for research participation with detailed consent tracking.

```dart
class ConsentResponse {
  final String participantUuid;         // Anonymous UUID identifier
  final bool informedConsent;
  final bool dataProcessing;
  final bool locationData;
  final bool surveyData;
  final bool dataRetention;
  final bool dataSharing;
  final bool voluntaryParticipation;
  final DateTime consentedAt;
  final String participantSignature;

  // Validation
  bool hasGivenValidConsent()
  
  // JSON serialization
  Map<String, dynamic> toJson()
  factory ConsentResponse.fromJson(Map<String, dynamic> json)
}
```

## Encryption & Data Upload APIs

### DataUploadService

Core service for encrypting and uploading research data to secure servers.

```dart
class DataUploadService {
  // Configuration
  static const Map<String, ServerConfig> _serverConfigs = {
    'barcelona': ServerConfig(...),
    'gauteng': ServerConfig(...)
  };

  // Main upload method
  static Future<UploadResult> uploadParticipantData({
    required String researchSite,
    required List<InitialSurveyResponse> initialSurveys,
    required List<RecurringSurveyResponse> recurringSurveys,
    required List<LocationTrack> locationTracks,
    required String participantUuid,
  })

  // Encryption
  static Future<EncryptionResult> encryptData(Map<String, dynamic> data, String researchSite)
  
  // Upload scheduling
  static Future<bool> shouldUploadData(String researchSite)
  static Future<void> markUploadCompleted(String researchSite, String uploadId)
  
  // Location data management
  static Future<List<LocationTrack>> getRecentLocationTracks()
}
```

#### ServerConfig

Configuration for research site servers with embedded public keys.

```dart
class ServerConfig {
  final String baseUrl;              // HTTPS server URL
  final String uploadEndpoint;       // API endpoint path
  final String publicKey;            // RSA-4096 public key (PEM format)
}
```

#### EncryptionResult

Result of data encryption operations.

```dart
class EncryptionResult {
  final bool success;
  final String? encryptedData;       // Base64 encoded: rsa_key|aes_data
  final Map<String, dynamic>? encryptionMetadata;
  final String? error;
}
```

#### UploadResult

Result of data upload operations to research servers.

```dart
class UploadResult {
  final bool success;
  final String? uploadId;            // UUID for tracking uploads
  final String? error;
  final DateTime? uploadedAt;
}
```

### LocationTrack

Location tracking data structure for research uploads.

```dart
class LocationTrack {
  final double latitude;
  final double longitude;
  final double? accuracy;            // Accuracy in meters
  final DateTime timestamp;
  final bool synced;                 // Upload synchronization status

  Map<String, dynamic> toJson()
  factory LocationTrack.fromJson(Map<String, dynamic> json)
}
```

## Survey System APIs

### Enhanced Survey Models

Survey models now support site-specific questions and research site tracking.

#### InitialSurveyResponse

```dart
class InitialSurveyResponse {
  final String id;
  final String participantUuid;
  final String? researchSite;       // NEW: Site-specific surveys
  final int wellbeingScore;
  final int stressLevel;
  final String mood;
  final List<String> activities;
  final String? ethnicity;          // Site-specific options
  final String? buildingType;       // Site-specific options
  final DateTime submittedAt;
  
  Map<String, dynamic> toJson()
  factory InitialSurveyResponse.fromJson(Map<String, dynamic> json)
}
```

#### RecurringSurveyResponse

```dart
class RecurringSurveyResponse {
  final String id;
  final String participantUuid;
  final String? researchSite;       // NEW: Site-specific surveys
  final int wellbeingScore;
  final int stressLevel;
  final String mood;
  final String? suburb;             // Gauteng-specific
  final String? generalHealth;      // Gauteng-specific
  final DateTime submittedAt;
  
  Map<String, dynamic> toJson()
  factory RecurringSurveyResponse.fromJson(Map<String, dynamic> json)
}
```

## Database APIs

### SurveyDatabase

Enhanced database class with location tracking and encryption support.

```dart
class SurveyDatabase {
  // Survey operations
  Future<int> insertInitialSurvey(InitialSurveyResponse survey)
  Future<List<InitialSurveyResponse>> getInitialSurveys()
  Future<int> insertRecurringSurvey(RecurringSurveyResponse survey)
  Future<List<RecurringSurveyResponse>> getRecurringSurveys()
  
  // Consent operations
  Future<int> insertConsent(ConsentResponse consent)
  Future<ConsentResponse?> getConsent()
  
  // Location tracking (NEW)
  Future<int> insertLocationTrack(Map<String, dynamic> locationData)
  Future<List<LocationTrack>> getLocationTracksSince(DateTime since)
  Future<List<LocationTrack>> getAllLocationTracks()
  Future<void> markLocationTracksAsSynced(List<String> trackIds)
  
  // Utility methods
  Future<DateTime?> getLastRecurringSurveyDate()
  Future<int> getRecurringSurveyCount()
  Future<List<Map<String, dynamic>>> getPendingSyncItems()
}
```

#### Database Schema

##### location_tracks table (NEW)
```sql
CREATE TABLE location_tracks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  accuracy REAL,
  timestamp TEXT NOT NULL,
  synced INTEGER DEFAULT 0,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

##### Enhanced survey tables
- `initial_surveys`: Added `research_site` column
- `recurring_surveys`: Added `research_site`, `suburb`, `general_health` columns
- `consent_responses`: Complete consent tracking with all required fields

## UI Components APIs

### DataUploadScreen

User interface for managing research data uploads.

```dart
class DataUploadScreen extends StatefulWidget {
  // Main screen for upload management
  // Shows upload status, data summary, and privacy information
  // Handles encrypted data transmission to research servers
}

class _DataUploadScreenState extends State<DataUploadScreen> {
  // State management
  bool _isLoading;
  String? _participantUuid;
  String? _researchSite;
  DateTime? _lastUpload;
  bool _canUpload;
  
  // Core methods
  Future<void> _loadParticipantInfo()
  Future<void> _uploadData()
  
  // UI builders
  Widget _buildParticipantInfo()
  Widget _buildUploadStatus()
  Widget _buildDataSummary()
  Widget _buildUploadButton()
  Widget _buildPrivacyNote()
}
```

### ParticipationSelectionScreen

Enhanced three-way participation selection interface.

```dart
class ParticipationSelectionScreen extends StatefulWidget {
  // Supports three modes:
  // 1. Private usage (no data sharing)
  // 2. Barcelona research participation
  // 3. Gauteng research participation
}

class _ParticipationSelectionScreenState extends State<ParticipationSelectionScreen> {
  String _selectedMode;             // 'private', 'barcelona', 'gauteng'
  TextEditingController _participantCodeController;
  
  // Site-specific UI rendering
  Widget _buildParticipationOption(String mode)
  Widget _buildParticipantCodeInput(String site)
  
  // Navigation to consent forms
  void _proceedToConsent(String site, String participantCode)
}
```

### ConsentFormScreen

Dynamic consent form generation based on research site.

```dart
class ConsentFormScreen extends StatefulWidget {
  final String participantCode;
  final String researchSite;       // 'barcelona' or 'gauteng'
}

class _ConsentFormScreenState extends State<ConsentFormScreen> {
  // Site-specific content generation
  String _getConsentTitle()
  String _getConsentContent()
  String _getLocationConsentText()
  
  // Consent processing
  Future<void> _submitConsent()
  ConsentResponse _buildConsentResponse()
}
```

## Encryption Technical Specifications

### Hybrid Encryption Process

1. **AES-256-GCM Encryption**:
   - Generate random 256-bit AES key
   - Generate random 96-bit IV
   - Encrypt JSON payload with AES-256-GCM
   - Produces: `encrypted_data + auth_tag`

2. **RSA-4096-OAEP Key Encryption**:
   - Encrypt AES key with research site's RSA public key
   - Use OAEP padding with SHA-256
   - Produces: `encrypted_aes_key`

3. **Final Payload**:
   - Format: `base64(encrypted_aes_key)|base64(encrypted_data+auth_tag)`
   - Metadata: `{"algorithm": "RSA-OAEP-AES-256-GCM", "iv": "base64_iv", ...}`

### Server-Side Decryption

```javascript
// Node.js decryption example
function decryptUpload(encryptedPayload, encryptionMetadata, privateKey) {
  const [encryptedAESKeyB64, encryptedDataB64] = encryptedPayload.split('|');
  
  // Decrypt AES key with RSA private key
  const aesKey = crypto.privateDecrypt({
    key: privateKey,
    padding: crypto.constants.RSA_PKCS1_OAEP_PADDING,
    oaepHash: 'sha256'
  }, Buffer.from(encryptedAESKeyB64, 'base64'));
  
  // Decrypt data with AES-256-GCM
  const iv = Buffer.from(encryptionMetadata.iv, 'base64');
  const encryptedData = Buffer.from(encryptedDataB64, 'base64');
  const authTag = encryptedData.slice(-16);
  const ciphertext = encryptedData.slice(0, -16);
  
  const decipher = crypto.createDecipherGCM('aes-256-gcm', aesKey);
  decipher.setIV(iv);
  decipher.setAuthTag(authTag);
  
  let decrypted = decipher.update(ciphertext, null, 'utf8');
  decrypted += decipher.final('utf8');
  
  return JSON.parse(decrypted);
}
```

## REST API Specifications

### Upload Endpoint

**POST** `/api/v1/participant-data`

**Request Headers**:
```
Content-Type: application/json
User-Agent: WellbeingMapper/1.0
```

**Request Body**:
```json
{
  "uploadId": "uuid-v4",
  "participantUuid": "uuid-v4",
  "researchSite": "barcelona" | "gauteng",
  "encryptedData": "base64-encoded-payload",
  "encryptionMetadata": {
    "algorithm": "RSA-OAEP-AES-256-GCM",
    "keySize": 4096,
    "iv": "base64-iv",
    "timestamp": "ISO-8601-timestamp"
  },
  "dataPeriod": {
    "start": "ISO-8601-timestamp",
    "end": "ISO-8601-timestamp"
  }
}
```

**Response**:
```json
{
  "success": true,
  "uploadId": "uuid-v4",
  "receivedAt": "ISO-8601-timestamp",
  "message": "Data uploaded successfully"
}
```

### Decrypted Data Structure

After server-side decryption, the payload contains:

```json
{
  "participantUuid": "uuid-v4",
  "researchSite": "barcelona" | "gauteng",
  "uploadTimestamp": "ISO-8601-timestamp",
  "surveys": [
    {
      "type": "initial" | "recurring",
      "submittedAt": "ISO-8601-timestamp",
      "responses": {
        "wellbeingScore": 1-10,
        "stressLevel": 1-10,
        "mood": "string",
        "suburb": "string",           // Gauteng only
        "generalHealth": "string",    // Gauteng only
        "ethnicity": "string",        // Site-specific options
        "buildingType": "string"      // Site-specific options
      }
    }
  ],
  "locationTracks": [
    {
      "timestamp": "ISO-8601-timestamp",
      "latitude": -90.0 to 90.0,
      "longitude": -180.0 to 180.0,
      "accuracy": 0.0-1000.0
    }
  ]
}
```

## Core Classes API

### CustomLocation

Primary class for handling location data with geocoded information.

```dart
class CustomLocation {
  // Properties
  String _uuid;                    // Unique identifier
  String _timestamp;               // ISO 8601 timestamp
  double _latitude;                // Decimal degrees
  double _longitude;               // Decimal degrees
  String _locality;                // City/locality name
  String _subAdministrativeArea;   // State/region
  String _street;                  // Street address
  String _isoCountryCode;          // ISO country code
  String _activity;                // Movement activity type
  num _speed;                      // Speed in m/s
  num _speedAccuracy;              // Speed accuracy
  num _altitude;                   // Altitude in meters
  num _altitudeAccuracy;           // Altitude accuracy
}
```

#### Static Methods

```dart
// Create CustomLocation from background geolocation data
static Future<CustomLocation> createCustomLocation(var recordedLocation)

// Reverse geocoding helper
static Future<Placemark?> getLocationData(double lat, double long)
```

#### Instance Methods

```dart
// Getters
String getUUID()
String getTimestamp()
double getLatitude()
double getLongitude()
String getLocality()
String getSubAdministrativeArea()
String getStreet()
String getISOCountryCode()
String getActivity()
num getSpeed()
num getSpeedAcc()
num getAltitude()
num getAltitudeAcc()

// Setters
void setUUID(String uuid)
void setTimestamp(String timestamp)
void setLatitude(double latitude)
void setLongitude(double longitude)
void setLocality(String locality)
void setSubAdministrativeArea(String subAdminArea)
void setStreet(String street)
void setISOCountry(String isoCountryCode)
void setActivity(String activity)
void setSpeed(num speed, num speedAccuracy)
void setAltitude(num altitude, num altitudeAccuracy)

// Utility Methods
DateTime timestampToDateTime(String timestamp)
String getFormattedTimestamp()
String getFormattedInformation(BuildContext context)
Future<void> deleteThisLocation()
```

### CustomLocationsManager

Static class for managing collections of CustomLocation objects.

```dart
class CustomLocationsManager {
  static List<CustomLocation> customLocations = [];
}
```

#### Static Methods

```dart
// Retrieve recent locations from background geolocation storage
static Future<List<CustomLocation>> getLocations(int maxElements)

// Remove all stored locations
static Future<void> removeAllCustomLocations()
```

### Project

Core class representing research projects.

```dart
class Project {
  // Properties
  int id;                         // Unique project ID
  String name;                    // Project display name
  String summary;                 // Project description
  String? webUrl;                 // Survey/project URL
  String? projectScreen;          // Internal screen route
  String imageUrl;                // Project banner image
  int locationSharingMethod;      // Data sharing method (0-3)
  String surveyElementCode;       // Form element identifier
}
```

#### Methods

```dart
// Navigate to project participation
void participate(BuildContext context, String locationHistoryJSON)

// String representation
String toString()
```

### ShareLocation

Simplified location data structure for sharing.

```dart
class ShareLocation {
  // Properties
  String timestamp;     // ISO 8601 timestamp
  double latitude;      // Decimal degrees latitude
  double longitude;     // Decimal degrees longitude
  double accuracy;      // Location accuracy in meters
  String userUUID;      // Anonymous user identifier
  
  // Constructor
  ShareLocation(this.timestamp, this.latitude, this.longitude, 
                this.accuracy, this.userUUID);
  
  // JSON serialization
  Map<String, dynamic> toJson()
}
```

## Database APIs

### ProjectDatabase

Manages research project data storage.

```dart
class ProjectDatabase {
  static final ProjectDatabase instance = ProjectDatabase._init();
  static Database? _database;
}
```

#### Core Methods

```dart
// Database initialization
Future<Database> get database
Future<Database> _initDB(String filePath)
Future _createDB(Database db, int version)
Future _onUpgrade(Database db, int oldVersion, int newVersion)

// CRUD Operations
Future<int> createProject(Particpating_Project project)
Future<Particpating_Project> readProject(int projectNumber)
Future<List<Particpating_Project>> readAllProjects()
Future<List<Particpating_Project>> getOngoingProjects()
Future<int> updateProject(Particpating_Project project)
Future<int> deleteProject(int projectNumber)

// Specialized Queries
Future<ProjectList> RetrieveProjectbyURL(String projectURL)
Future<Particpating_Project> getParticipatingProjectById(int projectId)
Future<void> updateProjectStatusBasedOnProjectNUmber(int projectNumber, String status)

// Utility
Future close()
```

#### Database Schema

```sql
CREATE TABLE participating_projects(
  projectNumber INTEGER PRIMARY KEY AUTOINCREMENT,
  projectId INTEGER NOT NULL,
  projectName STRING NOT NULL,
  projectDescription STRING NOT NULL,
  externalLink STRING,
  internalLink STRING,
  projectImageLocation STRING NOT NULL,
  duration STRING NOT NULL,
  startDate STRING NOT NULL,
  endDate STRING NOT NULL,
  projectStatus STRING NOT NULL,
  locationSharingMethod INTEGER NOT NULL,
  surveyElementCode STRING NOT NULL
)
```

### ContactDatabase

Manages contact form submissions.

```dart
class ContactDatabase {
  static final ContactDatabase instance = ContactDatabase._init();
  static Database? _database;
}
```

#### Core Methods

```dart
// Database operations
Future<Database> get database
Future<int> createContact(Contact contact)
Future<Contact> readContact(int id)
Future<List<Contact>> readAllContacts()
Future<int> updateContact(Contact contact)
Future<int> deleteContact(int id)
Future close()
```

#### Database Schema

```sql
CREATE TABLE contacts(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name STRING NOT NULL,
  email STRING NOT NULL,
  phone STRING NOT NULL,
  message STRING NOT NULL,
  timestamp STRING NOT NULL
)
```

### UnPushedLocationsDatabase

Manages failed location uploads for retry mechanisms.

```dart
class UnPushedLocationsDatabase {
  static final UnPushedLocationsDatabase instance = UnPushedLocationsDatabase._init();
  static Database? _database;
}
```

#### Core Methods

```dart
// Database operations
Future<Database> get database
Future<LocationToPush> createRecord(LocationToPush location)
Future<LocationToPush> readLocation(int id)
Future<List<LocationToPush>> readAllRecords()
Future<int> deleteRecord(String userUUID)
Future<int> getAmountOfRows()
Future close()
```

#### Database Schema

```sql
CREATE TABLE unpushedLocations(
  "_id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "user_UUID" STRING,
  "user_code" STRING,
  "app_version" STRING,
  "os" STRING,
  "type_of_data" STRING,
  "message" STRING,
  "lon" DOUBLE,
  "lat" DOUBLE,
  "unix_time" STRING,
  "speed" STRING,
  "activity" STRING,
  "altitude" STRING
)
```

## UI Component APIs

### HomeView

Main application screen managing location tracking and navigation.

```dart
class HomeView extends StatefulWidget {
  HomeView(this.appName);
  final String appName;
}

class HomeViewState extends State<HomeView> 
    with TickerProviderStateMixin<HomeView>, WidgetsBindingObserver {
  
  // State variables
  late bool _enabled;              // Location tracking enabled state
  late String appName;             // Application title
}
```

#### Key Methods

```dart
// Lifecycle
void initState()
void didChangeAppLifecycleState(AppLifecycleState state)

// Background geolocation setup
void initPlatformState()
void _configureBackgroundGeolocation(user_uuid, sample_id)
void _configureBackgroundFetch()

// User interactions
void _onClickEnable(enabled)
void _onClickGetCurrentPosition()

// Event handlers
void _onLocation(bg.Location location)
void _onLocationError(bg.LocationError error)
void _onMotionChange(bg.Location location)
void _onProviderChange(bg.ProviderChangeEvent event)
void _onHttp(bg.HttpEvent event)
void _onConnectivityChange(bg.ConnectivityChangeEvent event)
void _onHeartbeat(bg.HeartbeatEvent event)
void _onGeofence(bg.GeofenceEvent event)
void _onSchedule(bg.State state)
void _onEnabledChange(bool enabled)
void _onNotificationAction(String action)
void _onPowerSaveChange(bool enabled)

// Project management
void fetchProjects()

// Build method
Widget build(BuildContext context)
```

### MapView

Interactive map component displaying location history.

```dart
class MapView extends StatefulWidget {}

class MapViewState extends State<MapView> 
    with AutomaticKeepAliveClientMixin<MapView> {
  
  // Map components
  List<CircleMarker> _currentPosition = [];
  List<LatLng> _polyline = [];
  List<CircleMarker> _locations = [];
  List<CircleMarker> _stopLocations = [];
  List<Polyline> _motionChangePolylines = [];
  List<CircleMarker> _stationaryMarker = [];
  
  LatLng _center = new LatLng(51.5, -0.09);
  late MapController _mapController;
  late MapOptions _mapOptions;
}
```

#### Key Methods

```dart
// Lifecycle
void initState()
bool get wantKeepAlive

// Event handlers
void _onLocation(bg.Location location)
void _onMotionChange(bg.Location location)
void _onEnabledChange(bool enabled)
void _onPositionChanged(MapPosition pos, bool hasGesture)

// Display methods
void _displayStoredLocations()
void _updateCurrentPositionMarker(LatLng ll)

// Map element builders
Polyline _buildMotionChangePolyline(bg.Location from, bg.Location to)
CircleMarker _buildStopCircleMarker(bg.Location location)

// Build method
Widget build(BuildContext context)
```

### ProjectDetail

Detailed view for individual research projects.

```dart
class ProjectDetail extends StatefulWidget {
  final int projectID;
  ProjectDetail(this.projectID);
}

class _ProjectDetailState extends State<ProjectDetail> {
  Project? project;
  bool endButtonPressed = false;
  int dropdownValue = 7;
  String statusToSet = "ongoing";
  String surveyType = "starting";
  DateTime? startTime;
}
```

#### Key Methods

```dart
// Lifecycle
void initState()
void loadData()

// Data management
Future<Map<String, dynamic>> checkProjectStatus()
Future<String> getLocationsToShare(int maxDays)

// Navigation
Future<void> _navigationToProject(BuildContext context)

// UI builders
Widget build(BuildContext context)
Widget _renderBody(BuildContext context, Project project)
Widget _renderHeader()
Widget _renderConsentForm()
Widget _renderBottomSpacer()
```

## Global Data and State Management

### GlobalData

Application-wide state container.

```dart
class GlobalData {
  static String userUUID = "";                    // Unique user identifier
  static bool user_active_projects = false;      // Has active projects
  static bool user_available_projects = false;   // Has available projects
}
```

### GlobalRouteData

Navigation state management.

```dart
class GlobalRouteData {
  static String? user_route = "brown";  // Current route identifier
}
```

### GlobalProjectData

Project-specific state management.

```dart
class GlobalProjectData {
  static int? active_project_number;     // Current active project ID
  static String active_project_status = "";  // Project status
  static String generatedUrl = "";      // Generated survey URL
}
```

## Background Processing APIs

### Background Geolocation Events

```dart
// Main headless task handler
void backgroundGeolocationHeadlessTask(bg.HeadlessEvent headlessEvent)

// Supported events:
// - bg.Event.TERMINATE: App termination
// - bg.Event.HEARTBEAT: Periodic heartbeat
// - bg.Event.LOCATION: New location
// - bg.Event.MOTIONCHANGE: Movement state change
// - bg.Event.GEOFENCE: Geofence entry/exit
// - bg.Event.GEOFENCESCHANGE: Geofence configuration change
// - bg.Event.SCHEDULE: Schedule state change
// - bg.Event.ACTIVITYCHANGE: Activity type change
// - bg.Event.HTTP: HTTP response
// - bg.Event.POWERSAVECHANGE: Power save mode change
// - bg.Event.CONNECTIVITYCHANGE: Network connectivity change
// - bg.Event.ENABLEDCHANGE: Service enabled state change
// - bg.Event.AUTHORIZATION: Permission authorization change
```

### Background Fetch

```dart
// Background fetch handler
void backgroundFetchHeadlessTask(String taskId)

// Configuration
BackgroundFetchConfig(
  minimumFetchInterval: 15,        // Minimum interval in minutes
  startOnBoot: true,               // Start on device boot
  stopOnTerminate: false,          // Continue after app termination
  enableHeadless: true,            // Enable headless execution
  requiresStorageNotLow: false,    // Storage requirements
  requiresBatteryNotLow: false,    // Battery requirements
  requiresCharging: false,         // Charging requirements
  requiresDeviceIdle: false,       // Device idle requirements
  requiredNetworkType: NetworkType.NONE  // Network requirements
)
```

## Utility APIs

### Environment Configuration

```dart
class ENV {
  static final String TRACKER_HOST;        // Server host URL
  static final String DEFAULT_SAMPLE_ID;   // Default sample identifier
}
```

### Authentication

```dart
class TransistorAuth {
  // Register device with server
  static Future<bool> register()
  
  // Handle authentication errors
  static Future<void> registerErrorHandler()
}
```

### Dialog Utilities

```dart
class Dialog {
  // Get sound ID for notifications
  static int getSoundId(String soundName)
}
```

## Navigation and Routing

### RouteGenerator

Application navigation management.

```dart
class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings)
}
```

#### Supported Routes

```dart
// Available routes:
'/'                           // HomeView (main screen)
'/participate_in_a_project'   // Available projects list
'/active_projects'            // Active projects list  
'/locations_history'          // Location history list
'/report_an_issue'            // Issue reporting form
'/navigation_to_webview'      // Project survey webview
'/new_project'                // Project creation/QR scan
'/tiger_in_car'               // Specific project screen
'/tiger_in_car_finish'        // Project completion screen
```

## Data Models

### LocationToPush

Model for queued location uploads.

```dart
class LocationToPush {
  // Properties
  final int? id;
  final String userUUID;
  final String userCode;
  final String appVersion;
  final String operativeSystem;
  final String typeOfData;
  final String message;
  final double longitude;
  final double latitude;
  final String unixTime;
  final num speed;
  final String activity;
  final String altitude;
  
  // Methods
  LocationToPush copy({...})        // Create copy with optional changes
  Map<String, Object?> toJson()     // Convert to JSON
  static LocationToPush fromJson(Map<String, Object?> json)  // Create from JSON
}
```

### Contact

Contact form data model.

```dart
class Contact {
  // Properties
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String message;
  final String timestamp;
  
  // Methods
  Contact copy({...})               // Create copy with optional changes
  Map<String, Object?> toJson()     // Convert to JSON
  static Contact fromJson(Map<String, Object?> json)  // Create from JSON
}
```

## Error Handling

### Common Error Types

```dart
// Location errors
class LocationError {
  int code;         // Error code
  String message;   // Error description
}

// Database errors
class DatabaseException extends Exception {
  String message;
  DatabaseException(this.message);
}

// Network errors
class NetworkException extends Exception {
  String message;
  int? statusCode;
  NetworkException(this.message, [this.statusCode]);
}
```

### Error Handling Patterns

```dart
// Try-catch with graceful degradation
try {
  await riskyOperation();
} catch (error) {
  print('Operation failed: $error');
  await fallbackOperation();
}

// Future error handling
riskyAsyncOperation()
  .then((result) => handleSuccess(result))
  .catchError((error) => handleError(error));

// Database error handling
Future<void> safeDatabaseOperation() async {
  try {
    await database.transaction((txn) async {
      // Database operations
    });
  } on DatabaseException catch (e) {
    print('Database error: ${e.message}');
    // Handle database-specific errors
  } catch (e) {
    print('Unexpected error: $e');
    // Handle unexpected errors
  }
}
```

This API reference provides comprehensive coverage of the Wellbeing Mapper codebase. For implementation examples and usage patterns, refer to the Developer Guide and Architecture documentation.
