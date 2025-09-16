# Swift Code Generation Implementation Guide

## 1. Purpose and Scope

### Clear Relationship to Generic Specification
This document provides **Swift-specific implementation guidance** for building the content generation platform described in the [Generic Code Generation Specification](CodeGenerationSpec.md). While the generic specification provides language-agnostic algorithms, this guide focuses on **how** to implement those algorithms using Swift language features, frameworks, and idioms.

### Target Audience
AI code generation tools targeting Swift development, iOS/macOS developers, and development teams implementing the ShowroomAgentMVP system using Swift and SwiftUI.

### Prerequisites
- **Swift 6.1+**: Required for latest concurrency features and macro support
- **Xcode 15.0+**: Development environment with Swift Testing framework support
- **macOS 13.0+**: Target platform with SwiftUI and SwiftData availability
- **Understanding of SwiftUI**: Basic knowledge of declarative UI development
- **SwiftData Knowledge**: Understanding of modern Swift persistence framework

### Related Documents
- [Functional Specification](ShowroomAgentMVPSpec.md) - System capabilities and user requirements
- [Generic Code Generation Specification](CodeGenerationSpec.md) - Language-agnostic implementation algorithms

## 2. Swift Project Setup

### Package/Build System Configuration

#### Package.swift Configuration
```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ShowroomAgentMVP",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "ShowroomAgentMVP",
            targets: ["ShowroomAgentMVP"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
        .package(url: "https://github.com/RichNasz/ShowroomParser.git", branch: "main"),
        .package(url: "https://github.com/RichNasz/SwiftChatCompletionsDSL.git", branch: "main")
    ],
    targets: [
        .target(
            name: "ShowroomAgentMVP",
            dependencies: [
                "Yams",
                "ShowroomParser", 
                "SwiftChatCompletionsDSL"
            ],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableUpcomingFeature("ConciseMagicFile"),
                .enableUpcomingFeature("ForwardTrailingClosures"),
                .enableUpcomingFeature("ImplicitOpenExistentials"),
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "ShowroomAgentMVPTests",
            dependencies: ["ShowroomAgentMVP"]
        ),
    ]
)
```

#### Xcode Project Configuration
```swift
// Project Build Settings Requirements
SWIFT_VERSION = 6.0
MACOSX_DEPLOYMENT_TARGET = 13.0
ENABLE_STRICT_CONCURRENCY = YES
SWIFT_UPCOMING_FEATURE_FLAGS = BareSlashRegexLiterals ConciseMagicFile ForwardTrailingClosures ImplicitOpenExistentials StrictConcurrency

// Code Signing Configuration
CODE_SIGN_STYLE = Automatic
DEVELOPMENT_TEAM = [Your Team ID]
CODE_SIGN_IDENTITY = "Apple Development"

// App Sandbox Configuration (Optional - can be disabled for development)
ENABLE_APP_SANDBOX = YES
SANDBOX_NETWORK_CLIENT = YES
SANDBOX_FILE_ACCESS_USER_SELECTED = YES
```

### Dependency Specifications

#### Core Framework Dependencies
```swift
// SwiftUI and SwiftData (System Frameworks)
import SwiftUI
import SwiftData
import Foundation
import AppKit  // For macOS-specific functionality

// External Package Dependencies
import Yams                    // YAML parsing (Remote dependency)
import ShowroomParser         // Content parsing (GitHub dependency)
import SwiftChatCompletionsDSL // LLM integration (GitHub dependency)
```

#### Dependency Version Constraints
```swift
// In Package.swift dependencies array:
.package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
.package(url: "https://github.com/RichNasz/ShowroomParser.git", branch: "main"),
.package(url: "https://github.com/RichNasz/SwiftChatCompletionsDSL.git", branch: "main")

// Alternative version constraints (when tags become available):
// .package(url: "https://github.com/RichNasz/ShowroomParser.git", from: "1.0.0"),
// .package(url: "https://github.com/RichNasz/SwiftChatCompletionsDSL.git", from: "1.0.0")
```

### Module Organization and File Structure
```
ShowroomAgentMVP/
├── ShowroomAgentMVP/
│   ├── ShowroomAgentMVPApp.swift        # App entry point
│   ├── ContentView.swift                # Main UI container
│   ├── Models/
│   │   ├── ProjectData.swift           # SwiftData models
│   │   └── BlogGoal.swift              # Activity models
│   ├── Services/
│   │   ├── GitService.swift            # Repository operations
│   │   ├── RepositoryDownloader.swift  # HTTP download service
│   │   └── ShowroomUtilities.swift     # Utility functions
│   ├── Views/
│   │   ├── ProjectViews/               # Project management UI
│   │   ├── ContentGeneration/          # Content generation UI
│   │   └── Shared/                     # Reusable components
│   └── Assets.xcassets/                # App resources
├── ShowroomAgentMVPTests/
│   └── ShowroomAgentMVPTests.swift     # Test suite
└── ShowroomAgentMVPUITests/
    └── ShowroomAgentMVPUITests.swift   # UI test suite
```

### Required Imports and Namespace Usage
```swift
// Core application imports (required in most files)
import Foundation
import SwiftUI
import SwiftData

// Platform-specific imports (use conditionally)
#if canImport(AppKit)
import AppKit  // For macOS-specific functionality
#endif

// External dependencies (import only where needed)
import Yams                    // YAML parsing in utility files
import ShowroomParser         // Content parsing in services
import SwiftChatCompletionsDSL // LLM integration in content generation

// Conditional imports for features
#if canImport(Playgrounds)
import Playgrounds  // For playground support (optional)
#endif
```

## 3. Swift-Specific Data Model Implementation

### Type System Usage (Structs, Classes, Enums, Interfaces)

#### SwiftData Model Implementation
```swift
import Foundation
import SwiftData

@Model
final class Project {
    // Stored properties for persistence
    var name: String
    var repositoryURL: String?
    var localFolderPath: String?
    var localFolderBookmark: Data?
    var cloneStatus: CloneStatus = .notStarted
    var cloneErrorMessage: String?
    var lastClonedDate: Date?
    var createdDate: Date
    var modifiedDate: Date
    var blogPrompt: String?
    var llmUrl: String?
    var llmModelName: String?
    var llmAPIKey: String?
    var temperature: Double = 0.7
    
    // Transient property (not persisted)
    @Transient var showroomRepository: ShowroomRepository?
    
    init(name: String) {
        self.name = name
        self.createdDate = Date()
        self.modifiedDate = Date()
        // Other properties use default values or nil
    }
}

// Supporting enums with Codable conformance
enum CloneStatus: String, Codable, CaseIterable, Sendable {
    case notStarted = "notStarted"
    case cloning = "cloning" 
    case completed = "completed"
    case failed = "failed"
}
```

#### Observable State Management
```swift
import Observation

@Observable
class InspectorState {
    var isVisible = false
    var currentType: InspectorType?
    
    func show(_ type: InspectorType) {
        currentType = type
        isVisible = true
    }
    
    func hide() {
        isVisible = false
        currentType = nil
    }
}

// Enum for type-safe state management
enum InspectorType: Equatable {
    case newProject
    case configureProject(Project)
    case blogGoal(Project)
    case activity(ActivityType, Project)
    
    static func == (lhs: InspectorType, rhs: InspectorType) -> Bool {
        switch (lhs, rhs) {
        case (.newProject, .newProject):
            return true
        case (.configureProject(let l), .configureProject(let r)):
            return l.id == r.id
        case (.blogGoal(let l), .blogGoal(let r)):
            return l.id == r.id
        case (.activity(let l1, let l2), .activity(let r1, let r2)):
            return l1 == r1 && l2.id == r2.id
        default:
            return false
        }
    }
}
```

### Immutability Patterns and Data Model Organization
```swift
// Immutable configuration structures
struct LLMConfiguration {
    let endpointURL: String
    let modelName: String
    let apiKey: String
    let temperature: Double
    
    // Validation computed property
    var isValid: Bool {
        !endpointURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !modelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        temperature >= 0.0 && temperature <= 2.0
    }
    
    // Builder pattern for configuration
    func with(temperature: Double) -> LLMConfiguration {
        LLMConfiguration(
            endpointURL: self.endpointURL,
            modelName: self.modelName, 
            apiKey: self.apiKey,
            temperature: temperature
        )
    }
}

// Value types for transient data
struct ValidationResult {
    let isSuccess: Bool
    let errorMessage: String?
    let warnings: [String]
    let repository: ShowroomRepository?
    
    static func success(_ repository: ShowroomRepository) -> ValidationResult {
        ValidationResult(isSuccess: true, errorMessage: nil, warnings: [], repository: repository)
    }
    
    static func failure(_ message: String) -> ValidationResult {
        ValidationResult(isSuccess: false, errorMessage: message, warnings: [], repository: nil)
    }
}
```

