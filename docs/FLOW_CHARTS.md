# Wellbeing Mapper - Flow Charts and Diagrams

## Application Flow Overview

This document contains detailed flow charts and diagrams to help developers understand how different components of Wellbeing Mapper interact with each other to support mental wellbeing mapping in environmental & climate context as part of the Planet4Health research project.

## Main Application Flow

```mermaid
flowchart TD
    A[App Launch] --> B[Check User UUID]
    B --> C{UUID Exists?}
    C -->|No| D[Generate New UUID]
    C -->|Yes| E[Load User Preferences]
    D --> E
    E --> F[Initialize Background Geolocation]
    F --> G[Configure Background Fetch]
    G --> H[Load HomeView]
    H --> I[Display Map]
    I --> J[Check Active Projects]
    J --> K{Has Active Projects?}
    K -->|Yes| L[Show Project Indicators]
    K -->|No| M[Show Default State]
    L --> N[Ready for User Interaction]
    M --> N
    
    style A fill:#e1f5fe
    style N fill:#c8e6c9
```

## Location Tracking Flow

```mermaid
flowchart TD
    A[User Enables Tracking] --> B[Request Location Permissions]
    B --> C{Permissions Granted?}
    C -->|No| D[Show Permission Error]
    C -->|Yes| E[Configure Background Geolocation]
    E --> F[Start Location Service]
    F --> G[Background Location Monitoring]
    
    G --> H[Location Event Received]
    H --> I[Create CustomLocation Object]
    I --> J[Perform Reverse Geocoding]
    J --> K[Store Location in Database]
    K --> L[Update Map Display]
    L --> M[Check Active Projects]
    M --> N{Share Location?}
    N -->|Yes| O[Format Location Data]
    N -->|No| P[Continue Monitoring]
    O --> Q[Send to Project API]
    Q --> R{API Success?}
    R -->|Yes| S[Mark as Synced]
    R -->|No| T[Store in Retry Queue]
    S --> P
    T --> U[Schedule Retry]
    U --> P
    
    P --> H
    
    style A fill:#e1f5fe
    style G fill:#fff3e0
    style P fill:#c8e6c9
```

## Project Participation Flow

```mermaid
flowchart TD
    A[User Opens Project Menu] --> B[Load Available Projects]
    B --> C{Projects Available?}
    C -->|No| D[Show Add Project Option]
    C -->|Yes| E[Display Project List]
    
    D --> F[Scan QR Code]
    F --> G[Parse QR Code URL]
    G --> H[Fetch Project Data]
    H --> I{Valid Project?}
    I -->|No| J[Show Error Message]
    I -->|Yes| K[Display Project Details]
    
    E --> L[User Selects Project]
    L --> K
    K --> M[Show Consent Form]
    M --> N[User Reviews Information]
    N --> O{User Consents?}
    O -->|No| P[Return to Project List]
    O -->|Yes| Q[Store Project in Database]
    Q --> R[Set Project Status to Active]
    R --> S[Generate Survey URL]
    S --> T[Open WebView]
    T --> U[Load Survey Form]
    U --> V[Auto-fill Location Data]
    V --> W[User Completes Survey]
    W --> X[Submit Survey Data]
    X --> Y{Submission Success?}
    Y -->|No| Z[Show Retry Option]
    Y -->|Yes| AA[Update Project Status]
    AA --> BB[Return to Home]
    
    Z --> X
    J --> D
    P --> E
    
    style A fill:#e1f5fe
    style BB fill:#c8e6c9
    style J fill:#ffcdd2
    style Z fill:#ffcdd2
```

## Background Processing Flow

