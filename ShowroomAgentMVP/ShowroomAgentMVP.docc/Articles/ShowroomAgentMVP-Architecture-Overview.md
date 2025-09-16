# Architecture Overview

Comprehensive guide to ShowroomAgentMVP's technical architecture, design patterns, and system components.

## Overview

ShowroomAgentMVP follows modern Swift architectural principles, leveraging SwiftUI for the user interface, SwiftData for persistence, and structured concurrency for asynchronous operations. The application is designed as a native macOS experience with careful attention to platform integration and user experience.

## High-Level Architecture

### System Components

The application consists of several interconnected layers:

```
┌─────────────────────────────────────────────┐
│                UI Layer                     │
│  SwiftUI Views + ViewModels + Navigation    │
├─────────────────────────────────────────────┤
│              Service Layer                  │
│   GitService + ShowroomUtilities + LLM     │
├─────────────────────────────────────────────┤
│               Data Layer                    │
│     SwiftData Models + Core Data Logic     │
├─────────────────────────────────────────────┤
│             Platform Layer                  │
│  macOS Security + File System + Network    │
└─────────────────────────────────────────────┘
```

### Core Design Principles

**Native macOS Experience**:
- SwiftUI for modern, declarative interface design
- AppKit integration for platform-specific functionality
- Security-scoped bookmarks for sandboxed file access
- Native file system operations and folder selection

**Reactive Architecture**:
- `@Observable` macro for state management (not ObservableObject)
- SwiftUI's declarative data flow patterns
- Reactive updates throughout the interface
- Efficient view invalidation and rendering

**Structured Concurrency**:
- Modern async/await patterns for all asynchronous operations
- MainActor for UI thread safety
- Structured task management with proper cancellation
- Background processing with UI responsiveness

## Data Architecture

### SwiftData Integration

ShowroomAgentMVP uses SwiftData as its primary persistence layer:

```swift
@Model
final class Project {
    var name: String
    var repositoryURL: String?
    var localFolderPath: String?
    var localFolderBookmark: Data?
    var cloneStatus: CloneStatus = .notStarted
    var llmUrl: String?
    var llmModelName: String?
    var llmAPIKey: String?
    var temperature: Double = 0.7
    var blogPrompt: String?
    
    @Transient var showroomRepository: ShowroomRepository?
}
```

**Key Design Decisions**:
- **Persistent Properties**: Core project configuration stored in SwiftData
- **Transient Properties**: Temporary data like parsed repository content
- **Optional Configuration**: Flexible setup allowing partial configuration
- **Security Bookmarks**: Binary data storage for macOS file system permissions

### Data Flow Patterns

**Project Lifecycle**:
```
Create → Configure → Validate → Generate → Review
   ↓        ↓          ↓         ↓        ↓
 Save → Persist → Transient → Process → Display
```

**State Management**:
- **@Query**: SwiftData queries for reactive project lists
- **@Environment**: Model context injection for data operations
- **@State**: Transient UI state (selection, sheets, navigation)
- **@Observable**: Custom observable objects for complex state

## User Interface Architecture

### Navigation Structure

The application uses a hierarchical navigation pattern:

```
NavigationSplitView
├── Sidebar (Project List)
│   ├── Project Rows
│   ├── Selection State
│   └── Creation Controls
└── Detail View
    ├── Project Information
    ├── Configuration Forms
    └── Activity Launchers
```

### View Hierarchy

**Main Interface Components**:

```swift
ContentView                    // Root navigation container
├── ProjectSidebar            // Project list and management
│   ├── ProjectRowView       // Individual project items
│   └── NewProjectSheet      // Project creation modal
└── ProjectDetailView        // Selected project information
    ├── ConfigurationSheet   // Settings and setup
    └── ActivityViews       // Content generation workflows
```

**Modal Presentations**:
- **NewProjectSheet**: Project creation with optional initial configuration
- **ProjectConfigurationSheet**: Repository and LLM settings management
- **ActivitySheets**: Content generation workflows (blog, social media)