### Collection Handling and Relationship Management
```swift
// SwiftData relationship management
extension Project {
    // Computed properties for derived data
    var canClone: Bool {
        guard let repositoryURL = repositoryURL?.trimmingCharacters(in: .whitespacesAndNewlines),
              let localFolderPath = localFolderPath?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return false
        }
        
        return !repositoryURL.isEmpty &&
               !localFolderPath.isEmpty &&
               cloneStatus != .cloning
    }
    
    var repositoryLocalPath: String? {
        guard let localFolderPath = localFolderPath else { return nil }
        return "\(localFolderPath)/githubcontent"
    }
    
    var showroomLocalPath: String? {
        guard let repositoryPath = repositoryLocalPath else { return nil }
        return "\(repositoryPath)/content/modules/ROOT/pages"
    }
}

// Collection management with type safety
struct ProjectManager {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchProjects() throws -> [Project] {
        let descriptor = FetchDescriptor<Project>(
            sortBy: [SortDescriptor(\.modifiedDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func createProject(name: String) -> Project {
        let project = Project(name: name)
        modelContext.insert(project)
        return project
    }
    
    func deleteProject(_ project: Project) {
        modelContext.delete(project)
    }
}
```

### Language-Specific Features for Data Modeling
```swift
// Property wrappers for SwiftUI state management
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var projects: [Project]
    @State private var selectedProject: Project?
    @State private var inspectorState = InspectorState()
    
    var body: some View {
        NavigationSplitView {
            // Project list sidebar
        } detail: {
            // Project detail view
        }
        .inspector(isPresented: $inspectorState.isVisible) {
            // Inspector content
        }
    }
}

// Result type for error handling
enum ProjectError: Error, LocalizedError {
    case invalidConfiguration(String)
    case securityBookmarkExpired
    case repositoryNotFound
    case cloneOperationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let message):
            return "Configuration error: \(message)"
        case .securityBookmarkExpired:
            return "Folder access permissions have expired. Please reconfigure the local folder."
        case .repositoryNotFound:
            return "Repository not found or not accessible."
        case .cloneOperationFailed(let message):
            return "Clone operation failed: \(message)"
        }
    }
}
```

## 4. Swift-Specific Algorithm Contracts

### Function Signatures and Behavioral Requirements

#### Repository Processing Contracts
```swift
// Protocol definition for repository operations
protocol RepositoryProcessor {
    func validateRepository(at path: String) async throws -> ValidationResult
    func downloadRepository(from url: String, to localPath: String, project: Project) async -> Result<String, RepositoryError>
    func parseRepositoryContent(at path: String) async throws -> ShowroomRepository
}

// Concrete implementation contract
final class GitService: RepositoryProcessor {
    @MainActor
    func validateRepository(at path: String) async throws -> ValidationResult {
        // Implementation must:
        // 1. Check directory structure exists
        // 2. Validate required files (antora.yml, nav.adoc)
        // 3. Parse content using ShowroomParser
        // 4. Return detailed validation result
        // 5. Handle all file system errors gracefully
        
        guard FileManager.default.fileExists(atPath: path) else {
            return .failure("Repository directory does not exist")
        }
        
        // Additional validation logic...
        throw RepositoryError.notImplemented
    }
    
    func downloadRepository(from url: String, to localPath: String, project: Project) async -> Result<String, RepositoryError> {
        // Implementation must:
        // 1. Validate GitHub URL format
        // 2. Convert to archive download URL  
        // 3. Use security-scoped bookmark access
        // 4. Download and extract with progress tracking
        // 5. Handle network errors with retry logic
        
        return .failure(.notImplemented)
    }
    
    func parseRepositoryContent(at path: String) async throws -> ShowroomRepository {
        // Implementation must:
        // 1. Use ShowroomParser library integration
        // 2. Handle parsing errors gracefully
        // 3. Return structured content representation
        // 4. Support lazy loading for large repositories
        
        throw RepositoryError.notImplemented
    }
}

enum RepositoryError: Error {
    case invalidURL
    case networkFailure(String)
    case parseError(String) 
    case securityError(String)
    case notImplemented
}
```

#### LLM Integration Contracts
```swift
// Protocol for LLM service integration
protocol LLMService {
    func configure(endpoint: String, apiKey: String, model: String) throws
    func generateContent(prompt: String, content: String, temperature: Double) async throws -> LLMResponse
    func validateConnection() async throws -> Bool
}

// SwiftChatCompletionsDSL integration contract
final class LLMClient: LLMService {
    private var baseURL: String?
    private var apiKey: String?
    private var modelName: String?
    
    func configure(endpoint: String, apiKey: String, model: String) throws {
        // Implementation must:
        // 1. Validate URL format using URLComponents
        // 2. Store configuration securely
        // 3. Validate model name format
        // 4. Prepare for OpenAI-compatible API calls
        
        guard let url = URLComponents(string: endpoint),
              url.scheme != nil, url.host != nil else {
            throw LLMError.invalidEndpoint
        }
        
        self.baseURL = endpoint
        self.apiKey = apiKey
        self.modelName = model
    }
    
    func generateContent(prompt: String, content: String, temperature: Double) async throws -> LLMResponse {
        // Implementation must:
        // 1. Use SwiftChatCompletionsDSL for request building
        // 2. Handle authentication properly
        // 3. Format content with proper context
        // 4. Parse response and extract generated content
        // 5. Handle API errors with meaningful messages
        
        guard let baseURL = baseURL, let apiKey = apiKey, let modelName = modelName else {
            throw LLMError.notConfigured
        }
        
        let client = try LLMClient(baseURL: baseURL, apiKey: apiKey)
        
        let request = try ChatRequest(model: modelName) {
            try Temperature(temperature)
        } messages: {
            TextMessage(role: .system, content: "You are a helpful assistant that excels at generating compelling technical blog articles.")
            TextMessage(role: .user, content: prompt)
            TextMessage(role: .user, content: "Content to process: \(content)")
        }
        
        let response = try await client.complete(request)
        
        guard let choice = response.choices.first else {
            throw LLMError.noContentGenerated
        }
        
        return LLMResponse(content: choice.message.content, tokenUsage: response.usage?.totalTokens)
    }
    
    func validateConnection() async throws -> Bool {
        // Implementation must validate endpoint connectivity
        throw LLMError.notImplemented
    }
}

struct LLMResponse {
    let content: String
    let tokenUsage: Int?
}

enum LLMError: Error, LocalizedError {
    case invalidEndpoint
    case notConfigured
    case networkError(String)
    case apiError(Int, String)
    case noContentGenerated
    case notImplemented
    
    var errorDescription: String? {
        switch self {
        case .invalidEndpoint:
            return "Invalid LLM endpoint URL"
        case .notConfigured:
            return "LLM client not properly configured"
        case .networkError(let message):
            return "Network error: \(message)"
        case .apiError(let code, let message):
            return "API error \(code): \(message)"
        case .noContentGenerated:
            return "No content was generated by the LLM"
        case .notImplemented:
            return "Feature not implemented"
        }
    }
}
```

### Library Integration Patterns

#### ShowroomParser Integration
```swift
import ShowroomParser

extension Project {
    func parseShowroomContent() async throws -> ShowroomRepository {
        // Contract requirements:
        // 1. Use security-scoped bookmark access
        // 2. Call ShowroomParser.parseRepository with proper path
        // 3. Handle parsing errors with context
        // 4. Store result in transient property
        // 5. Return parsed repository for immediate use
        
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

#### YAML Processing Integration
```swift
import Yams

struct AntoraConfigParser {
    func parseConfiguration(from yamlString: String) throws -> AntoraConfig {
        // Contract requirements:
        // 1. Use Yams library for YAML parsing
        // 2. Handle malformed YAML gracefully
        // 3. Validate required fields exist
        // 4. Return structured configuration object
        // 5. Provide detailed error messages
        
        guard !yamlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw YAMLParseError.emptyString
        }
        
        do {
            let decoder = YAMLDecoder()
            let config = try decoder.decode(AntoraConfig.self, from: yamlString)
            
            // Validate required fields
            guard config.name != nil, config.version != nil else {
                throw YAMLParseError.invalidStructure("Missing required fields: name or version")
            }
            
            return config
        } catch let yamlError as YamlError {
            throw YAMLParseError.invalidYAML(yamlError.localizedDescription)
        } catch {
            throw YAMLParseError.parsingFailed(error)
        }
    }
}

struct AntoraConfig: Codable {
    let name: String?
    let title: String?
    let version: String?
    let nav: [String]?
    let asciidoc: AsciidocConfig?
}

