/*
 * GitService.swift
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
import Observation

/// Service for downloading and managing repository content using HTTP downloads.
///
/// `GitService` provides a safe, sandbox-compatible alternative to command-line git operations.
/// It uses HTTP archive downloads through GitHub's API to clone repository content without
/// requiring external git binary execution or special entitlements.
///
/// ## Usage
/// ```swift
/// let gitService = GitService()
/// let result = await gitService.cloneRepository(
///     from: "https://github.com/user/repo",
///     to: "/Users/user/Projects",
///     project: project
/// )
///
/// switch result {
/// case .success(let message):
///     print("Clone successful: \(message)")
/// case .failure(let error):
///     print("Clone failed: \(error.localizedDescription)")
/// }
/// ```
///
/// ## Thread Safety
/// All operations are performed on the main actor for UI safety and state consistency.
///
/// - Important: Uses security-scoped bookmark access for sandboxed environments
/// - Note: Designed to work without external dependencies or special entitlements
@Observable
@MainActor
class GitService {

    /// Repository downloader service for handling HTTP-based repository operations.
    ///
    /// Provides the underlying functionality for downloading and extracting GitHub
    /// repository archives without requiring command-line git tools.
    private let repositoryDownloader = RepositoryDownloader()
	
	/// Result type for repository download operations.
	///
	/// Encapsulates the outcome of repository cloning or validation operations,
	/// providing either a success message or detailed error information.
	///
	/// ## Cases
	/// - `success(String)`: Operation completed successfully with status message
	/// - `failure(GitError)`: Operation failed with detailed error information
	enum GitResult {
		/// Successful operation with descriptive status message
		case success(String)

		/// Failed operation with specific error details
		case failure(GitError)
	}
	
	/// Comprehensive error types for repository download operations.
	///
	/// Provides specific error cases with detailed context for troubleshooting
	/// repository cloning failures. Each error includes actionable information
	/// for error recovery and user guidance.
	///
	/// ## Error Cases
	/// - `invalidURL`: Repository URL format is invalid or malformed
	/// - `invalidPath`: Local storage path is invalid or inaccessible
	/// - `downloadFailed(String)`: Network or HTTP download failure with details
	/// - `commandFailed(String)`: System operation failure with error message
	///
	/// - SeeAlso: `GitError.localizedDescription` for user-friendly error messages
	enum GitError: Error, Sendable {
		/// Repository URL is malformed or invalid format
		case invalidURL

		/// Local storage path is invalid or inaccessible
		case invalidPath

		/// Network download operation failed with error details
		case downloadFailed(String)

		/// System command or operation failed with error message
		case commandFailed(String)

		/// User-friendly description of the error for display in UI.
		var localizedDescription: String {
			switch self {
				case .invalidURL:
					return "Invalid repository URL provided."
				case .invalidPath:
					return "Invalid local path provided."
				case .downloadFailed(let message):
					return "Repository download failed: \(message)"
				case .commandFailed(let message):
					return "Operation failed: \(message)"
			}
		}
	}
	
	/// Downloads a repository using HTTP archive download method.
	///
	/// Provides a sandbox-compatible alternative to git clone by downloading
	/// repository archives through GitHub's HTTP API. Handles security-scoped
	/// access for sandboxed applications and validates all inputs.
	///
	/// ## Process Flow
	/// 1. Validates repository URL and local path inputs
	/// 2. Uses HTTP download method for maximum compatibility
	/// 3. Handles security-scoped bookmark access if project provided
	/// 4. Extracts repository content to `githubcontent` subdirectory
	///
	/// ## Example
	/// ```swift
	/// let result = await gitService.cloneRepository(
	///     from: "https://github.com/company/docs",
	///     to: "/Users/user/Projects/MyProject",
	///     project: project
	/// )
	/// ```
	///
	/// - Parameters:
	///   - repositoryURL: GitHub repository URL (public or private with authentication)
	///   - localPath: Base directory path for storing downloaded repository content
	///   - project: Project instance containing security bookmark for folder access
	/// - Returns: `GitResult` with success message or detailed error information
	///
	/// - Important: Repository content is extracted to `{localPath}/githubcontent/`
	/// - Note: Uses security-scoped bookmarks when project is provided for sandbox compatibility
	func cloneRepository(from repositoryURL: String, to localPath: String, project: Project? = nil) async -> GitResult {
		// Validate inputs
		guard !repositoryURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
			return .failure(.invalidURL)
		}
		
		guard !localPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
			return .failure(.invalidPath)
		}
		
		// Always use HTTP download method for maximum compatibility
		print("Using HTTP download method for repository")
		return await gitHTTPDownload(repositoryURL: repositoryURL, localPath: localPath, project: project)
	}
	
	/// Performs HTTP-based repository download using the repository downloader.
	///
	/// Internal method that delegates the actual download operation to `RepositoryDownloader`
	/// while converting its result format to `GitResult` for consistent API.
	///
	/// - Parameters:
	///   - repositoryURL: GitHub repository URL to download from
	///   - localPath: Local directory path for storing repository content
	///   - project: Project instance for security-scoped folder access
	/// - Returns: `GitResult` with converted success/failure status
	///
	/// - Note: Provides abstraction layer between GitService and RepositoryDownloader
	private func gitHTTPDownload(repositoryURL: String, localPath: String, project: Project?) async -> GitResult {
		let result = await repositoryDownloader.downloadRepository(from: repositoryURL, to: localPath, project: project)
		
		switch result {
		case .success(let message):
			return .success(message)
		case .failure(let error):
			return .failure(.commandFailed(error.localizedDescription))
		}
	}
	
	/// Validates that a directory contains downloaded repository content.
	///
	/// Performs basic validation to verify that a directory exists and contains
	/// files that indicate a successful repository download operation.
	/// Used for verifying clone operations and repository integrity.
	///
	/// ## Validation Checks
	/// - Directory exists at specified path
	/// - Directory is readable and accessible
	/// - Directory contains at least one file or subdirectory
	///
	/// ## Example
	/// ```swift
	/// let result = await gitService.isRepository(at: "/Users/user/Projects/repo")
	/// switch result {
	/// case .success(let message):
	///     print("Repository found: \(message)")
	/// case .failure(let error):
	///     print("No repository: \(error.localizedDescription)")
	/// }
	/// ```
	///
	/// - Parameter path: File system path to directory for validation
	/// - Returns: `GitResult` with item count or error information
	///
	/// - Note: Does not validate repository structure, only presence of content
	func isRepository(at path: String) async -> GitResult {
		let fileManager = FileManager.default
		
		// Check if the directory exists and contains files
		guard fileManager.fileExists(atPath: path) else {
			return .failure(.commandFailed("Directory does not exist"))
		}
		
		do {
			let contents = try fileManager.contentsOfDirectory(atPath: path)
			if contents.isEmpty {
				return .failure(.commandFailed("Directory is empty"))
			}
			return .success("Repository directory found with \(contents.count) items")
		} catch {
			return .failure(.commandFailed("Failed to read directory: \(error.localizedDescription)"))
		}
	}
	
}
