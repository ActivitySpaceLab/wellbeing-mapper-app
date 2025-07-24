# Wellbeing Mapper - Code Architecture

## System Architecture Overview

Wellbeing Mapper follows a layered architecture pattern designed for maintainability, testability, and scalability. The application is built using Flutter and implements a clean separation of concerns to support mental wellbeing mapping in environmental & climate context as part of the Planet4Health research project.

The architecture now includes multi-site research participation with end-to-end encryption for secure data transmission to research servers in Barcelona, Spain and Gauteng, South Africa.

## Architectural Layers

### 1. Presentation Layer (`ui/`)
The presentation layer handles all user interface components and user interactions.

#### Key Components:
- **HomeView**: Main application screen with location tracking controls
- **MapView**: Interactive map displaying location history  
- **ListView**: Chronological list of recorded locations
- **ParticipationSelectionScreen**: Three-way research participation selection
- **ConsentFormScreen**: Dynamic site-specific consent forms
- **DataUploadScreen**: Encrypted research data upload interface
- **Survey Screens**: Site-specific survey interfaces
- **WebView**: Survey and external content integration

#### Responsibilities:
- User interface rendering
- User input handling
- State management for UI components
- Navigation between screens
- Research participation workflow management

### 2. Business Logic Layer (`models/`, `services/`)
This layer contains the application's business rules and data processing logic.

#### Key Components:
- **RouteGenerator**: Application navigation and routing
- **CustomLocation**: Location data processing and management
- **DataUploadService**: Encrypted data transmission service
- **ConsentModels**: Research consent and participation management
- **SurveyModels**: Site-specific survey data structures
- **LocationManager**: Location tracking coordination

#### Responsibilities:
- Data validation and processing
- Encryption and security operations
- Business rule implementation
- Service coordination
- Multi-site research logic
- Upload scheduling and synchronization

### 3. Data Layer (`db/` and `models/`)
The data layer manages all data persistence and retrieval operations.

#### Key Components:
- **SurveyDatabase**: Enhanced SQLite database with location tracking
- **Model Classes**: Data structure definitions with encryption support
- **Storage Services**: File and preference management
- **LocationTrack**: Location data for research uploads

#### Responsibilities:
- Data persistence with encryption support
- Database operations for surveys and location tracking
- Local data synchronization
- Data model definitions
- Cache management

### 4. Platform Layer (`util/` and platform services)
This layer handles platform-specific functionality and external service integration.

#### Key Components:
- **Background Geolocation**: Native location tracking
- **Authentication Services**: User identification  
- **Environment Configuration**: App settings
- **External APIs**: Third-party service integration

#### Responsibilities:
- Platform-specific operations
- External service communication
- Background processing
- Hardware abstraction

## Security & Encryption Architecture

### Hybrid Encryption System
The app implements a sophisticated encryption system for secure research data transmission:

```
Local Data → AES-256-GCM → RSA-4096-OAEP → Base64 → HTTPS → Research Server
     ↓              ↓              ↓           ↓         ↓
Survey Responses   Fast Encryption  Key Security  Transit   Secure Storage
Location Tracks    Large Data      Public Key    Format    Private Key Only
Demographics       Performance     Exchange      Network   Decryption
```

#### Encryption Components:
- **DataUploadService**: Core encryption and upload coordination
- **ServerConfig**: Research site configuration with embedded public keys
- **EncryptionResult**: Encryption operation results and metadata
- **LocationTrack**: Location data structures for research uploads

#### Security Features:
- **RSA-4096 Public Key Cryptography**: Asymmetric encryption for key exchange
- **AES-256-GCM**: Symmetric encryption for data payload (authenticated encryption)
- **Unique Session Keys**: Fresh AES key generated for each upload
- **Site Isolation**: Separate key pairs for Barcelona and Gauteng research sites
- **Forward Secrecy**: Compromised uploads don't affect other uploads

### Multi-Site Research Architecture
```
App Configuration:
├── Barcelona Research Site
│   ├── Public Key (embedded in app)
│   ├── Server: barcelona-research.domain.com
│   └── Site-specific surveys and consent
├── Gauteng Research Site  
│   ├── Public Key (embedded in app)
│   ├── Server: gauteng-research.domain.com
│   └── Site-specific surveys and consent
└── Private Mode
    └── No data transmission (local only)
```

## Component Interaction Diagram