enum YAMLParseError: Error, LocalizedError {
    case emptyString
    case invalidYAML(String)
    case invalidStructure(String)
    case parsingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .emptyString:
            return "Cannot parse empty YAML content"
        case .invalidYAML(let details):
            return "Invalid YAML format: \(details)"
        case .invalidStructure(let details):
            return "Invalid configuration structure: \(details)"
        case .parsingFailed(let error):
            return "YAML parsing failed: \(error.localizedDescription)"
        }
    }
}
```

### Language Idioms and Best Practices

#### Swift Concurrency Integration
```swift
// Actor for thread-safe repository operations
@MainActor
final class RepositoryManager: ObservableObject {
    @Published var downloadProgress: Double = 0.0
    @Published var currentOperation: String?
    
    func downloadRepository(project: Project) async throws -> String {
        // Contract requirements:
        // 1. Use @MainActor for UI updates
        // 2. Publish progress updates
        // 3. Handle cancellation properly
        // 4. Use structured concurrency
        // 5. Maintain thread safety
        
        currentOperation = "Initializing download..."
        downloadProgress = 0.0
        
        return try await withTaskCancellationHandler {
            // Actual download implementation
            try await performDownload(project: project)
        } onCancel: {
            self.currentOperation = "Cancelling..."
            // Cleanup logic
        }
    }
    
    private func performDownload(project: Project) async throws -> String {
        // Implementation with progress updates
        throw RepositoryError.notImplemented
    }
}

// Async sequence for streaming operations  
struct ContentProcessingSequence: AsyncSequence {
    typealias Element = ProcessingUpdate
    
    let repositoryPath: String
    
    func makeAsyncIterator() -> Iterator {
        Iterator(repositoryPath: repositoryPath)
    }
    
    struct Iterator: AsyncIteratorProtocol {
        let repositoryPath: String
        private var isFinished = false
        
        mutating func next() async throws -> ProcessingUpdate? {
            // Contract: Stream processing updates
            guard !isFinished else { return nil }
            
            // Implementation here...
            isFinished = true
            return nil
        }
    }
}

struct ProcessingUpdate {
    let stage: String
    let progress: Double
    let message: String
}
```

### Error Handling Patterns and Requirements

#### Result Type Usage
```swift
// Standardized result handling for async operations
extension Project {
    func cloneRepository() async -> Result<String, CloneError> {
        // Contract requirements:
        // 1. Use Result type for explicit error handling
        // 2. Provide detailed error information
        // 3. Handle all possible failure cases
        // 4. Update project state consistently
        // 5. Maintain operation atomicity
        
        guard let repositoryURL = repositoryURL,
              let localFolderPath = localFolderPath else {
            return .failure(.invalidConfiguration("Repository URL or local path not configured"))
        }
        
        updateCloneStatus(.cloning)
        
        do {
            let gitService = GitService()
            let result = await gitService.cloneRepository(from: repositoryURL, to: localFolderPath, project: self)
            
            switch result {
            case .success(let message):
                updateCloneStatus(.completed)
                return .success(message)
            case .failure(let error):
                updateCloneStatus(.failed, errorMessage: error.localizedDescription)
                return .failure(.operationFailed(error.localizedDescription))
            }
        } catch {
            updateCloneStatus(.failed, errorMessage: error.localizedDescription)
            return .failure(.unexpectedError(error))
        }
    }
}

enum CloneError: Error, LocalizedError {
    case invalidConfiguration(String)
    case operationFailed(String)
    case unexpectedError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let message):
            return "Configuration error: \(message)"
        case .operationFailed(let message):
            return "Clone operation failed: \(message)"
        case .unexpectedError(let error):
            return "Unexpected error: \(error.localizedDescription)"
        }
    }
}
```

#### Throwing Function Contracts
```swift
// File reading with proper error handling
func readProjectFile(_ project: Project, relativePath: String) throws -> String {
    // Contract requirements:
    // 1. Use security-scoped bookmark access
    // 2. Validate file existence and permissions
    // 3. Handle encoding errors gracefully
    // 4. Provide detailed error context
    // 5. Clean up resources properly
    
    guard let repositoryPath = project.repositoryLocalPath else {
        throw FileReadError.invalidProjectPath
    }
    
    let fullPath = URL(fileURLWithPath: repositoryPath)
        .appendingPathComponent(relativePath)
        .path
    
    do {
        return try String(contentsOfFile: fullPath, encoding: .utf8)
    } catch CocoaError.fileReadNoSuchFile {
        throw FileReadError.fileNotFound
    } catch CocoaError.fileReadNoPermission {
        throw FileReadError.readPermissionDenied
    } catch {
        if error.localizedDescription.contains("encoding") {
            throw FileReadError.invalidEncoding
        }
        throw FileReadError.unknownError(error)
    }
}

enum FileReadError: Error, LocalizedError {
    case invalidProjectPath
    case fileNotFound
    case readPermissionDenied
    case invalidEncoding
    case unknownError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidProjectPath:
            return "Invalid project local folder path"
        case .fileNotFound:
            return "File not found at specified path"
        case .readPermissionDenied:
            return "Permission denied reading file"
        case .invalidEncoding:
            return "File contains invalid text encoding"
        case .unknownError(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}
```

## 5. Platform-Specific Features

### Environment Detection and Conditional Compilation
```swift
// Platform-specific feature detection
#if os(macOS)
import AppKit

extension Project {
    func selectLocalFolder() -> String? {
        // Contract: Use NSOpenPanel for folder selection
        // Requirements:
        // 1. Configure panel for directory selection only
        // 2. Set appropriate prompts and titles
        // 3. Return selected path or nil
        // 4. Handle user cancellation gracefully
        
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose"
        panel.message = "Select a folder to store project files and repository clones."
        panel.title = "Choose Project Folder"
        
        guard panel.runModal() == .OK else {
            return nil
        }
        
        return panel.url?.path
    }
}
#else
extension Project {
    func selectLocalFolder() -> String? {
        // Fallback for non-macOS platforms
        return nil
    }
}
#endif

// Conditional feature availability
#if canImport(Playgrounds)
import Playgrounds

extension ContentView {
    func enablePlaygroundFeatures() {
        // Contract: Enable playground-specific debugging and testing
        // Only available when Playgrounds framework is present
    }
}
#endif
```

### Platform APIs and File System Operations
```swift
import Foundation

// Security-scoped bookmark handling (macOS specific)
extension Project {
    @MainActor
    func withSecureFolderAccess<T>(_ operation: @MainActor @Sendable () async throws -> T) async throws -> T {
        // Contract requirements:
        // 1. Resolve security-scoped bookmark
        // 2. Start accessing security-scoped resource
        // 3. Execute operation with proper cleanup
        // 4. Handle bookmark staleness and errors
        // 5. Ensure resource cleanup in all cases
        
        guard let bookmark = localFolderBookmark else {
            throw NSError(domain: "ProjectError", code: 1, 
                         userInfo: [NSLocalizedDescriptionKey: "No folder bookmark available. Please reconfigure the local folder."])
        }
        
        var isStale = false
        let url = try URL(resolvingBookmarkData: bookmark, 
                         options: .withSecurityScope, 
                         relativeTo: nil, 
                         bookmarkDataIsStale: &isStale)
        
        if isStale {
            throw NSError(domain: "ProjectError", code: 2,
                         userInfo: [NSLocalizedDescriptionKey: "Folder access permissions have expired. Please reconfigure the local folder."])
        }
        
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        guard didStartAccessing else {
            throw NSError(domain: "ProjectError", code: 3,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to access the selected folder. Please reconfigure the local folder."])
        }
        
        return try await operation()
    }
    
    func createSecurityBookmark(for url: URL) throws -> Data {
        // Contract: Create security-scoped bookmark for folder access
        // Requirements:
        // 1. Create bookmark with security scope
        // 2. Validate bookmark size (prevent data store issues)
        // 3. Handle bookmark creation failures
        // 4. Return bookmark data for storage
        
        let bookmark = try url.bookmarkData(options: .withSecurityScope, 
                                          includingResourceValuesForKeys: nil, 
                                          relativeTo: nil)
        
        // Validate bookmark size to prevent data store issues
        if bookmark.count > 1024 * 1024 { // 1MB limit
            print("WARNING: Created bookmark is too large (\(bookmark.count) bytes). This may cause data store issues.")
        }
        
        return bookmark
    }
}
```

### IDE Integration and Development Tools
```swift
// Xcode scheme configuration for development
/*
 Build Configuration:
 - Debug: Full debugging symbols, sandbox disabled for development
 - Release: Optimized, sandbox enabled, code signing for distribution
 
 Run Scheme Arguments:
 -com.apple.CoreData.SQLDebug 1  // Enable Core Data SQL logging
 -com.apple.CoreData.Logging.stderr 1  // Log to stderr
 */

// Development-only features
#if DEBUG
extension ContentView {
    private func createSampleProjectsIfNeeded() {
        // Contract: Create sample data for development only
        // Requirements:
        // 1. Only run in debug builds
        // 2. Check if projects already exist
        // 3. Create realistic sample data
        // 4. Don't interfere with production data
        
        guard projects.isEmpty else { return }
        
        let sampleProjects = [
            Project(name: "SwiftUI Documentation Generator"),
            Project(name: "iOS App Showcase"),
            Project(name: "API Reference Builder")
        ]
        
        for project in sampleProjects {
            modelContext.insert(project)
        }
        
        try? modelContext.save()
    }
}
#endif

// Logging and debugging support
import os.log

extension Logger {
    static let projectManagement = Logger(subsystem: "com.example.ShowroomAgentMVP", category: "ProjectManagement")
    static let contentGeneration = Logger(subsystem: "com.example.ShowroomAgentMVP", category: "ContentGeneration")
    static let networkOperations = Logger(subsystem: "com.example.ShowroomAgentMVP", category: "Network")
}

// Usage in implementation
func downloadRepository() async {
    Logger.networkOperations.info("Starting repository download for project: \(project.name)")
    
    // Implementation...
    
    Logger.networkOperations.debug("Download completed successfully")
}
```

### Cross-Platform Considerations
```swift
// Abstraction layer for platform differences
protocol PlatformServices {
    func selectFolder() async -> URL?
    func createSecurityBookmark(for url: URL) throws -> Data?
    func accessSecureResource<T>(bookmark: Data, operation: () throws -> T) throws -> T
}

#if os(macOS)
final class MacOSPlatformServices: PlatformServices {
    func selectFolder() async -> URL? {
        // Use NSOpenPanel implementation
        return await MainActor.run {
            let panel = NSOpenPanel()
            // Configure panel...
            return panel.runModal() == .OK ? panel.url : nil
        }
    }
    
