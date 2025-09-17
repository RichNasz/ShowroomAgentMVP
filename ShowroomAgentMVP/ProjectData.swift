/*
 * ProjectData.swift
 * ShowroomAgentMVP
 *
 * Created by Richard Naszcyniec with AI assistance from Claude Code
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation
import SwiftData
import ShowroomParser

/// Content types that can be generated from repository documentation.
///
/// Represents the different types of marketing and communication content
/// that can be automatically generated from technical documentation.
///
/// ## Usage
/// ```swift
/// let contentType = ContentType.blogPost
/// project.setGeneratedFile(for: contentType, fileName: "api-guide.md")
/// ```
///
/// ## Extensibility
/// New content types can be added by simply adding new cases to this enum.
/// The dictionary-based storage in Project automatically supports new types.
enum ContentType: String, CaseIterable, Codable, Sendable {
	/// Long-form blog posts and articles
	case blogPost = "blog"

	/// Email campaigns and newsletters
	case email = "email"

	/// LinkedIn posts and professional social media content
	case linkedIn = "linkedin"
}

/// Repository cloning operation status tracking.
///
/// Represents the current state of a repository download and extraction operation.
/// Used to provide user feedback and manage workflow progression.
///
/// ## Usage
/// ```swift
/// let project = Project(name: "My Project")
/// print(project.cloneStatus) // .notStarted
/// 
/// project.updateCloneStatus(.cloning)
/// // ... perform clone operation
/// project.updateCloneStatus(.completed)
/// ```
///
/// - Important: Status transitions should follow the logical progression: 
///   notStarted → cloning → completed/failed
enum CloneStatus: String, Codable, CaseIterable, Sendable {
	/// Initial state before any clone operation has been attempted
	case notStarted = "notStarted"
	
	/// Clone operation is currently in progress
	case cloning = "cloning"
	
	/// Clone operation completed successfully
	case completed = "completed"
	
	/// Clone operation failed with an error
	case failed = "failed"
}

/// Content generation project managing documentation sources and AI configuration.
///
/// The Project class serves as the central entity for organizing content generation activities.
/// Each project represents a connection to a GitHub repository containing technical documentation
/// and the configuration needed to transform that content into engaging blog posts and social media content.
///
/// ## Overview
/// Projects maintain all necessary configuration for the content generation workflow:
/// - Repository connection and local storage settings
/// - LLM service configuration and authentication
/// - Content generation parameters and custom prompts
/// - Operational state tracking and error handling
///
/// ## Usage Example
/// ```swift
/// // Create a new project
/// let project = Project(name: "API Documentation Blog")
/// 
/// // Configure repository and storage
/// project.updateRepositorySettings(
///     repositoryURL: "https://github.com/company/api-docs",
///     localFolderPath: "/Users/username/Projects",
///     localFolderBookmark: bookmark
/// )
/// 
/// // Set up LLM configuration
/// project.llmUrl = "https://api.openai.com/v1/chat/completions"
/// project.llmModelName = "gpt-4"
/// project.llmAPIKey = "sk-..."
/// project.temperature = 0.7
/// 
/// // Generate content
/// let content = try await generateContent(from: project)
/// ```
///
/// ## Performance Considerations
/// - The `showroomRepository` property is marked as `@Transient` for memory efficiency
/// - Security bookmarks are validated for size to prevent data store corruption
/// - Modification dates are automatically updated when configuration changes
///
/// ## Thread Safety
/// - All operations should be performed on the main actor
/// - The `withSecureFolderAccess` method is marked as `@MainActor` for safety
/// - SwiftData handles concurrent access to persistent properties
///
/// - Important: Always use `withSecureFolderAccess` for file system operations to ensure 
///   proper security-scoped resource management
/// - Warning: The `showroomRepository` property must remain `@Transient` to prevent 
///   data store corruption with large repository content
@Model
final class Project {
	/// The display name for this content generation project.
	///
	/// Used throughout the UI to identify and organize projects. Should be descriptive
	/// and help users distinguish between different documentation sources or content types.
	///
	/// - Note: Project names do not need to be unique but should be meaningful for organization
	var name: String
	
	/// GitHub repository URL containing Antora-structured technical documentation.
	///
	/// Must be a valid GitHub repository URL (public or private) containing documentation
	/// structured for Antora site generation. The repository should include:
	/// - `content/antora.yml` configuration file
	/// - `content/modules/ROOT/nav.adoc` navigation structure
	/// - `content/modules/ROOT/pages/` directory with documentation files
	///
	/// Example: `"https://github.com/company/api-documentation"`
	///
	/// - Important: Changing this value resets the clone status to allow re-cloning
	var repositoryURL: String?
	
	/// Local directory path for storing cloned repository content and generated files.
	///
	/// This directory will contain:
	/// - `githubcontent/` subdirectory with the cloned repository
	/// - Generated content files and processing artifacts
	/// - Temporary files during content generation
	///
	/// - Important: Must have read/write permissions and sufficient disk space
	/// - Note: Used in conjunction with `localFolderBookmark` for security-scoped access
	var localFolderPath: String?
	
	/// Security-scoped bookmark data for persistent folder access permissions.
	///
	/// Stores macOS security bookmark data that allows the sandboxed application
	/// to access the user-selected folder across app launches. Essential for
	/// App Store distribution and security compliance.
	///
	/// - Warning: Bookmark data is validated for size (1MB limit) to prevent data store issues
	/// - Note: Becomes stale over time and may require user re-authorization
	var localFolderBookmark: Data?
	
	/// Current state of the repository cloning operation.
	///
	/// Tracks the progress of downloading and extracting repository content.
	/// Used to provide user feedback and control workflow progression.
	///
	/// Default value is `.notStarted`. Updated automatically during clone operations.
	var cloneStatus: CloneStatus = CloneStatus.notStarted
	
	/// Descriptive error message from the most recent failed clone operation.
	///
	/// Contains human-readable error information when `cloneStatus` is `.failed`.
	/// Automatically cleared when clone status changes to `.completed`.
	///
	/// Common error scenarios include network failures, repository access issues,
	/// and insufficient disk space.
	///
	/// - Note: `nil` when no error has occurred or after successful completion
	var cloneErrorMessage: String?
	
	/// Timestamp of the most recent successful repository clone operation.
	///
	/// Updated automatically when `cloneStatus` changes to `.completed`.
	/// Used for tracking content freshness and determining when to refresh
	/// repository content.
	///
	/// - Note: `nil` if no successful clone has occurred
	var lastClonedDate: Date?
	
	/// Timestamp when this project was initially created.
	///
	/// Set automatically during project initialization and never modified thereafter.
	/// Used for project organization and lifecycle tracking.
	var createdDate: Date
	
	/// Timestamp of the most recent modification to project configuration.
	///
	/// Updated automatically whenever project settings change, including:
	/// - Repository configuration updates
	/// - LLM settings modifications  
	/// - Clone status changes
	///
	/// Used for change tracking and synchronization purposes.
	var modifiedDate: Date
	
	/// Custom prompt text for guiding LLM content generation.
	///
	/// Provides specific instructions to the language model about tone, style,
	/// structure, and content requirements for generated blog posts and social media content.
	///
	/// Example:
	/// ```
	/// "Generate an engaging technical blog post for enterprise developers.
	/// Use a professional yet approachable tone with practical examples."
	/// ```
	///
	/// - Note: Falls back to default system prompt when `nil`
	var blogPrompt: String?
	
	/// LLM service endpoint URL for content generation API calls.
	///
	/// Must be an OpenAI-compatible chat completions endpoint. Supports various providers:
	/// - OpenAI: `"https://api.openai.com/v1/chat/completions"`  
	/// - Local Ollama: `"http://localhost:11434/v1/chat/completions"`
	/// - Custom endpoints: Any OpenAI-compatible API
	///
	/// - Important: Must be a valid HTTPS URL for production use
	var llmUrl: String?
	
	/// Model identifier for the LLM service.
	///
	/// Specifies which language model to use for content generation.
	/// Must match a model available from the configured LLM provider.
	///
	/// Common examples:
	/// - OpenAI: `"gpt-4"`, `"gpt-3.5-turbo"`
	/// - Ollama: `"llama2"`, `"codellama"`
	/// - Other providers: Provider-specific model names
	var llmModelName: String?
	
	/// Authentication API key for the LLM service.
	///
	/// Required for most commercial LLM providers. Should be kept secure
	/// and rotated regularly according to provider recommendations.
	///
	/// - Important: Stored securely but consider using system keychain for production
	/// - Note: May be `nil` for local models that don't require authentication
	var llmAPIKey: String?
	
	/// Creativity and randomness control for LLM content generation.
	///
	/// Controls the randomness of the model's responses:
	/// - **Lower values (0.0-0.3)**: More focused, consistent, and deterministic output
	/// - **Medium values (0.4-0.7)**: Balanced creativity and consistency (recommended)
	/// - **Higher values (0.8-2.0)**: More creative, varied, but potentially inconsistent output
	///
	/// Default value of `0.7` provides good balance for technical content generation.
	///
	/// - Important: Valid range is 0.0 to 2.0; values outside this range may cause API errors
	var temperature: Double = 0.7
	
	/// Parsed repository content structure for validation and generation (memory-only).
	///
	/// Contains the parsed ShowroomParser representation of the cloned repository.
	/// Used during content validation and generation workflows but not persisted
	/// to avoid data store corruption with large content structures.
	///
	/// ## Usage
	/// ```swift
	/// // Parse repository content
	/// project.showroomRepository = try ShowroomParser.parseRepository(at: path)
	/// 
	/// // Use for content generation
	/// let markdown = project.showroomRepository?.toMarkdown()
	/// 
	/// // Clear when no longer needed
	/// project.clearShowroomRepository()
	/// ```
	///
	/// - Warning: **MUST** remain `@Transient` to prevent SwiftData corruption
	/// - Note: Regenerated as needed; cleared automatically to manage memory usage
	@Transient var showroomRepository: ShowroomRepository?

	/// Dictionary storing file names for generated content by content type.
	///
	/// Maps content types to their corresponding generated file names, providing
	/// flexible storage for various types of marketing and communication content
	/// generated from the repository documentation.
	///
	/// ## Usage
	/// ```swift
	/// // Set generated file names
	/// project.setGeneratedFile(for: .blogPost, fileName: "api-guide-blog.md")
	/// project.setGeneratedFile(for: .email, fileName: "release-email.html")
	///
	/// // Retrieve file names
	/// if let blogFile = project.getGeneratedFile(for: .blogPost) {
	///     // Process the blog file
	/// }
	///
	/// // Clear specific content
	/// project.clearGeneratedFile(for: .linkedIn)
	/// ```
	///
	/// ## Design Benefits
	/// - **Extensible**: New content types only require adding enum cases
	/// - **Efficient**: O(1) dictionary lookup performance
	/// - **Clean Storage**: Only stores actual file names (no nil values)
	/// - **Type Safe**: ContentType enum prevents invalid keys
	///
	/// The dictionary uses ContentType.rawValue as keys for SwiftData compatibility.
	/// Helper methods provide type-safe access while maintaining dictionary flexibility.
	///
	/// - Note: Updated automatically when modification date changes
	var generatedContentFiles: [String: String] = [:]

	/// Creates a new content generation project with the specified name.
	///
	/// Initializes a project with default configuration values and current timestamps.
	/// All optional configuration (repository, LLM settings) can be set after creation.
	///
	/// ## Example
	/// ```swift
	/// let project = Project(name: "API Documentation Blog")
	/// // Configure repository and LLM settings...
	/// ```
	///
	/// - Parameter name: Descriptive name for the project, used in UI and organization
	/// - Postcondition: Project is created with `.notStarted` clone status and current timestamps
	init(name: String) {
		self.name = name
		self.repositoryURL = nil
		self.localFolderPath = nil
		self.localFolderBookmark = nil
		// cloneStatus uses default value of .notStarted
		self.cloneErrorMessage = nil
		self.lastClonedDate = nil
		self.createdDate = Date()
		self.modifiedDate = Date()
		self.blogPrompt = nil
		self.llmUrl = nil
		self.llmModelName = nil
		self.llmAPIKey = nil
		// showroomRepository is @Transient and should always be nil initially
		self.showroomRepository = nil
	}
	
	/// Updates repository and local storage configuration for the project.
	///
	/// Configures the project's connection to a GitHub repository and local storage location.
	/// This method handles validation, state reset, and automatic cleanup of related properties.
	///
	/// ## Behavior
	/// - Validates security bookmark size to prevent data store corruption
	/// - Resets clone status when repository URL changes
	/// - Clears transient repository data
	/// - Updates modification timestamp
	///
	/// ## Example
	/// ```swift
	/// project.updateRepositorySettings(
	///     repositoryURL: "https://github.com/company/docs",
	///     localFolderPath: "/Users/user/Projects/MyProject",
	///     localFolderBookmark: securityBookmark
	/// )
	/// ```
	///
	/// - Parameters:
	///   - repositoryURL: GitHub repository URL containing Antora documentation, or `nil` to clear
	///   - localFolderPath: Local directory path for file storage, or `nil` to clear
	///   - localFolderBookmark: macOS security bookmark data for persistent folder access
	/// 
	/// - Important: Security bookmarks larger than 1MB are logged as warnings due to potential data store issues
	/// - Postcondition: Clone status reset to `.notStarted` if repository URL changed
	func updateRepositorySettings(repositoryURL: String?, localFolderPath: String?, localFolderBookmark: Data? = nil) {
		// Validate bookmark data size to prevent data store corruption
		if let bookmark = localFolderBookmark, bookmark.count > 1024 * 1024 { // 1MB limit
			print("WARNING: Bookmark data is too large (\(bookmark.count) bytes). This may cause data store issues.")
		}

		self.repositoryURL = repositoryURL
		self.localFolderPath = localFolderPath
		self.localFolderBookmark = localFolderBookmark
		self.modifiedDate = Date()

		// Reset clone status if repository URL changed
		if self.repositoryURL != repositoryURL {
			self.cloneStatus = .notStarted
			self.cloneErrorMessage = nil
			self.lastClonedDate = nil
		}

		// Always ensure showroomRepository is nil (it's @Transient)
		self.showroomRepository = nil
	}
	
	/// Updates the repository cloning status and manages related state.
	///
	/// Tracks the progress of repository download operations and manages associated
	/// timestamps and error information. Automatically handles state cleanup for
	/// successful completions.
	///
	/// ## State Management
	/// - Updates modification timestamp for all status changes
	/// - Sets completion timestamp for successful clones  
	/// - Clears error messages on successful completion
	/// - Preserves error information for debugging failed operations
	///
	/// ## Example
	/// ```swift
	/// // Starting clone operation
	/// project.updateCloneStatus(.cloning)
	/// 
	/// // On success
	/// project.updateCloneStatus(.completed)
	/// 
	/// // On failure
	/// project.updateCloneStatus(.failed, errorMessage: "Network connection failed")
	/// ```
	///
	/// - Parameters:
	///   - status: New clone operation status
	///   - errorMessage: Descriptive error message for failed operations (ignored for non-failure states)
	/// 
	/// - Postcondition: `lastClonedDate` updated and `cloneErrorMessage` cleared on completion
	func updateCloneStatus(_ status: CloneStatus, errorMessage: String? = nil) {
		self.cloneStatus = status
		self.cloneErrorMessage = errorMessage
		self.modifiedDate = Date()
		
		if status == .completed {
			self.lastClonedDate = Date()
			self.cloneErrorMessage = nil
		}
	}
	
	/// Determines whether the project configuration is sufficient to begin repository cloning.
	///
	/// Validates that all required configuration is present and that no clone operation
	/// is currently in progress. Used to enable/disable clone UI controls and workflow progression.
	///
	/// ## Validation Checks
	/// - Repository URL is configured and non-empty
	/// - Local folder path is configured and non-empty  
	/// - No clone operation currently in progress
	/// - Whitespace trimming applied to prevent false negatives
	///
	/// ## Example
	/// ```swift
	/// if project.canClone {
	///     // Enable clone button
	///     await startCloneOperation()
	/// } else {
	///     // Show configuration prompt
	///     showConfigurationSheet()
	/// }
	/// ```
	///
	/// - Returns: `true` if clone operation can be initiated, `false` otherwise
	/// - Note: Does not validate URL format or folder permissions; only checks presence of values
	var canClone: Bool {
		guard let repositoryURL = repositoryURL?.trimmingCharacters(in: .whitespacesAndNewlines),
				let localFolderPath = localFolderPath?.trimmingCharacters(in: .whitespacesAndNewlines) else {
			return false
		}
		
		return !repositoryURL.isEmpty &&
		!localFolderPath.isEmpty &&
		cloneStatus != .cloning
	}
	
	/// Computed path to the cloned repository content directory.
	///
	/// Combines the user-selected local folder path with the standard `githubcontent`
	/// subdirectory where repository archives are extracted. Used throughout the
	/// application for accessing cloned repository files.
	///
	/// ## Path Structure
	/// ```
	/// {localFolderPath}/githubcontent/
	/// └── content/
	///     ├── antora.yml
	///     └── modules/ROOT/
	///         ├── nav.adoc
	///         └── pages/
	/// ```
	///
	/// - Returns: Complete path to repository content, or `nil` if local folder not configured
	/// - Note: Path existence is not validated; use for constructing file operations
	var repositoryLocalPath: String? {
		guard let localFolderPath = localFolderPath else {
			return nil
		}
		return "\(localFolderPath)/githubcontent"
	}
	
	/// Computed path to the Antora documentation pages directory.
	///
	/// Provides the standard Antora pages path where documentation files (.adoc, .md)
	/// are located within the cloned repository. This is the primary content directory
	/// used by ShowroomParser for content extraction and processing.
	///
	/// ## Antora Structure
	/// Points to: `{repositoryLocalPath}/content/modules/ROOT/pages`
	///
	/// This directory typically contains:
	/// - `.adoc` files (AsciiDoc documentation)
	/// - `.md` files (Markdown documentation)  
	/// - Subdirectories with organized content
	/// - Images and other assets
	///
	/// - Returns: Complete path to Antora pages directory, or `nil` if repository not configured
	/// - Note: Used by ShowroomParser for content discovery and parsing operations
	var showroomLocalPath: String? {
		guard let localFolderPath = repositoryLocalPath else {
			return nil
		}
		return "\(localFolderPath)/content/modules/ROOT/pages"
	}

	/// Releases parsed repository content to free memory.
	///
	/// Clears the transient `showroomRepository` property to reclaim memory used by
	/// parsed content structures. Should be called when repository content is no longer
	/// needed for immediate operations.
	///
	/// ## When to Call
	/// - After completing content generation workflows
	/// - When switching between projects
	/// - During memory pressure situations
	/// - Before long-term project storage
	///
	/// ## Example
	/// ```swift
	/// // After content generation
	/// let content = try await generateBlogContent(from: project)
	/// project.clearShowroomRepository() // Free memory
	/// ```
	///
	/// - Note: Repository content can be re-parsed from disk when needed again
	/// - Important: Does not affect persisted project configuration or files
	func clearShowroomRepository() {
		showroomRepository = nil
	}
	
	/// Executes file operations with security-scoped folder access.
	///
	/// Provides secure access to the user-selected local folder using macOS security-scoped 
	/// bookmarks. Essential for file system operations in sandboxed applications.
	/// Automatically manages resource access lifecycle and cleanup.
	///
	/// ## Security Model
	/// - Resolves security bookmark to obtain folder access
	/// - Starts security-scoped resource access
	/// - Executes provided operation with folder access
	/// - Automatically stops resource access on completion or error
	///
	/// ## Error Handling
	/// Throws descriptive errors for common failure scenarios:
	/// - Missing bookmark (folder not configured)
	/// - Stale bookmark (permissions expired, requires re-authorization)
	/// - Access denied (system security restriction)
	///
	/// ## Example
	/// ```swift
	/// try await project.withSecureFolderAccess {
	///     // File operations with guaranteed folder access
	///     let content = try String(contentsOfFile: filePath)
	///     return try processContent(content)
	/// }
	/// ```
	///
	/// - Parameter block: Async operation to execute with folder access
	/// - Returns: Result of the block execution
	/// - Throws: Security or access errors with descriptive messages
	/// 
	/// - Important: All file system operations for this project should use this method
	/// - Note: Block executes on main actor for UI safety
	@MainActor func withSecureFolderAccess<T>(_ block: @MainActor @Sendable () async throws -> T) async throws -> T {
		guard let bookmark = localFolderBookmark else {
			throw NSError(domain: "ProjectError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No folder bookmark available. Please reconfigure the local folder."])
		}
		
		var isStale = false
		let url = try URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
		
		if isStale {
			throw NSError(domain: "ProjectError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Folder access permissions have expired. Please reconfigure the local folder."])
		}
		
		let didStartAccessing = url.startAccessingSecurityScopedResource()
		defer {
			if didStartAccessing {
				url.stopAccessingSecurityScopedResource()
			}
		}
		
		guard didStartAccessing else {
			throw NSError(domain: "ProjectError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to access the selected folder. Please reconfigure the local folder."])
		}
		
		return try await block()
	}

	// MARK: - Generated Content File Management

	/// Sets the file name for a specific content type.
	///
	/// Stores the generated file name in the dictionary using the content type as key.
	/// Automatically updates the project's modification date to reflect the change.
	///
	/// ## Example
	/// ```swift
	/// project.setGeneratedFile(for: .blogPost, fileName: "api-guide-blog.md")
	/// project.setGeneratedFile(for: .email, fileName: "release-announcement.html")
	/// ```
	///
	/// - Parameters:
	///   - contentType: The type of content being generated
	///   - fileName: The name of the generated file (including extension)
	///
	/// - Postcondition: `modifiedDate` is updated to current time
	func setGeneratedFile(for contentType: ContentType, fileName: String) {
		generatedContentFiles[contentType.rawValue] = fileName
		modifiedDate = Date()
	}

	/// Retrieves the file name for a specific content type.
	///
	/// Looks up the stored file name for the given content type in the dictionary.
	/// Returns nil if no file has been generated for this content type.
	///
	/// ## Example
	/// ```swift
	/// if let blogFile = project.getGeneratedFile(for: .blogPost) {
	///     // Process the blog file
	///     print("Blog file: \(blogFile)")
	/// } else {
	///     print("No blog file generated yet")
	/// }
	/// ```
	///
	/// - Parameter contentType: The type of content to look up
	/// - Returns: The file name if one exists, nil otherwise
	func getGeneratedFile(for contentType: ContentType) -> String? {
		return generatedContentFiles[contentType.rawValue]
	}

	/// Removes the file name for a specific content type.
	///
	/// Clears the stored file name for the given content type from the dictionary.
	/// Automatically updates the project's modification date to reflect the change.
	///
	/// ## Example
	/// ```swift
	/// // Clear the LinkedIn content file
	/// project.clearGeneratedFile(for: .linkedIn)
	/// ```
	///
	/// - Parameter contentType: The type of content to clear
	/// - Postcondition: `modifiedDate` is updated to current time
	func clearGeneratedFile(for contentType: ContentType) {
		generatedContentFiles.removeValue(forKey: contentType.rawValue)
		modifiedDate = Date()
	}

	/// Removes all generated file names from the project.
	///
	/// Clears the entire dictionary of generated content files.
	/// Useful for resetting the project or when regenerating all content.
	/// Automatically updates the project's modification date to reflect the change.
	///
	/// ## Example
	/// ```swift
	/// // Clear all generated content before regenerating
	/// project.clearAllGeneratedFiles()
	/// ```
	///
	/// - Postcondition: `generatedContentFiles` is empty and `modifiedDate` is updated
	func clearAllGeneratedFiles() {
		generatedContentFiles.removeAll()
		modifiedDate = Date()
	}

	/// Returns all content types that have generated files.
	///
	/// Provides a convenient way to check which content types have been generated
	/// for this project. Useful for UI display and validation purposes.
	///
	/// ## Example
	/// ```swift
	/// let generatedTypes = project.getGeneratedContentTypes()
	/// for contentType in generatedTypes {
	///     print("Generated: \(contentType.rawValue)")
	/// }
	/// ```
	///
	/// - Returns: Array of ContentType values that have associated file names
	func getGeneratedContentTypes() -> [ContentType] {
		return generatedContentFiles.keys.compactMap { key in
			ContentType(rawValue: key)
		}
	}

	/// Checks if any content has been generated for this project.
	///
	/// Convenience property to quickly determine if the project has any generated files.
	/// Useful for enabling/disabling UI elements or workflow decisions.
	///
	/// ## Example
	/// ```swift
	/// if project.hasGeneratedContent {
	///     // Show export options
	/// } else {
	///     // Show generation prompts
	/// }
	/// ```
	///
	/// - Returns: `true` if any generated files exist, `false` otherwise
	var hasGeneratedContent: Bool {
		return !generatedContentFiles.isEmpty
	}
}