```mermaid
graph TB
    subgraph "Presentation Layer"
        A[ParticipationSelectionScreen]
        B[ConsentFormScreen]
        C[DataUploadScreen]
        D[HomeView]
        E[MapView]
        F[SurveyScreens]
    end
    
    subgraph "Business Logic Layer"
        G[DataUploadService]
        H[ConsentModels]
        I[SurveyModels]
        J[RouteGenerator]
        K[CustomLocation]
        L[LocationManager]
    end
    
    subgraph "Data Layer"
        K[ProjectDatabase]
        L[ContactDatabase]
        M[UnpushedLocationsDB]
        N[SharedPreferences]
        O[FileStorage]
    end
    
    subgraph "Platform Layer"
        P[BackgroundGeolocation]
        Q[Authentication]
        R[WebServices]
        S[Environment]
    end
    
    A --> F
    A --> I
    B --> G
    C --> G
    D --> H
    D --> J
    E --> H
    
    F --> K
    G --> L
    G --> M
    H --> K
    I --> P
    J --> K
    
    G --> P
    H --> R
    I --> Q
    J --> R
    
    K --> N
    L --> N
    M --> O
```

## Data Flow Architecture

### Location Tracking Flow

```mermaid
sequenceDiagram
    participant U as User
    participant HV as HomeView
    participant BG as BackgroundGeolocation
    participant CL as CustomLocation
    participant DB as Database
    participant MV as MapView
    
    U->>HV: Enable Tracking
    HV->>BG: Start Location Service
    BG->>BG: Background Monitoring
    BG->>CL: Location Event
    CL->>CL: Process Location Data
    CL->>DB: Store Location
    CL->>MV: Update Map Display
    MV->>U: Visual Update
```

### Project Participation Flow

```mermaid
sequenceDiagram
    participant U as User
    participant PC as ProjectCreate
    participant QR as QRScanner
    participant API as External API
    participant DB as ProjectDatabase
    participant WV as WebView
    
    U->>PC: Scan QR Code
    PC->>QR: Open Scanner
    QR->>PC: Return URL
    PC->>API: Fetch Project Data
    API->>PC: Project Information
    PC->>U: Display Project Details
    U->>PC: Agree to Participate
    PC->>DB: Store Project
    PC->>WV: Open Survey
    WV->>API: Submit Data
```

## Core Classes and Their Relationships

### 1. Location Management Classes

```dart
// Core location data structure
class CustomLocation {
    String _uuid;
    String _timestamp;
    double _latitude;
    double _longitude;
    String _locality;
    String _activity;
    // ... other properties
    
    static Future<CustomLocation> createCustomLocation(var recordedLocation);
    Future<void> deleteThisLocation();
    String getFormattedTimestamp();
}

// Location collection management
class CustomLocationsManager {
    static Future<List<CustomLocation>> getLocations(int maxElements);
    static Future<void> storeLocation(CustomLocation location);
    static Future<void> removeAllCustomLocations();
}

// Simplified location for sharing
class ShareLocation {
    String timestamp;
    double latitude;
    double longitude;
    double accuracy;
    String userUUID;
}
```

### 2. Project Management Classes

```dart
// Base project structure
class Project {
    int id;
    String name;
    String summary;
    String? webUrl;
    String? projectScreen;
    String imageUrl;
    int locationSharingMethod;
    String surveyElementCode;
    
    void participate(BuildContext context, String locationHistoryJSON);
}

// Database storage for projects
class ProjectDatabase {
    static final ProjectDatabase instance;
    
    Future<Database> get database;
    Future<int> createProject(Particpating_Project project);
    Future<List<Particpating_Project>> getOngoingProjects();
    Future<void> updateProjectStatus(int projectId, String status);
}
```

### 3. Database Architecture

```mermaid
erDiagram
    CustomLocation {
        string uuid PK
        string timestamp
        double latitude
        double longitude
        string locality
        string activity
        double speed
        double altitude
    }
    
    Project {
        int projectNumber PK
        int projectId
        string projectName
        string description
        string externalLink
        string internalLink
        string imageLocation
        string duration
        string startDate
        string endDate
        string status
        int locationSharingMethod
        string surveyElementCode
    }
    
    Contact {
        int id PK
        string name
        string email
        string phone
        string message
        string timestamp
    }
    
    UnpushedLocation {
        int id PK
        string userUUID
        string userCode
        string appVersion
        string operativeSystem
        string typeOfData
        string message
        double longitude
        double latitude
        string unixTime
        string speed
        string activity
        string altitude
    }
```

## Background Processing Architecture

### Headless Tasks

Wellbeing Mapper implements sophisticated background processing to ensure location tracking continues even when the app is terminated.