    func createSecurityBookmark(for url: URL) throws -> Data? {
        return try url.bookmarkData(options: .withSecurityScope, 
                                   includingResourceValuesForKeys: nil, 
                                   relativeTo: nil)
    }
    
    func accessSecureResource<T>(bookmark: Data, operation: () throws -> T) throws -> T {
        // Security-scoped resource access implementation
        var isStale = false
        let url = try URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
        
        let didStart = url.startAccessingSecurityScopedResource()
        defer {
            if didStart {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        return try operation()
    }
}
#endif

// Dependency injection for platform services
extension App {
    var platformServices: PlatformServices {
        #if os(macOS)
        return MacOSPlatformServices()
        #else
        return DefaultPlatformServices()  // Stub implementation
        #endif
    }
}
```

## 6. Swift-Specific Testing Contracts

### Testing Framework Integration
```swift
import Testing
import Foundation
@testable import ShowroomAgentMVP

// Swift Testing framework usage (not XCTest)
@Suite("Project Management Tests")
struct ProjectManagementTests {
    
    @Test("Project creation with valid name")
    func testProjectCreation() async throws {
        // Contract: Test project creation functionality
        // Requirements:
        // 1. Create project with valid name
        // 2. Verify all properties are set correctly
        // 3. Ensure timestamps are current
        // 4. Validate default values
        
        let projectName = "Test Project"
        let project = Project(name: projectName)
        
        #expect(project.name == projectName)
        #expect(project.repositoryURL == nil)
        #expect(project.localFolderPath == nil)
        #expect(project.cloneStatus == .notStarted)
        #expect(project.createdDate <= Date())
        #expect(project.modifiedDate <= Date())
        #expect(project.temperature == 0.7)
    }
    
    @Test("Repository URL validation", arguments: [
        ("https://github.com/user/repo", true),
        ("https://github.com/user/repo.git", true),
        ("invalid-url", false),
        ("", false)
    ])
    func testRepositoryURLValidation(url: String, shouldBeValid: Bool) {
        // Contract: Validate repository URL format
        let isValid = isValidGitHubURL(url)
        #expect(isValid == shouldBeValid)
    }
    
    @Test("Clone status transitions")
    func testCloneStatusTransitions() async {
        // Contract: Test state machine for clone operations
        let project = Project(name: "Test")
        
        #expect(project.cloneStatus == .notStarted)
        
        project.updateCloneStatus(.cloning)
        #expect(project.cloneStatus == .cloning)
        
        project.updateCloneStatus(.completed)
        #expect(project.cloneStatus == .completed)
        #expect(project.lastClonedDate != nil)
        #expect(project.cloneErrorMessage == nil)
        
        project.updateCloneStatus(.failed, errorMessage: "Test error")
        #expect(project.cloneStatus == .failed)
        #expect(project.cloneErrorMessage == "Test error")
    }
}

@Suite("Content Generation Tests")
struct ContentGenerationTests {
    
    @Test("LLM configuration validation")
    func testLLMConfiguration() {
        // Contract: Test LLM configuration validation
        let validConfig = LLMConfiguration(
            endpointURL: "https://api.openai.com/v1/chat/completions",
            modelName: "gpt-4",
            apiKey: "sk-test-key",
            temperature: 0.7
        )
        
        #expect(validConfig.isValid)
        
        let invalidConfig = LLMConfiguration(
            endpointURL: "",
            modelName: "",
            apiKey: "key",
            temperature: 3.0  // Invalid temperature
        )
        
        #expect(!invalidConfig.isValid)
    }
    
    @Test("Content parsing with ShowroomParser")
    func testContentParsing() async throws {
        // Contract: Test integration with ShowroomParser
        // Requirements:
        // 1. Create mock repository structure
        // 2. Test parsing with valid content
        // 3. Test error handling with invalid content
        // 4. Verify parsed content structure
        
        let mockRepoPath = createMockRepository()
        defer { cleanupMockRepository(mockRepoPath) }
        
        let parsedRepo = ShowroomParser.parseRepository(at: mockRepoPath)
        #expect(parsedRepo != nil)
        
        let markdownContent = parsedRepo?.toMarkdown()
        #expect(markdownContent?.isEmpty == false)
    }
}
```

### Language Testing Idioms and Patterns
```swift
// Mock objects using Swift protocols
protocol MockLLMService: LLMService {
    var shouldSucceed: Bool { get set }
    var mockResponse: String { get set }
}

final class TestLLMService: MockLLMService {
    var shouldSucceed: Bool = true
    var mockResponse: String = "Mock generated content"
    
    func configure(endpoint: String, apiKey: String, model: String) throws {
        // Mock implementation
    }
    
    func generateContent(prompt: String, content: String, temperature: Double) async throws -> LLMResponse {
        if shouldSucceed {
            return LLMResponse(content: mockResponse, tokenUsage: 100)
        } else {
            throw LLMError.networkError("Mock network error")
        }
    }
    
    func validateConnection() async throws -> Bool {
        return shouldSucceed
    }
}

// Test helpers using Swift features
extension Testing {
    static func createTestProject(name: String = "Test Project") -> Project {
        let project = Project(name: name)
        project.repositoryURL = "https://github.com/test/repo"
        project.localFolderPath = "/tmp/test"
        return project
    }
    
    static func createMockRepository() -> String {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        // Create mock Antora structure
        let contentDir = tempDir.appendingPathComponent("content")
        let modulesDir = contentDir.appendingPathComponent("modules/ROOT")
        let pagesDir = modulesDir.appendingPathComponent("pages")
        
        try! FileManager.default.createDirectory(at: pagesDir, withIntermediateDirectories: true)
        
        // Create mock files
        let antoraYml = """
        name: test-module
        title: Test Module
        version: 1.0.0
        nav:
        - modules/ROOT/nav.adoc
        """
        
        try! antoraYml.write(to: contentDir.appendingPathComponent("antora.yml"), atomically: true, encoding: .utf8)
        
        let navAdoc = """
        * xref:index.adoc[Introduction]
        * xref:guide.adoc[User Guide]
        """
        
        try! navAdoc.write(to: modulesDir.appendingPathComponent("nav.adoc"), atomically: true, encoding: .utf8)
        
        return tempDir.path
    }
    
    static func cleanupMockRepository(_ path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }
}

// Async testing patterns
@Suite("Async Operations Tests")
struct AsyncOperationTests {
    
    @Test("Repository download with timeout")
    func testRepositoryDownloadTimeout() async throws {
        // Contract: Test async operations with proper timeout handling
        let project = Testing.createTestProject()
        let gitService = GitService()
        
        let result = await withTimeout(of: .seconds(30)) {
            await gitService.cloneRepository(from: project.repositoryURL!, to: project.localFolderPath!, project: project)
        }
        
        // Verify result handling
        switch result {
        case .success:
            break  // Expected for mock
        case .failure(let error):
            #expect(error.localizedDescription.contains("timeout") || error.localizedDescription.contains("network"))
        }
    }
    
    @Test("Concurrent content processing")
    func testConcurrentProcessing() async throws {
        // Contract: Test concurrent operations don't interfere
        let projects = (1...5).map { Testing.createTestProject(name: "Project \($0)") }
        
        await withTaskGroup(of: Void.self) { group in
            for project in projects {
                group.addTask {
                    // Simulate concurrent validation
                    let result = await validateProject(project)
                    // Verify no data races
                }
            }
        }
    }
}

// Helper function for timeout testing
func withTimeout<T>(of duration: Duration, operation: @escaping () async throws -> T) async throws -> T {
    return try await withThrowingTimeout(of: duration) {
        try await operation()
    }
}
```

### Mock and Test Data Management
```swift
// Test data factory
struct TestDataFactory {
    static func createValidAntoraRepository() -> URL {
        // Contract: Create complete valid repository structure
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-repo-\(UUID().uuidString)")
        
        // Create directory structure
        let contentURL = tempURL.appendingPathComponent("content")
        let modulesURL = contentURL.appendingPathComponent("modules/ROOT")
        let pagesURL = modulesURL.appendingPathComponent("pages")
        
        try! FileManager.default.createDirectory(at: pagesURL, withIntermediateDirectories: true)
        
        // Create configuration files
        createAntoraConfig(at: contentURL)
        createNavigation(at: modulesURL)
        createSamplePages(at: pagesURL)
        
        return tempURL
    }
    
    private static func createAntoraConfig(at url: URL) {
        let config = """
        name: sample-docs
        title: Sample Documentation
        version: 1.0.0
        nav:
        - modules/ROOT/nav.adoc
        asciidoc:
          attributes:
            lab_name: Sample Lab
            release-version: 1.0.0
        """
        
        let configURL = url.appendingPathComponent("antora.yml")
        try! config.write(to: configURL, atomically: true, encoding: .utf8)
    }
    
    private static func createNavigation(at url: URL) {
        let nav = """
        * xref:index.adoc[Getting Started]
        * xref:installation.adoc[Installation Guide]
        * xref:tutorial.adoc[Tutorial]
        * xref:api-reference.adoc[API Reference]
        """
        
        let navURL = url.appendingPathComponent("nav.adoc")
        try! nav.write(to: navURL, atomically: true, encoding: .utf8)
    }
    
    private static func createSamplePages(at url: URL) {
        let pages = [
            ("index.adoc", sampleIndexContent),
            ("installation.adoc", sampleInstallationContent),
            ("tutorial.adoc", sampleTutorialContent),
            ("api-reference.adoc", sampleAPIContent)
        ]
        
        for (filename, content) in pages {
            let pageURL = url.appendingPathComponent(filename)
            try! content.write(to: pageURL, atomically: true, encoding: .utf8)
        }
    }
    
    private static let sampleIndexContent = """
    = Getting Started
    
    Welcome to the sample documentation. This guide will help you understand the basics.
    
    == Overview
    
    This is a comprehensive guide covering all aspects of the system.
    """
    
    // Additional sample content...
}

// Test configuration management
final class TestConfiguration {
    static let shared = TestConfiguration()
    
    var mockLLMEndpoint = "http://localhost:8080/v1/chat/completions"
    var mockAPIKey = "test-api-key"
    var mockModelName = "test-model"
    var useRealNetwork = false
    
    func setupTestEnvironment() {
        // Contract: Configure test environment consistently
        if !useRealNetwork {
            // Setup URL session mocking
            URLProtocol.registerClass(MockURLProtocol.self)
        }
    }
    
    func teardownTestEnvironment() {
        if !useRealNetwork {
            URLProtocol.unregisterClass(MockURLProtocol.self)
        }
    }
}

// Mock URL protocol for network testing
final class MockURLProtocol: URLProtocol {
    static var mockResponses: [URL: (Data, HTTPURLResponse)] = [:]
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let url = request.url,
              let (data, response) = Self.mockResponses[url] else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "MockError", code: 404))
            return
        }
        
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {
        // No-op for mock
    }
}
```

### Type-Safe Assertion Patterns
```swift
// Custom expectation helpers for domain-specific testing
extension Testing {
    static func expectValidProject(_ project: Project) {
        #expect(!project.name.isEmpty, "Project name should not be empty")
        #expect(project.createdDate <= Date(), "Created date should not be in the future")
        #expect(project.modifiedDate >= project.createdDate, "Modified date should be after created date")
        #expect(project.temperature >= 0.0 && project.temperature <= 2.0, "Temperature should be in valid range")
    }
    