```mermaid
flowchart TD
    A[App Backgrounded/Terminated] --> B[Background Geolocation Active]
    B --> C[Location Event Triggered]
    C --> D[Headless Task Activated]
    D --> E[Process Location Event]
    E --> F[Store Location Data]
    F --> G[Check Network Connectivity]
    G --> H{Network Available?}
    H -->|Yes| I[Attempt API Sync]
    H -->|No| J[Store for Later Sync]
    I --> K{Sync Success?}
    K -->|Yes| L[Mark as Synced]
    K -->|No| M[Add to Retry Queue]
    
    L --> N[Continue Background Monitoring]
    M --> N
    J --> N
    N --> C
    
    O[Background Fetch Triggered] --> P[Check Retry Queue]
    P --> Q{Items to Retry?}
    Q -->|Yes| R[Attempt Retry Upload]
    Q -->|No| S[Perform Maintenance]
    R --> T{Retry Success?}
    T -->|Yes| U[Remove from Queue]
    T -->|No| V[Update Retry Count]
    U --> S
    V --> W{Max Retries?}
    W -->|Yes| X[Mark as Failed]
    W -->|No| S
    X --> S
    S --> Y[Finish Background Task]
    
    style A fill:#e1f5fe
    style N fill:#fff3e0
    style Y fill:#c8e6c9
```

## Data Synchronization Flow

```mermaid
flowchart TD
    A[Location Data Generated] --> B[Store Locally]
    B --> C[Check Active Projects]
    C --> D{Projects Require Data?}
    D -->|No| E[Local Storage Only]
    D -->|Yes| F[Format for Each Project]
    F --> G[Attempt Upload]
    G --> H{Upload Success?}
    H -->|Yes| I[Mark as Synced]
    H -->|No| J[Add to Retry Queue]
    
    I --> K[Continue Processing]
    J --> L[UnpushedLocationsDB]
    L --> M[Schedule Background Retry]
    
    N[Background Fetch] --> O[Check Retry Queue]
    O --> P{Queue Empty?}
    P -->|Yes| Q[No Action Needed]
    P -->|No| R[Process Queue Items]
    R --> S[Attempt Reupload]
    S --> T{Success?}
    T -->|Yes| U[Remove from Queue]
    T -->|No| V[Increment Retry Count]
    U --> W{More Items?}
    V --> X{Max Retries Reached?}
    X -->|Yes| Y[Mark as Failed]
    X -->|No| W
    W -->|Yes| R
    W -->|No| Q
    Y --> W
    
    style A fill:#e1f5fe
    style E fill:#c8e6c9
    style Q fill:#c8e6c9
```

## User Interface Navigation Flow

```mermaid
flowchart TD
    A[Home Screen] --> B{User Action}
    B -->|Menu| C[Side Drawer]
    B -->|Location Toggle| D[Enable/Disable Tracking]
    B -->|GPS Button| E[Get Current Position]
    B -->|Map Interaction| F[Map View Updates]
    
    C --> G{Menu Selection}
    G -->|Projects| H[Projects List]
    G -->|History| I[Location History]
    G -->|Share| J[Share Locations]
    G -->|Report Issue| K[Issue Report Form]
    G -->|Website| L[External Website]
    
    H --> M{Project Action}
    M -->|New Project| N[QR Scanner]
    M -->|View Details| O[Project Detail View]
    M -->|Participate| P[Project Survey]
    
    N --> Q[Scan QR Code]
    Q --> R{Valid QR?}
    R -->|Yes| S[Fetch Project Data]
    R -->|No| T[Error Message]
    S --> O
    T --> N
    
    O --> U{User Decision}
    U -->|Participate| V[Show Consent]
    U -->|Cancel| H
    V --> W{User Consents?}
    W -->|Yes| P
    W -->|No| O
    
    P --> X[WebView Survey]
    X --> Y[Auto-fill Data]
    Y --> Z[User Completion]
    Z --> AA[Submit Results]
    AA --> A
    
    I --> BB[List View]
    BB --> CC{Item Action}
    CC -->|Delete| DD[Remove Location]
    CC -->|View Details| EE[Location Details]
    DD --> BB
    EE --> BB
    
    D --> FF{Enable/Disable}
    FF -->|Enable| GG[Start Tracking]
    FF -->|Disable| HH[Stop Tracking]
    GG --> A
    HH --> A
    
    E --> II[Request Location]
    II --> A
    F --> A
    J --> JJ[Share Dialog]
    JJ --> A
    K --> KK[Report Form]
    KK --> A
    L --> LL[Open Browser]
    LL --> A
    
    style A fill:#e1f5fe
    style AA fill:#c8e6c9
    style T fill:#ffcdd2
```