```dart
// Main headless task handler
void backgroundGeolocationHeadlessTask(bg.HeadlessEvent headlessEvent) async {
    switch (headlessEvent.name) {
        case bg.Event.LOCATION:
            // Process new location data
            bg.Location location = headlessEvent.event;
            await processLocationInBackground(location);
            break;
        case bg.Event.MOTIONCHANGE:
            // Handle movement state changes
            break;
        case bg.Event.GEOFENCE:
            // Handle geofence events
            break;
        // ... other event types
    }
}

// Background fetch for periodic tasks
void backgroundFetchHeadlessTask(String taskId) async {
    // Retry failed uploads
    // Perform maintenance tasks
    // Update project status
    BackgroundFetch.finish(taskId);
}
```

### State Management Pattern

```mermaid
graph LR
    A[User Action] --> B[State Change]
    B --> C[Business Logic]
    C --> D[Data Update]
    D --> E[UI Refresh]
    E --> F[User Feedback]
    
    subgraph "Global State"
        G[GlobalData]
        H[SharedPreferences]
        I[Database State]
    end
    
    C --> G
    C --> H
    C --> I
```

## Security Architecture

### Data Protection
- **Local Storage**: All sensitive data stored locally using SQLite
- **Encryption**: User UUIDs generated using cryptographically secure methods
- **Anonymization**: Personal identifiers never shared with external services
- **User Control**: Explicit consent required for all data sharing

### Authentication Flow
```mermaid
sequenceDiagram
    participant A as App
    participant P as Preferences
    participant S as Server
    participant U as UUID Generator
    
    A->>P: Check User UUID
    alt UUID exists
        P->>A: Return UUID
    else UUID missing
        A->>U: Generate New UUID
        U->>A: Return UUID
        A->>P: Store UUID
    end
    
    A->>S: Register with UUID
    S->>A: Return Auth Token
    A->>P: Store Auth Token
```

## Error Handling Architecture

### Error Handling Strategy
1. **Graceful Degradation**: App continues functioning with reduced capabilities
2. **Retry Mechanisms**: Automatic retry for network failures
3. **Local Fallbacks**: Store data locally when remote services fail
4. **User Feedback**: Clear error messages and recovery options

### Error Flow
```mermaid
graph TD
    A[Operation Attempt] --> B{Success?}
    B -->|Yes| C[Continue Normal Flow]
    B -->|No| D[Log Error]
    D --> E[Determine Error Type]
    E --> F{Recoverable?}
    F -->|Yes| G[Apply Recovery Strategy]
    F -->|No| H[Graceful Degradation]
    G --> I[Retry Operation]
    I --> B
    H --> J[Notify User]
    J --> K[Continue with Reduced Function]
```

## Performance Considerations

### Location Tracking Optimization
- **Smart Sampling**: Adjust location frequency based on movement
- **Battery Management**: Optimize GPS usage for battery life
- **Memory Management**: Limit in-memory location history
- **Background Limits**: Respect platform background execution limits

### Database Optimization
- **Indexing**: Proper database indexes for common queries
- **Pagination**: Limit query results to prevent memory issues
- **Cleanup**: Regular cleanup of old location data
- **Transactions**: Batch database operations for performance

## Testing Architecture

### Testing Strategy
1. **Unit Tests**: Individual class and method testing
2. **Widget Tests**: UI component testing
3. **Integration Tests**: End-to-end workflow testing
4. **Platform Tests**: Native functionality testing

### Test Organization
```
test/
├── unit/
│   ├── models/
│   ├── services/
│   └── utils/
├── widget/
│   ├── ui/
│   └── components/
└── integration_test/
    ├── location_tracking_test.dart
    ├── project_participation_test.dart
    └── app_test.dart
```

## Deployment Architecture

### Build Configuration
- **Development**: Debug builds with verbose logging
- **Staging**: Release builds with test data
- **Production**: Optimized builds with production configuration

### Platform-Specific Considerations
- **Android**: ProGuard/R8 optimization, signing configuration
- **iOS**: App Store compliance, background execution limits
- **Cross-Platform**: Shared business logic, platform-specific UI adaptations

## Future Architecture Considerations

### Scalability
- **Cloud Integration**: Optional cloud backup and sync
- **Real-time Features**: Live location sharing for specific projects
- **Analytics**: Privacy-preserving usage analytics
- **Modular Projects**: Plugin architecture for research projects

### Technology Evolution
- **State Management**: Consider adopting Bloc or Riverpod
- **Database**: Evaluate migration to Drift for type safety
- **Background Processing**: Adapt to changing platform restrictions
- **UI Framework**: Stay current with Flutter updates and best practices