    static func expectValidRepositoryStructure(at path: String) throws {
        let fileManager = FileManager.default
        
        #expect(fileManager.fileExists(atPath: path), "Repository path should exist")
        
        let contentPath = "\(path)/content"
        #expect(fileManager.fileExists(atPath: contentPath), "Content directory should exist")
        
        let configPath = "\(contentPath)/antora.yml"
        #expect(fileManager.fileExists(atPath: configPath), "Antora config should exist")
        
        let navPath = "\(contentPath)/modules/ROOT/nav.adoc"
        #expect(fileManager.fileExists(atPath: navPath), "Navigation file should exist")
        
        let pagesPath = "\(contentPath)/modules/ROOT/pages"
        #expect(fileManager.fileExists(atPath: pagesPath), "Pages directory should exist")
        
        let pageContents = try fileManager.contentsOfDirectory(atPath: pagesPath)
        #expect(!pageContents.isEmpty, "Pages directory should contain files")
    }
    
    static func expectValidLLMResponse(_ response: LLMResponse) {
        #expect(!response.content.isEmpty, "LLM response content should not be empty")
        #expect(response.content.count > 100, "LLM response should be substantial")
        #expect(response.tokenUsage ?? 0 > 0, "Token usage should be reported")
    }
    
    static func expectValidMarkdown(_ content: String) {
        #expect(content.contains("#") || content.contains("*") || content.contains("-"), 
               "Content should contain markdown formatting")
        #expect(content.count > 50, "Generated content should be substantial")
        #expect(!content.contains("<script>"), "Content should not contain unsafe HTML")
    }
}

// Parameterized testing for comprehensive coverage
@Suite("Repository Validation Tests")
struct RepositoryValidationTests {
    
    @Test("Repository structure validation", arguments: [
        ("valid-complete", true),
        ("missing-config", false),
        ("missing-nav", false),
        ("empty-pages", false),
        ("invalid-yaml", false)
    ])
    func testRepositoryValidation(repoType: String, shouldPass: Bool) async throws {
        let repoPath = createTestRepository(type: repoType)
        defer { cleanupTestRepository(repoPath) }
        
        let validationResult = await validateRepositoryStructure(repoPath)
        
        if shouldPass {
            #expect(validationResult.isSuccess, "Repository should pass validation")
        } else {
            #expect(!validationResult.isSuccess, "Repository should fail validation")
            #expect(validationResult.errorMessage != nil, "Should provide error message")
        }
    }
    
    private func createTestRepository(type: String) -> String {
        // Create repository based on type for testing different scenarios
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-\(type)-\(UUID().uuidString)")
        
        switch type {
        case "valid-complete":
            return TestDataFactory.createValidAntoraRepository().path
        case "missing-config":
            return createRepositoryWithoutConfig(at: tempDir)
        case "missing-nav":
            return createRepositoryWithoutNav(at: tempDir)
        case "empty-pages":
            return createRepositoryWithEmptyPages(at: tempDir)
        case "invalid-yaml":
            return createRepositoryWithInvalidYAML(at: tempDir)
        default:
            return TestDataFactory.createValidAntoraRepository().path
        }
    }
    
    // Helper methods for creating specific test scenarios...
    private func createRepositoryWithoutConfig(at url: URL) -> String {
        // Implementation for testing missing config scenario
        return url.path
    }
    
    private func createRepositoryWithoutNav(at url: URL) -> String {
        // Implementation for testing missing navigation scenario
        return url.path
    }
    
    private func createRepositoryWithEmptyPages(at url: URL) -> String {
        // Implementation for testing empty pages scenario
        return url.path
    }
    
    private func createRepositoryWithInvalidYAML(at url: URL) -> String {
        // Implementation for testing invalid YAML scenario
        return url.path
    }
    