### State Management Patterns

**Observable Objects**:
```swift
@Observable
class InspectorState {
    var isVisible = false
    var currentType: InspectorType?
    
    func show(_ type: InspectorType) {
        currentType = type
        isVisible = true
    }
}
```

**Environment Integration**:
```swift
@Environment(\.modelContext) private var modelContext
@Query private var projects: [Project]
@State private var selectedProject: Project?
@State private var inspectorState = InspectorState()
```

## Service Layer Architecture

### Core Services

**GitService**: Repository operations and content management
```swift
final class GitService {
    func downloadRepository(from url: String, to localPath: String, project: Project) async -> Result<String, RepositoryError>
    func validateRepository(at path: String) async throws -> ValidationResult
}
```

**ShowroomUtilities**: Content processing and utility functions
```swift
final class ShowroomUtilities {
    static func validateShowroomRepository(at path: String) throws -> ShowroomRepository?
    static func isValidGitHubURL(_ urlString: String) -> Bool
}
```

**LLM Integration**: AI service management through SwiftChatCompletionsDSL
```swift
// Integration with external SwiftChatCompletionsDSL library
// Provides OpenAI-compatible API client functionality
```

### Service Design Patterns

**Dependency Injection**:
- Services injected through SwiftUI environment
- Protocol-based abstractions for testability
- Singleton patterns for shared resource management

**Error Handling**:
- Result types for operation outcomes
- Specific error types for different failure categories
- Graceful degradation with user-friendly error messages

**Async/Await Integration**:
- All network operations use structured concurrency
- MainActor annotations for UI thread safety
- Proper cancellation support for long-running operations

## Platform Integration

### macOS Security Model

**Security-Scoped Bookmarks**:
```swift
extension Project {
    func withSecureFolderAccess<T>(_ operation: () async throws -> T) async throws -> T {
        // Resolve security bookmark
        // Start accessing scoped resource
        // Execute operation with proper cleanup
        // Stop accessing scoped resource
    }
}
```

**File System Access**:
- **App Sandbox Compatibility**: Works within sandbox restrictions
- **User Consent**: Clear permission requests for folder access
- **Persistent Access**: Security bookmarks maintain permissions across sessions
- **Cleanup**: Proper resource management and permission cleanup

### AppKit Integration

**Platform-Specific Features**:
```swift
#if os(macOS)
import AppKit

extension Project {
    func selectLocalFolder() -> String? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        // Configure and display folder selection
    }
}
#endif
```

### Network Architecture

**HTTP-Based Operations**:
- **Repository Downloads**: HTTP archive downloads instead of git clone
- **LLM API Calls**: RESTful API integration with proper authentication
- **Error Recovery**: Retry logic and graceful failure handling
- **Progress Tracking**: Real-time progress updates for long operations

## Content Processing Architecture

### ShowroomParser Integration

The application integrates with the ShowroomParser library for content processing:

```swift
// External dependency: ShowroomParser
import ShowroomParser

extension Project {
    func parseShowroomContent() async throws -> ShowroomRepository {
        guard let repositoryPath = repositoryLocalPath else {
            throw ProjectError.invalidConfiguration("Repository local path not configured")
        }
        
        return try await withSecureFolderAccess {
            guard let parsedRepo = ShowroomParser.parseRepository(at: repositoryPath) else {
                throw ProjectError.repositoryNotFound
            }
            
            self.showroomRepository = parsedRepo
            return parsedRepo
        }
    }
}
```

### Content Generation Workflow

**Multi-Step Processing**:
1. **Repository Validation**: Verify Antora structure and ShowroomParser compatibility
2. **Content Extraction**: Parse documentation files and navigation structure
3. **Content Transformation**: Convert parsed content to markdown format
4. **LLM Processing**: Send formatted content to AI service with custom prompts
5. **Output Generation**: Process LLM response and present to user