## Database Operations Flow

```mermaid
flowchart TD
    A[Database Operation Request] --> B{Operation Type}
    B -->|Create| C[Insert Operation]
    B -->|Read| D[Query Operation]
    B -->|Update| E[Update Operation]
    B -->|Delete| F[Delete Operation]
    
    C --> G[Validate Data]
    G --> H{Data Valid?}
    H -->|No| I[Return Validation Error]
    H -->|Yes| J[Execute Insert]
    J --> K{Insert Success?}
    K -->|Yes| L[Return New Record ID]
    K -->|No| M[Return Database Error]
    
    D --> N[Build Query]
    N --> O[Execute Query]
    O --> P{Query Success?}
    P -->|Yes| Q[Return Results]
    P -->|No| R[Return Query Error]
    
    E --> S[Validate Update Data]
    S --> T{Data Valid?}
    T -->|No| U[Return Validation Error]
    T -->|Yes| V[Execute Update]
    V --> W{Update Success?}
    W -->|Yes| X[Return Updated Count]
    W -->|No| Y[Return Update Error]
    
    F --> Z[Validate Delete Request]
    Z --> AA[Execute Delete]
    AA --> BB{Delete Success?}
    BB -->|Yes| CC[Return Deleted Count]
    BB -->|No| DD[Return Delete Error]
    
    style A fill:#e1f5fe
    style L fill:#c8e6c9
    style Q fill:#c8e6c9
    style X fill:#c8e6c9
    style CC fill:#c8e6c9
    style I fill:#ffcdd2
    style M fill:#ffcdd2
    style R fill:#ffcdd2
    style U fill:#ffcdd2
    style Y fill:#ffcdd2
    style DD fill:#ffcdd2
```

## Error Handling Flow

```mermaid
flowchart TD
    A[Operation Attempted] --> B{Operation Success?}
    B -->|Yes| C[Continue Normal Flow]
    B -->|No| D[Error Occurred]
    D --> E[Log Error Details]
    E --> F[Determine Error Type]
    F --> G{Error Type}
    
    G -->|Network| H[Network Error Handler]
    G -->|Database| I[Database Error Handler]
    G -->|Permission| J[Permission Error Handler]
    G -->|Validation| K[Validation Error Handler]
    G -->|Unknown| L[Generic Error Handler]
    
    H --> M{Network Available?}
    M -->|Yes| N[Retry Operation]
    M -->|No| O[Queue for Later]
    N --> P{Retry Success?}
    P -->|Yes| C
    P -->|No| Q{Max Retries?}
    Q -->|Yes| R[Mark as Failed]
    Q -->|No| N
    
    I --> S[Check Database Connection]
    S --> T{Connection OK?}
    T -->|Yes| U[Retry Database Operation]
    T -->|No| V[Reinitialize Database]
    U --> W{Retry Success?}
    W -->|Yes| C
    W -->|No| X[Report Database Issue]
    V --> Y[Database Reinitialized]
    Y --> U
    
    J --> Z[Request Permissions]
    Z --> AA{Permissions Granted?}
    AA -->|Yes| BB[Retry Operation]
    AA -->|No| CC[Show Permission Explanation]
    BB --> C
    CC --> DD[User Education]
    
    K --> EE[Show Validation Message]
    EE --> FF[Request Corrected Input]
    FF --> GG[User Corrects Input]
    GG --> A
    
    L --> HH[Log Unknown Error]
    HH --> II[Show Generic Error Message]
    II --> JJ[Graceful Degradation]
    
    O --> KK[Store in Retry Queue]
    R --> LL[Notify User of Failure]
    X --> MM[Database Recovery Mode]
    DD --> NN[Continue with Reduced Function]
    JJ --> NN
    MM --> NN
    LL --> NN
    KK --> NN
    
    style A fill:#e1f5fe
    style C fill:#c8e6c9
    style NN fill:#fff3e0
    style R fill:#ffcdd2
    style X fill:#ffcdd2
    style LL fill:#ffcdd2
```