    private func cleanupTestRepository(_ path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }
}
```

## 7. Performance Optimization Contracts for Swift

### Language-Specific Optimization Requirements
```swift
// Memory management strategy for large repositories
final class ContentCache {
    private let cache = NSCache<NSString, ContentItem>()
    private let queue = DispatchQueue(label: "content-cache", qos: .utility)
    
    init() {
        // Contract: Configure cache limits based on available memory
        cache.countLimit = 100  // Maximum number of items
        cache.totalCostLimit = 50 * 1024 * 1024  // 50MB memory limit
        
        // Setup memory pressure handling
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        // Contract: Respond to memory pressure by clearing cache
        queue.async {
            self.cache.removeAllObjects()
        }
    }
    
    func store(_ content: ContentItem, forKey key: String) {
        // Contract: Store content with proper cost calculation
        let cost = content.estimatedMemoryUsage
        queue.async {
            self.cache.setObject(content, forKey: key as NSString, cost: cost)
        }
    }
    
    func retrieve(forKey key: String) -> ContentItem? {
        return queue.sync {
            cache.object(forKey: key as NSString)
        }
    }
}

// Lazy loading implementation for repository content
struct LazyRepositoryContent {
    private let repositoryPath: String
    private var _parsedContent: ShowroomRepository?
    private let parseQueue = DispatchQueue(label: "repository-parsing", qos: .userInitiated)
    
    init(repositoryPath: String) {
        self.repositoryPath = repositoryPath
    }
    
    var parsedContent: ShowroomRepository {
        get async throws {
            // Contract: Parse content only when needed, cache result
            if let cached = _parsedContent {
                return cached
            }
            
            return try await withTaskCancellationHandler {
                try await parseQueue.async {
                    let content = ShowroomParser.parseRepository(at: repositoryPath)
                    self._parsedContent = content
                    return content
                }
            } onCancel: {
                // Handle cancellation
            }
        }
    }
    
    mutating func invalidate() {
        // Contract: Clear cached content to free memory
        _parsedContent = nil
    }
}
```

### Memory Management Strategy Contracts
```swift
// Automatic memory management for content generation
@MainActor
final class ContentGenerationManager: ObservableObject {
    @Published var isGenerating = false
    @Published var progress: Double = 0.0
    
    private var currentTask: Task<String, Error>?
    private let memoryManager = MemoryManager()
    
    func generateContent(project: Project) async throws -> String {
        // Contract: Manage memory during content generation
        // Requirements:
        // 1. Monitor memory usage during operation
        // 2. Use autoreleasepool for large operations
        // 3. Clean up temporary data promptly
        // 4. Handle memory warnings gracefully
        
        isGenerating = true
        defer { isGenerating = false }
        
        return try await autoreleasepool {
            try await memoryManager.withMemoryManagement {
                try await performContentGeneration(project: project)
            }
        }
    }
    
    private func performContentGeneration(project: Project) async throws -> String {
        // Implementation with memory monitoring
        memoryManager.beginMonitoring()
        defer { memoryManager.endMonitoring() }
        
        // Chunked processing for large repositories
        guard let repository = project.showroomRepository else {
            throw ContentGenerationError.repositoryNotParsed
        }
        
        let markdownContent = try await processRepositoryInChunks(repository)
        
        return try await generateWithLLM(content: markdownContent, project: project)
    }
    
    private func processRepositoryInChunks(_ repository: ShowroomRepository) async throws -> String {
        // Contract: Process content in memory-efficient chunks
        let chunkSize = memoryManager.optimalChunkSize
        var result = ""
        
        for chunk in repository.contentChunks(size: chunkSize) {
            autoreleasepool {
                result += chunk.toMarkdown()
            }
            
            // Yield control to allow memory cleanup
            await Task.yield()
            
            // Check memory pressure
            if memoryManager.isUnderMemoryPressure {
                try Task.checkCancellation()
                await Task.sleep(nanoseconds: 100_000_000) // 100ms
            }
        }
        
        return result
    }
}

// Memory monitoring utility
final class MemoryManager {
    private var isMonitoring = false
    private let memoryPressureSource: DispatchSourceMemoryPressure
    
    var isUnderMemoryPressure: Bool {
        // Check system memory pressure
        return ProcessInfo.processInfo.thermalState != .nominal
    }
    
    var optimalChunkSize: Int {
        // Calculate optimal chunk size based on available memory
        let availableMemory = ProcessInfo.processInfo.physicalMemory
        return max(1024, Int(availableMemory / 1000))  // Conservative sizing
    }
    
    init() {
        memoryPressureSource = DispatchSource.makeMemoryPressureSource(
            eventMask: [.warning, .critical],
            queue: .global(qos: .utility)
        )
        
        memoryPressureSource.setEventHandler { [weak self] in
            self?.handleMemoryPressure()
        }
    }
    
    func beginMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        memoryPressureSource.resume()
    }
    
    func endMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        memoryPressureSource.suspend()
    }
    
    private func handleMemoryPressure() {
        // Contract: Respond to memory pressure events
        NotificationCenter.default.post(name: .memoryPressureDetected, object: nil)
    }
    
    func withMemoryManagement<T>(_ operation: () async throws -> T) async throws -> T {
        beginMonitoring()
        defer { endMonitoring() }
        
        return try await operation()
    }
}

extension Notification.Name {
    static let memoryPressureDetected = Notification.Name("memoryPressureDetected")
}
```

### Concurrency and Parallelism Contracts
```swift
// Structured concurrency for repository operations
actor RepositoryProcessor {
    private var activeOperations: Set<UUID> = []
    private let maxConcurrentOperations = 3
    
    func processRepositories(_ repositories: [String]) async throws -> [ProcessingResult] {
        // Contract: Process repositories with controlled concurrency
        // Requirements:
        // 1. Limit concurrent operations to prevent resource exhaustion
        // 2. Use structured concurrency for proper cancellation
        // 3. Collect results from all operations
        // 4. Handle individual failures gracefully
        
        return try await withThrowingTaskGroup(of: ProcessingResult.self) { group in
            var results: [ProcessingResult] = []
            
            for repository in repositories {
                // Respect concurrency limit
                while activeOperations.count >= maxConcurrentOperations {
                    _ = try await group.next()
                    results.append(try await group.next()!)
                }
                
                let operationId = UUID()
                activeOperations.insert(operationId)
                
                group.addTask { [weak self] in
                    defer {
                        Task { await self?.completeOperation(operationId) }
                    }
                    
                    return try await self?.processRepository(repository) ?? .failure("Actor deallocated")
                }
            }
            
            // Collect remaining results
            for try await result in group {
                results.append(result)
            }
            
            return results
        }
    }
    
    private func processRepository(_ path: String) async throws -> ProcessingResult {
        // Implementation with proper error handling
        do {
            let content = ShowroomParser.parseRepository(at: path)
            return .success(content)
        } catch {
            return .failure(error.localizedDescription)
        }
    }
    
    private func completeOperation(_ id: UUID) {
        activeOperations.remove(id)
    }
}

enum ProcessingResult {
    case success(ShowroomRepository?)
    case failure(String)
}

// Main actor coordination for UI updates
@MainActor
final class ContentGenerationCoordinator: ObservableObject {
    @Published var overallProgress: Double = 0.0
    @Published var currentOperation: String = ""
    @Published var results: [GenerationResult] = []
    
    private let repositoryProcessor = RepositoryProcessor()
    
    func coordinateGeneration(for projects: [Project]) async {
        // Contract: Coordinate multiple generation tasks with UI updates
        // Requirements:
        // 1. Update UI on main actor
        // 2. Coordinate background processing
        // 3. Aggregate results from multiple sources
        // 4. Handle cancellation properly
        
        let totalProjects = projects.count
        var completedProjects = 0
        
        currentOperation = "Starting content generation..."
        overallProgress = 0.0
        
        await withTaskGroup(of: GenerationResult.self) { group in
            for project in projects {
                group.addTask { [weak self] in
                    let result = await self?.generateContentForProject(project) ?? .failure("Coordinator deallocated")
                    
                    await MainActor.run {
                        completedProjects += 1
                        self?.overallProgress = Double(completedProjects) / Double(totalProjects)
                        self?.currentOperation = "Completed \(completedProjects) of \(totalProjects) projects"
                    }
                    
                    return result
                }
            }
            
            for await result in group {
                results.append(result)
            }
        }
        
        currentOperation = "Generation complete"
        overallProgress = 1.0
    }
    
    private func generateContentForProject(_ project: Project) async -> GenerationResult {
        // Implementation for individual project generation
        return .success("Generated content for \(project.name)")
    }
}

enum GenerationResult {
    case success(String)
    case failure(String)
}
```

### Profiling and Debugging Requirements
```swift
import os.signpost

