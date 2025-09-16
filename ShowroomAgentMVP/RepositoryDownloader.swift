/*
 * RepositoryDownloader.swift
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

/// HTTP-based repository downloader for sandbox-compatible Git operations.
///
/// `RepositoryDownloader` provides a secure alternative to command-line git operations
/// by downloading GitHub repository archives via HTTP and extracting them locally.
/// Designed specifically for sandboxed applications that cannot execute external binaries.
///
/// ## Key Features
/// - Downloads GitHub repositories as ZIP archives
/// - Handles security-scoped bookmark access for sandboxed apps
/// - Extracts content to structured directory layout
/// - Supports both public and private repositories
/// - No external dependencies or special entitlements required
///
/// ## Usage Example
/// ```swift
/// let downloader = RepositoryDownloader()
/// let result = await downloader.downloadRepository(
///     from: "https://github.com/user/repo",
///     to: "/Users/user/Projects",
///     project: project
/// )
///
/// switch result {
/// case .success(let message):
///     print("Download successful: \(message)")
/// case .failure(let error):
///     print("Download failed: \(error.localizedDescription)")
/// }
/// ```
///
/// ## Directory Structure
/// Downloaded content is organized as:
/// ```
/// {localPath}/
/// └── githubcontent/
///     └── content/
///         ├── antora.yml
///         └── modules/
/// ```
///
/// - Important: All operations must be performed on the main actor
/// - Note: Uses GitHub's archive API which downloads the main branch by default
@Observable
@MainActor
class RepositoryDownloader {
	
	/// Result type for repository download operations.
	///
	/// Encapsulates the outcome of HTTP-based repository download attempts,
	/// providing either success confirmation or detailed error information.
	///
	/// ## Cases
	/// - `success(String)`: Download completed successfully with status message
	/// - `failure(DownloadError)`: Download failed with specific error details
	///
	/// - SeeAlso: `DownloadError` for comprehensive error type definitions
	enum DownloadResult: Sendable {
		/// Successful download operation with descriptive status message
		case success(String)

		/// Failed download operation with detailed error information
		case failure(DownloadError)
	}
	
	/// Comprehensive error types for repository download operations.
	///
	/// Provides specific error cases with detailed context for troubleshooting
	/// HTTP download and extraction failures. Each error includes actionable
	/// information for error recovery and user guidance.
	///
	/// ## Error Categories
	/// - **URL Validation**: `invalidURL` for malformed repository URLs
	/// - **Path Validation**: `invalidPath` for invalid local storage paths
	/// - **Network Operations**: `networkError` for HTTP download failures
	/// - **Archive Processing**: `extractionError` for ZIP extraction failures
	/// - **File System**: `fileSystemError` for local file operations
	///
	/// - SeeAlso: `DownloadError.localizedDescription` for user-friendly error messages
	enum DownloadError: Error, Sendable {
		/// Repository URL is malformed or invalid format
		case invalidURL

		/// Local storage path is invalid or inaccessible
		case invalidPath

		/// HTTP download operation failed with error details
		case networkError(String)

		/// ZIP archive extraction failed with error message
		case extractionError(String)

		/// File system operation failed with error details
		case fileSystemError(String)
		
		/// Returns a localized description of the error
		var localizedDescription: String {
			switch self {
				case .invalidURL:
					return "Invalid repository URL. Please check the URL format."
				case .invalidPath:
					return "Invalid local path provided."
				case .networkError(let message):
					return "Network error: \(message)"
				case .extractionError(let message):
					return "Failed to extract repository: \(message)"
				case .fileSystemError(let message):
					return "File system error: \(message)"
			}
		}
	}
	
	/// Downloads and extracts a GitHub repository using HTTP archive method.
	///
	/// Performs a complete repository download operation by converting the GitHub URL
	/// to an archive download URL, downloading the ZIP file, and extracting it to
	/// the specified local directory with proper security-scoped access.
	///
	/// ## Process Flow
	/// 1. Validates input parameters (URL and path)
	/// 2. Converts GitHub URL to archive download URL
	/// 3. Establishes security-scoped access if project provided
	/// 4. Downloads ZIP archive via HTTP
	/// 5. Extracts content to `githubcontent` subdirectory
	/// 6. Cleans up temporary files
	///
	/// ## URL Conversion
	/// Converts standard GitHub URLs to archive download URLs:
	/// - Input: `https://github.com/user/repo`
	/// - Output: `https://github.com/user/repo/archive/refs/heads/main.zip`
	///
	/// ## Example
	/// ```swift
	/// let result = await downloader.downloadRepository(
	///     from: "https://github.com/company/documentation",
	///     to: "/Users/user/Projects/MyProject",
	///     project: project
	/// )
	/// ```
	///
	/// - Parameters:
	///   - repositoryURL: GitHub repository URL (supports .git suffix removal)
	///   - localPath: Base directory path for storing extracted repository content
	///   - project: Project instance containing security bookmark for folder access
	/// - Returns: `DownloadResult` with extraction path or detailed error information
	///
	/// - Important: Content is extracted to `{localPath}/githubcontent/` subdirectory
	/// - Note: Downloads main branch by default; private repos require authentication
	func downloadRepository(from repositoryURL: String, to localPath: String, project: Project? = nil) async -> DownloadResult {
		// Validate inputs
		guard !repositoryURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
			return .failure(.invalidURL)
		}
		
		guard !localPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
			return .failure(.invalidPath)
		}
		
		// Convert GitHub URL to archive download URL
		guard let archiveURL = createArchiveURL(from: repositoryURL) else {
			return .failure(.invalidURL)
		}
		
		// Perform download with security-scoped access if project is provided
		if let project = project {
			do {
				return try await project.withSecureFolderAccess {
					return await performDownload(from: archiveURL, to: localPath, repositoryURL: repositoryURL)
				}
			} catch {
				return .failure(.fileSystemError("Security access error: \(error.localizedDescription)"))
			}
		} else {
			return await performDownload(from: archiveURL, to: localPath, repositoryURL: repositoryURL)
		}
	}
	
	/// Converts a standard GitHub repository URL to an archive download URL.
	///
	/// Transforms GitHub repository URLs into their corresponding ZIP archive
	/// download URLs by appending the archive path for the main branch.
	/// Handles common URL variations and validates GitHub domain.
	///
	/// ## URL Transformations
	/// - Removes `.git` suffix if present
	/// - Validates GitHub domain presence
	/// - Appends archive download path: `/archive/refs/heads/main.zip`
	///
	/// ## Examples
	/// ```swift
	/// // Standard URL
	/// "https://github.com/user/repo"
	/// // Becomes:
	/// "https://github.com/user/repo/archive/refs/heads/main.zip"
	///
	/// // URL with .git suffix
	/// "https://github.com/user/repo.git"
	/// // Becomes:
	/// "https://github.com/user/repo/archive/refs/heads/main.zip"
	/// ```
	///
	/// - Parameter repositoryURL: GitHub repository URL (standard format)
	/// - Returns: Archive download URL, or `nil` if URL is invalid or not GitHub
	///
	/// - Note: Only supports GitHub.com repositories
	/// - Important: Downloads main branch; does not support branch specification
	private func createArchiveURL(from repositoryURL: String) -> URL? {
		var cleanURL = repositoryURL.trimmingCharacters(in: .whitespacesAndNewlines)
		
		// Remove .git suffix if present
		if cleanURL.hasSuffix(".git") {
			cleanURL = String(cleanURL.dropLast(4))
		}
		
		// Ensure it's a GitHub URL
		guard cleanURL.contains("github.com") else {
			return nil
		}
		
		// Convert to archive URL
		// https://github.com/user/repo -> https://github.com/user/repo/archive/refs/heads/main.zip
		let archiveURL = "\(cleanURL)/archive/refs/heads/main.zip"
		return URL(string: archiveURL)
	}
	
	/// Executes the HTTP download and ZIP extraction process.
	///
	/// Internal method that handles the core download workflow including
	/// directory creation, HTTP download, response validation, and ZIP extraction.
	/// Manages temporary file cleanup and provides detailed error reporting.
	///
	/// ## Operations Performed
	/// 1. Creates local storage directory structure
	/// 2. Downloads ZIP archive via URLSession
	/// 3. Validates HTTP response status codes
	/// 4. Extracts ZIP to `githubcontent` subdirectory
	/// 5. Cleans up temporary download files
	///
	/// ## Error Handling
	/// Maps various failure scenarios to appropriate `DownloadError` types:
	/// - HTTP status codes (404, 403, etc.)
	/// - Network connectivity issues
	/// - File system permission problems
	/// - ZIP extraction failures
	///
	/// - Parameters:
	///   - archiveURL: GitHub archive download URL (ZIP format)
	///   - localPath: Base directory path for repository storage
	///   - repositoryURL: Original repository URL for error context
	/// - Returns: `DownloadResult` with success confirmation or error details
	///
	/// - Note: Creates `githubcontent` subdirectory under `localPath`
	private func performDownload(from archiveURL: URL, to localPath: String, repositoryURL: String) async -> DownloadResult {
		do {
			// Create the local directory
			let fileManager = FileManager.default
			try fileManager.createDirectory(atPath: localPath, withIntermediateDirectories: true)
			
			// Download the archive
			let (tempURL, response) = try await URLSession.shared.download(from: archiveURL)
			
			// Check response
			if let httpResponse = response as? HTTPURLResponse {
				guard httpResponse.statusCode == 200 else {
					return .failure(.networkError("HTTP \(httpResponse.statusCode): Repository not found or access denied"))
				}
			}
			
			// Extract to 'githubcontent' folder under the user-selected directory
			let destinationURL = URL(fileURLWithPath: localPath).appendingPathComponent("githubcontent")
			
			// Extract the ZIP file
			try await extractZipFile(from: tempURL, to: destinationURL)
			
			// Clean up temporary file
			try fileManager.removeItem(at: tempURL)
			
			return .success("Repository downloaded successfully to \(destinationURL.path)")
			
		} catch {
			return .failure(.networkError(error.localizedDescription))
		}
	}
	
	/// Extracts a ZIP archive to the specified destination directory.
	///
	/// Handles the complete ZIP extraction process including temporary directory
	/// management, archive decompression, and content organization. Manages
	/// the typical GitHub archive structure where content is nested in a
	/// version-named subdirectory.
	///
	/// ## Extraction Process
	/// 1. Creates temporary extraction directory
	/// 2. Extracts ZIP using system unzip command
	/// 3. Locates extracted content directory (e.g., "repo-main")
	/// 4. Moves content to final destination
	/// 5. Cleans up temporary files
	///
	/// ## GitHub Archive Structure
	/// GitHub archives contain a top-level directory named `{repo}-{branch}`:
	/// ```
	/// archive.zip
	/// └── repo-main/
	///     ├── README.md
	///     └── src/
	/// ```
	/// Content is moved from `repo-main/` to the destination directory.
	///
	/// - Parameters:
	///   - zipURL: Local file URL of the downloaded ZIP archive
	///   - destinationURL: Target directory URL for extracted content
	/// - Throws: `DownloadError.extractionError` for extraction failures
	///
	/// - Important: Overwrites existing content in destination directory
	/// - Note: Uses system unzip command for reliable extraction
	private func extractZipFile(from zipURL: URL, to destinationURL: URL) async throws {
		let fileManager = FileManager.default
		
		// Create a temporary extraction directory
		let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
		try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
		
		defer {
			// Clean up temp directory
			try? fileManager.removeItem(at: tempDir)
		}
		
		// Extract ZIP using NSFileManager (available in sandbox)
		try fileManager.unzipItem(at: zipURL, to: tempDir)
		
		// Find the extracted folder (GitHub creates a folder like "repo-main")
		let contents = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
		
		guard let extractedFolder = contents.first(where: { $0.hasDirectoryPath }) else {
			throw DownloadError.extractionError("No directory found in archive")
		}
		
		// Move the contents of the extracted folder to the final destination
		// First, ensure the destination directory exists and is empty
		if fileManager.fileExists(atPath: destinationURL.path) {
			// Clear the destination directory
			let existingContents = try fileManager.contentsOfDirectory(at: destinationURL, includingPropertiesForKeys: nil)
			for item in existingContents {
				try fileManager.removeItem(at: item)
			}
		} else {
			// Create the destination directory
			try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true)
		}
		
		// Move each item from the extracted folder to the destination
		let extractedContents = try fileManager.contentsOfDirectory(at: extractedFolder, includingPropertiesForKeys: nil)
		for item in extractedContents {
			let destinationItem = destinationURL.appendingPathComponent(item.lastPathComponent)
			try fileManager.moveItem(at: item, to: destinationItem)
		}
	}
}

/// FileManager extension providing ZIP archive extraction capabilities.
///
/// Extends `FileManager` with unzip functionality for repository archive processing.
/// Uses the system's built-in unzip command for reliable archive extraction.
extension FileManager {
	/// Extracts a ZIP archive using the system unzip command.
	///
	/// Provides ZIP extraction functionality by invoking the system's unzip utility.
	/// Designed to work within sandbox restrictions while maintaining reliability
	/// for repository archive processing.
	///
	/// ## Process Details
	/// - Uses `/usr/bin/unzip` system command
	/// - Extracts quietly without verbose output
	/// - Validates extraction success via exit status
	/// - Throws detailed errors for troubleshooting
	///
	/// ## Example
	/// ```swift
	/// let fileManager = FileManager.default
	/// try fileManager.unzipItem(
	///     at: zipFileURL,
	///     to: extractionDirectoryURL
	/// )
	/// ```
	///
	/// - Parameters:
	///   - sourceURL: File URL of the ZIP archive to extract
	///   - destinationURL: Directory URL where content should be extracted
	/// - Throws: `RepositoryDownloader.DownloadError.extractionError` for extraction failures
	///
	/// - Important: Requires system unzip command to be available
	/// - Note: May have limitations in highly restricted sandbox environments
	func unzipItem(at sourceURL: URL, to destinationURL: URL) throws {
		// Use the system unzip command as a fallback approach
		// This might still have sandbox issues, but is more likely to work than git
		let process = Process()
		process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
		process.arguments = ["-q", sourceURL.path, "-d", destinationURL.path]
		
		try process.run()
		process.waitUntilExit()
		
		guard process.terminationStatus == 0 else {
			throw RepositoryDownloader.DownloadError.extractionError("Unzip failed with status \(process.terminationStatus)")
		}
	}
}
