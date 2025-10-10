---
layout: default
title: Architecture
description: App structure and design patterns for the Gauteng Wellbeing Mapper
---

# Gauteng Wellbeing Mapper - Architecture Overview

## System Architecture Overview

Gauteng Wellbeing Mapper follows a layered architecture pattern designed for maintainability, testability, and scalability. The application is built using Flutter and implements a clean separation of concerns to support mental wellbeing mapping in environmental & climate context as part of the Planet4Health research project.

The architecture includes research participation with end-to-end encryption for secure data transmission from participants' phones to researchers in South Africa.

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
The app implements a sophisticated encryption system for secure research data transmission.

#### Encryption Components:
- **DataUploadService**: Core encryption and upload coordination
- **ServerConfig**: Research site configuration with embedded public keys
- **EncryptionResult**: Encryption operation results and metadata
- **LocationTrack**: Location data structures for research uploads

#### Security Features:
- **RSA-4096 Public Key Cryptography**: Asymmetric encryption for key exchange
- **AES-256-GCM**: Symmetric encryption for data payload (authenticated encryption)
- **Unique Session Keys**: Fresh AES key generated for each upload
- **Site Isolation**: Secure encryption for research data


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
        K[SurveyDatabase]
        L[UnpushedLocationsDB]
        M[SharedPreferences]
        N[FileStorage]
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

### App Mode Selection Flow

```mermaid
sequenceDiagram
    participant U as User
    participant MS as ModeSelection
    participant Config as AppConfig
    participant Prefs as SharedPreferences
    participant WV as WebView
    
    U->>MS: Select App Mode
    MS->>U: Display Mode Options
    U->>MS: Choose Research Mode
    MS->>WV: Show Consent Form
    WV->>U: Display Consent
    U->>WV: Accept Consent
    WV->>Config: Update Mode Configuration
    Config->>Prefs: Save Mode Settings
    Prefs->>MS: Confirm Update
    MS->>U: Mode Activated
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