// Performance measurement and profiling
final class PerformanceProfiler {
    private let log = OSLog(subsystem: "com.example.ShowroomAgentMVP", category: "Performance")
    private var activeOperations: [String: OSSignpostID] = [:]
    
    func beginOperation(_ name: String) -> OSSignpostID {
        // Contract: Start performance measurement for operation
        let signpostID = OSSignpostID(log: log)
        activeOperations[name] = signpostID
        
        os_signpost(.begin, log: log, name: "ContentGeneration", signpostID: signpostID, 
                   "Starting operation: %{public}s", name)
        
        return signpostID
    }
    
    func endOperation(_ name: String, metrics: [String: Any] = [:]) {
        // Contract: End performance measurement with metrics
        guard let signpostID = activeOperations.removeValue(forKey: name) else { return }
        
        var metricString = ""
        for (key, value) in metrics {
            metricString += "\(key): \(value), "
        }
        
        os_signpost(.end, log: log, name: "ContentGeneration", signpostID: signpostID,
                   "Completed operation: %{public}s, metrics: %{public}s", name, metricString)
    }
    
    func measureOperation<T>(_ name: String, operation: () async throws -> T) async rethrows -> T {
        // Contract: Measure async operation automatically
        let signpostID = beginOperation(name)
        defer { endOperation(name) }
        
        return try await operation()
    }
    
    func measureMemoryUsage() -> MemoryMetrics {
        // Contract: Capture current memory usage metrics
        let info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return MemoryMetrics(
            residentSize: Int(info.resident_size),
            virtualSize: Int(info.virtual_size),
            isValid: result == KERN_SUCCESS
        )
    }
}

struct MemoryMetrics {
    let residentSize: Int
    let virtualSize: Int
    let isValid: Bool
    
    var residentSizeMB: Double {
        Double(residentSize) / (1024 * 1024)
    }
    
    var virtualSizeMB: Double {
        Double(virtualSize) / (1024 * 1024)
    }
}

// Debugging support with conditional compilation
#if DEBUG
extension ContentView {
    private var debugControls: some View {
        VStack {
            Button("Simulate Memory Pressure") {
                NotificationCenter.default.post(name: .memoryPressureDetected, object: nil)
            }
            
            Button("Profile Content Generation") {
                Task {
                    let profiler = PerformanceProfiler()
                    await profiler.measureOperation("FullGeneration") {
                        // Perform generation with profiling
                    }
                }
            }
            
            Button("Dump Memory Metrics") {
                let profiler = PerformanceProfiler()
                let metrics = profiler.measureMemoryUsage()
                print("Memory Usage: \(metrics.residentSizeMB)MB resident, \(metrics.virtualSizeMB)MB virtual")
            }
        }
    }
}
#endif
```

## 8. Extension-Based Architecture Contracts

### Language Extension Patterns
```swift
// Protocol-oriented architecture for extensibility
protocol ContentGenerator {
    associatedtype Input
    associatedtype Output
    
    func generate(from input: Input) async throws -> Output
    func validate(input: Input) throws -> ValidationResult
    func configure(settings: GenerationSettings) throws
}

// Blog content generator implementation
struct BlogContentGenerator: ContentGenerator {
    typealias Input = ShowroomRepository
    typealias Output = BlogContent
    
    private let llmService: LLMService
    private var settings: BlogGenerationSettings
    
    init(llmService: LLMService, settings: BlogGenerationSettings = .default) {
        self.llmService = llmService
        self.settings = settings
    }
    
    func generate(from input: ShowroomRepository) async throws -> BlogContent {
        // Contract: Generate blog content from repository
        let prompt = settings.buildPrompt()
        let content = input.toMarkdown()
        
        let response = try await llmService.generateContent(
            prompt: prompt,
            content: content,
            temperature: settings.temperature
        )
        
        return BlogContent(
            title: extractTitle(from: response.content),
            body: response.content,
            metadata: BlogMetadata(
                generatedAt: Date(),
                tokenUsage: response.tokenUsage,
                sourceRepository: input.name
            )
        )
    }
    
    func validate(input: ShowroomRepository) throws -> ValidationResult {
        // Contract: Validate input repository for blog generation
        guard !input.pages.isEmpty else {
            throw ValidationError.emptyRepository
        }
        
        guard input.totalWordCount > settings.minimumWordCount else {
            throw ValidationError.insufficientContent
        }
        
        return .valid
    }
    
    func configure(settings: GenerationSettings) throws {
        guard let blogSettings = settings as? BlogGenerationSettings else {
            throw ConfigurationError.invalidSettingsType
        }
        self.settings = blogSettings
    }
    
    private func extractTitle(from content: String) -> String {
        // Extract title from generated content
        return content.components(separatedBy: "\n").first { $0.hasPrefix("#") } ?? "Generated Article"
    }
}

// Social media content generator
struct SocialMediaGenerator: ContentGenerator {
    typealias Input = ShowroomRepository
    typealias Output = SocialMediaContent
    
    // Implementation following same contract pattern
    func generate(from input: ShowroomRepository) async throws -> SocialMediaContent {
        // Contract: Generate social media posts from repository
        throw GenerationError.notImplemented
    }
    
    func validate(input: ShowroomRepository) throws -> ValidationResult {
        // Contract: Validate for social media generation
        throw ValidationError.notImplemented
    }
    
    func configure(settings: GenerationSettings) throws {
        // Contract: Configure social media generation
        throw ConfigurationError.notImplemented
    }
}
```

### Domain-Specific Language Features
```swift
// DSL for content generation configuration
@resultBuilder
struct ContentGenerationBuilder {
    static func buildBlock(_ components: GenerationStep...) -> GenerationPipeline {
        GenerationPipeline(steps: components)
    }
    
    static func buildOptional(_ component: GenerationStep?) -> GenerationStep? {
        component
    }
    
    static func buildEither(first component: GenerationStep) -> GenerationStep {
        component
    }
    
    static func buildEither(second component: GenerationStep) -> GenerationStep {
        component
    }
}

struct GenerationPipeline {
    let steps: [GenerationStep]
    
    func execute(with input: ShowroomRepository) async throws -> GenerationResult {
        var currentInput: Any = input
        
        for step in steps {
            currentInput = try await step.execute(input: currentInput)
        }
        
        guard let result = currentInput as? GenerationResult else {
            throw PipelineError.invalidFinalResult
        }
        
        return result
    }
}

protocol GenerationStep {
    func execute(input: Any) async throws -> Any
}

// Usage example with DSL
func createBlogGenerationPipeline() -> GenerationPipeline {
    @ContentGenerationBuilder
    func buildPipeline() -> GenerationPipeline {
        ValidateRepositoryStep()
        
        if shouldIncludeCodeExamples {
            ExtractCodeExamplesStep()
        }
        
        GenerateContentStep(style: .blog)
        FormatMarkdownStep()
        ValidateOutputStep()
    }
    
    return buildPipeline()
}

// Concrete step implementations
struct ValidateRepositoryStep: GenerationStep {
    func execute(input: Any) async throws -> Any {
        guard let repository = input as? ShowroomRepository else {
            throw StepError.invalidInput
        }
        
        // Validation logic
        return repository
    }
}

struct GenerateContentStep: GenerationStep {
    let style: ContentStyle
    
    func execute(input: Any) async throws -> Any {
        // Generation logic based on style
        throw StepError.notImplemented
    }
}

enum ContentStyle {
    case blog
    case socialMedia
    case email
    case presentation
}
```

### Code Organization Strategy Requirements
```swift
// Modular architecture with clear separation of concerns
// Feature-based module organization

// MARK: - Core Domain
protocol ProjectRepository {
    func create(_ project: Project) async throws
    func fetch(by id: UUID) async throws -> Project?
    func fetchAll() async throws -> [Project]
    func update(_ project: Project) async throws
    func delete(_ project: Project) async throws
}

protocol ContentGenerationUseCase {
    func generateContent(for project: Project, type: ContentType) async throws -> GeneratedContent
}

// MARK: - Infrastructure Layer
final class SwiftDataProjectRepository: ProjectRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func create(_ project: Project) async throws {
        modelContext.insert(project)
        try modelContext.save()
    }
    
    func fetch(by id: UUID) async throws -> Project? {
        let descriptor = FetchDescriptor<Project>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    // Additional implementation...
}

// MARK: - Application Layer
final class ContentGenerationService: ContentGenerationUseCase {
    private let projectRepository: ProjectRepository
    private let contentGenerators: [ContentType: any ContentGenerator]
    
    init(projectRepository: ProjectRepository) {
        self.projectRepository = projectRepository
        self.contentGenerators = [
            .blog: BlogContentGenerator(llmService: LLMClientService()),
            .socialMedia: SocialMediaGenerator(),
            .email: EmailContentGenerator()
        ]
    }
    