**Memory Management**:
- **Lazy Loading**: Content parsed only when needed
- **Transient Storage**: Parsed content not persisted, regenerated as needed
- **Efficient Processing**: Stream-based processing for large repositories

## Testing Architecture

### Testing Strategy

**Unit Testing with Swift Testing**:
```swift
@Suite("Project Management Tests")
struct ProjectManagementTests {
    @Test("Project creation with valid name")
    func testProjectCreation() async throws {
        let project = Project(name: "Test Project")
        #expect(project.name == "Test Project")
    }
}
```

**Integration Testing**:
- **End-to-End Workflows**: Complete content generation scenarios
- **External Service Mocking**: Mock LLM and repository services for testing
- **File System Testing**: Temporary directories and permission testing

**UI Testing**:
- **Navigation Testing**: SwiftUI navigation and state management
- **Modal Presentation**: Sheet and inspector testing
- **User Interaction**: Button clicks, form inputs, and validation

### Test Data Management

**Mock Repositories**:
- **Antora Structure**: Valid test repositories with proper configuration
- **Content Variety**: Different content types and structures for testing
- **Error Scenarios**: Invalid repositories for error handling testing

## Performance Considerations

### Memory Management

**Efficient Content Handling**:
- **NSCache**: Intelligent caching for parsed content
- **Lazy Evaluation**: Parse content only when needed
- **Memory Pressure**: Respond to system memory warnings
- **Resource Cleanup**: Proper disposal of temporary data

### Background Processing

**Async Operations**:
- **Network Downloads**: Background repository downloads with progress
- **Content Parsing**: Background ShowroomParser operations
- **LLM Generation**: Background AI processing with status updates
- **UI Responsiveness**: Maintain smooth interface during processing

### Scalability

**Project Management**:
- **Efficient Queries**: SwiftData optimizations for large project lists
- **Lazy Loading**: Load project details only when selected
- **Batch Operations**: Efficient handling of multiple projects

## Security Architecture

### Data Protection

**Sensitive Information**:
- **API Keys**: Secure storage using macOS Keychain services
- **Repository Access**: Security-scoped bookmarks for file system access
- **Network Security**: HTTPS-only communications
- **Data Isolation**: Project data properly isolated and protected

### Permission Management

**File System Security**:
- **Explicit Consent**: Clear user permission requests
- **Minimal Access**: Access only to user-selected directories
- **Time-Limited**: Security bookmarks with proper expiration handling
- **Audit Trail**: Logging of file system operations for debugging

## Extensibility and Modularity

### Plugin Architecture

**Extension Points**:
- **Custom LLM Providers**: Protocol-based LLM service integration
- **Content Processors**: Extensible content parsing and transformation
- **Output Formats**: Configurable content generation formats
- **Workflow Integration**: Hooks for external system integration

### Configuration Management

**Flexible Settings**:
- **Project-Level**: Per-project configuration and customization
- **Application-Level**: Global settings and preferences
- **User Preferences**: Customizable UI and workflow preferences
- **Template System**: Reusable prompt templates and configurations

## Future Architecture Considerations

### Potential Enhancements

**Cross-Platform Support**:
- **iOS Adaptation**: Architecture designed for potential iOS version
- **Shared Libraries**: Core logic separated from platform-specific code
- **Cloud Synchronization**: Project synchronization across devices

**Advanced Features**:
- **Collaborative Editing**: Multi-user project sharing and collaboration
- **Version Control**: Content generation history and versioning
- **Analytics Integration**: Content performance tracking and optimization
- **Batch Processing**: Automated content generation for multiple projects

### Scalability Planning

**Performance Optimization**:
- **Concurrent Processing**: Parallel content generation for multiple projects
- **Caching Strategies**: Advanced caching for frequently accessed content
- **Resource Management**: Dynamic resource allocation based on system capabilities

---

This architecture overview provides the foundation for understanding ShowroomAgentMVP's design and implementation. For specific implementation details, refer to the source code and comprehensive specifications in the project repository.