## State Management Flow

```mermaid
flowchart TD
    A[User Action] --> B[State Change Triggered]
    B --> C{State Type}
    C -->|Global| D[Update GlobalData]
    C -->|Route| E[Update GlobalRouteData]
    C -->|Project| F[Update GlobalProjectData]
    C -->|Local Widget| G[Update Widget State]
    
    D --> H[Notify Global Listeners]
    E --> I[Update Navigation State]
    F --> J[Update Project UI]
    G --> K[Trigger Widget Rebuild]
    
    H --> L[Update Dependent Widgets]
    I --> M[Navigate to New Screen]
    J --> N[Refresh Project Display]
    K --> O[Widget Redrawn]
    
    L --> P[Save to SharedPreferences]
    M --> Q[Screen Transition]
    N --> R[Update Project Status]
    O --> S[UI Updated]
    
    P --> T[Persist State]
    Q --> U[New Screen Loaded]
    R --> V[Database Updated]
    S --> W[User Sees Changes]
    
    T --> X[State Persisted]
    U --> Y[Screen Ready]
    V --> Z[Project State Saved]
    W --> AA[Interaction Complete]
    
    style A fill:#e1f5fe
    style X fill:#c8e6c9
    style Y fill:#c8e6c9
    style Z fill:#c8e6c9
    style AA fill:#c8e6c9
```

## Component Interaction Diagram

```mermaid
graph TB
    subgraph "UI Layer"
        UI1[HomeView]
        UI2[MapView]
        UI3[ListView]
        UI4[ProjectViews]
        UI5[WebView]
    end
    
    subgraph "Business Logic"
        BL1[LocationManager]
        BL2[ProjectManager]
        BL3[NavigationRouter]
        BL4[StateManager]
    end
    
    subgraph "Data Layer"
        DL1[CustomLocation]
        DL2[ProjectDatabase]
        DL3[ContactDatabase]
        DL4[UnpushedDB]
        DL5[SharedPreferences]
    end
    
    subgraph "Platform Layer"
        PL1[BackgroundGeolocation]
        PL2[BackgroundFetch]
        PL3[WebServices]
        PL4[FileSystem]
    end
    
    UI1 --> BL1
    UI1 --> BL3
    UI1 --> BL4
    UI2 --> BL1
    UI2 --> DL1
    UI3 --> DL1
    UI4 --> BL2
    UI4 --> DL2
    UI5 --> BL2
    
    BL1 --> DL1
    BL1 --> PL1
    BL2 --> DL2
    BL2 --> PL3
    BL3 --> DL5
    BL4 --> DL5
    
    DL1 --> PL1
    DL2 --> PL4
    DL3 --> PL4
    DL4 --> PL4
    
    PL1 --> PL2
    PL3 --> PL2
    
    style UI1 fill:#e3f2fd
    style UI2 fill:#e3f2fd
    style UI3 fill:#e3f2fd
    style UI4 fill:#e3f2fd
    style UI5 fill:#e3f2fd
    style BL1 fill:#f3e5f5
    style BL2 fill:#f3e5f5
    style BL3 fill:#f3e5f5
    style BL4 fill:#f3e5f5
    style DL1 fill:#e8f5e8
    style DL2 fill:#e8f5e8
    style DL3 fill:#e8f5e8
    style DL4 fill:#e8f5e8
    style DL5 fill:#e8f5e8
    style PL1 fill:#fff3e0
    style PL2 fill:#fff3e0
    style PL3 fill:#fff3e0
    style PL4 fill:#fff3e0
```

These flow charts and diagrams provide a comprehensive visual guide to understanding how Wellbeing Mapper components interact and how data flows through the system. They serve as a reference for developers to quickly understand the application's behavior and identify integration points for new features.