    func generateContent(for project: Project, type: ContentType) async throws -> GeneratedContent {
        // Contract: Coordinate content generation across different types
        guard let generator = contentGenerators[type] else {
            throw ServiceError.unsupportedContentType(type)
        }
        
        // Implementation using dependency injection
        throw ServiceError.notImplemented
    }
}

// MARK: - Presentation Layer  
struct ContentGenerationView: View {
    @StateObject private var viewModel: ContentGenerationViewModel
    
    init(project: Project, useCase: ContentGenerationUseCase) {
        self._viewModel = StateObject(wrappedValue: ContentGenerationViewModel(
            project: project,
            useCase: useCase
        ))
    }
    
    var body: some View {
        // UI implementation
        Text("Content Generation")
    }
}

@MainActor
final class ContentGenerationViewModel: ObservableObject {
    @Published var isGenerating = false
    @Published var generatedContent: GeneratedContent?
    @Published var error: Error?
    
    private let project: Project
    private let useCase: ContentGenerationUseCase
    
    init(project: Project, useCase: ContentGenerationUseCase) {
        self.project = project
        self.useCase = useCase
    }
    
    func generateContent(type: ContentType) async {
        // Contract: Handle UI interaction and state management
        isGenerating = true
        error = nil
        
        do {
            generatedContent = try await useCase.generateContent(for: project, type: type)
        } catch {
            self.error = error
        }
        
        isGenerating = false
    }
}
```

### API Design Principle Specifications
```swift
// Fluent API design for configuration
struct ProjectConfigurationBuilder {
    private var project: Project
    
    init(name: String) {
        self.project = Project(name: name)
    }
    
    func withRepository(_ url: String) -> ProjectConfigurationBuilder {
        project.repositoryURL = url
        return self
    }
    
    func withLocalFolder(_ path: String) -> ProjectConfigurationBuilder {
        project.localFolderPath = path
        return self
    }
    
    func withLLMConfiguration(_ config: LLMConfiguration) -> ProjectConfigurationBuilder {
        project.llmUrl = config.endpointURL
        project.llmModelName = config.modelName
        project.llmAPIKey = config.apiKey
        project.temperature = config.temperature
        return self
    }
    
    func build() -> Project {
        return project
    }
}

// Usage example
// Note: This project's source is available at https://github.com/RichNasz/ShowroomAgentMVP.git
let project = ProjectConfigurationBuilder(name: "My Project")
    .withRepository("https://github.com/user/repo")
    .withLocalFolder("/path/to/folder")
    .withLLMConfiguration(LLMConfiguration(
        endpointURL: "https://api.openai.com/v1/chat/completions",
        modelName: "gpt-4",
        apiKey: "sk-...",
        temperature: 0.7
    ))
    .build()

// Type-safe configuration with compile-time validation
struct TypeSafeConfiguration {
    let repository: RepositoryConfiguration
    let storage: StorageConfiguration  
    let generation: GenerationConfiguration
    
    private init(repository: RepositoryConfiguration, 
                storage: StorageConfiguration,
                generation: GenerationConfiguration) {
        self.repository = repository
        self.storage = storage
        self.generation = generation
    }
    
    static func build(@ConfigurationBuilder builder: () -> TypeSafeConfiguration) -> TypeSafeConfiguration {
        return builder()
    }
}

@resultBuilder
struct ConfigurationBuilder {
    static func buildBlock(_ repository: RepositoryConfiguration,
                          _ storage: StorageConfiguration,
                          _ generation: GenerationConfiguration) -> TypeSafeConfiguration {
        TypeSafeConfiguration(repository: repository, storage: storage, generation: generation)
    }
}

// Error handling with specific, actionable errors
enum ProjectConfigurationError: Error, LocalizedError, RecoveryErrorProviding {
    case invalidRepositoryURL(String)
    case inaccessibleLocalFolder(String, reason: String)
    case invalidLLMConfiguration(field: String, value: String)
    case securityBookmarkExpired
    
    var errorDescription: String? {
        switch self {
        case .invalidRepositoryURL(let url):
            return "The repository URL '\(url)' is not valid. Please check the format and try again."
        case .inaccessibleLocalFolder(let path, let reason):
            return "Cannot access local folder at '\(path)': \(reason)"
        case .invalidLLMConfiguration(let field, let value):
            return "Invalid LLM configuration: \(field) value '\(value)' is not acceptable"
        case .securityBookmarkExpired:
            return "Folder access permissions have expired. Please reselect the folder to restore access."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidRepositoryURL:
            return "Ensure the URL starts with 'https://github.com/' and points to a valid repository."
        case .inaccessibleLocalFolder:
            return "Choose a different folder or check that you have read/write permissions to the selected location."
        case .invalidLLMConfiguration:
            return "Review the LLM configuration and ensure all required fields are properly formatted."
        case .securityBookmarkExpired:
            return "Use the 'Configure' button to reselect the local folder and restore access permissions."
        }
    }
}

// Protocol-based dependency injection
protocol DependencyContainer {
    func resolve<T>(_ type: T.Type) -> T
    func register<T>(_ type: T.Type, factory: @escaping () -> T)
}

final class SwiftDependencyContainer: DependencyContainer {
    private var factories: [String: () -> Any] = [:]
    
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }
    
    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        guard let factory = factories[key] else {
            fatalError("No registration found for type \(type)")
        }
        
        guard let instance = factory() as? T else {
            fatalError("Factory for type \(type) returned incorrect type")
        }
        
        return instance
    }
}
```

## 9. Implementation Checklist for Swift

### Swift-Specific Requirements and Features
- [ ] **SwiftUI Application Structure**
  - [ ] App entry point with WindowGroup and scene configuration
  - [ ] NavigationSplitView for main interface layout
  - [ ] Inspector integration for side panels
  - [ ] State management with @State, @Published, and @Observable
  - [ ] Environment object injection for shared state

- [ ] **SwiftData Integration**
  - [ ] Model container configuration with proper schema
  - [ ] @Model classes for persistent data
  - [ ] @Query property wrappers for data fetching
  - [ ] Model context injection and usage
  - [ ] Transient property handling for non-persistent data

- [ ] **Concurrency Implementation**
  - [ ] Async/await for all asynchronous operations
  - [ ] MainActor annotation for UI-related operations
  - [ ] Structured concurrency with TaskGroup
  - [ ] Actor usage for thread-safe state management
  - [ ] Sendable conformance for data passed between contexts

### Library Integration Tasks
- [ ] **ShowroomParser Integration**
  - [ ] Import and configure ShowroomParser dependency
  - [ ] Repository parsing function implementation
  - [ ] Content extraction and markdown generation
  - [ ] Error handling for parsing failures
  - [ ] Memory management for parsed content

- [ ] **SwiftChatCompletionsDSL Integration**
  - [ ] LLM client configuration and setup
  - [ ] Request building using DSL syntax
  - [ ] Response handling and error management
  - [ ] Authentication and connection validation
  - [ ] Timeout and retry logic implementation

- [ ] **Yams YAML Processing**
  - [ ] YAML parsing for Antora configuration files
  - [ ] Error handling for malformed YAML
  - [ ] Configuration validation and structure checking
  - [ ] Type-safe YAML data mapping
  - [ ] Custom decoder configuration

### Platform-Specific Implementation Tasks
- [ ] **macOS Integration**
  - [ ] NSOpenPanel integration for folder selection
  - [ ] Security-scoped bookmark creation and management
  - [ ] File system permission handling
  - [ ] AppKit integration where needed
  - [ ] Sandbox compatibility and configuration

- [ ] **Performance Optimization**
  - [ ] Memory management with NSCache and autoreleasepool
  - [ ] Background queue usage for heavy operations
  - [ ] Progress reporting for long-running tasks
  - [ ] Memory pressure handling and cleanup
  - [ ] Lazy loading for large content

### Testing Infrastructure Setup
- [ ] **Swift Testing Framework**
  - [ ] Test target configuration with Swift Testing
  - [ ] Unit test structure and organization
  - [ ] Mock object creation for external dependencies
  - [ ] Async testing patterns for concurrent operations
  - [ ] UI testing setup for interface validation

- [ ] **Test Data Management**
  - [ ] Mock repository creation utilities
  - [ ] Test configuration management
  - [ ] Network mocking for LLM service testing
  - [ ] File system mocking for repository operations
  - [ ] Performance benchmark establishment

---

**Related Documents:**
- [Functional Specification](ShowroomAgentMVPSpec.md) - System capabilities and user requirements  
- [Generic Code Generation Specification](CodeGenerationSpec.md) - Language-agnostic implementation algorithms