/*
 * ShowroomUtilities.swift
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
// Removed Playgrounds import to fix dyld linking issues
// #if canImport(Playgrounds)
// import Playgrounds
// #endif
import Yams

/// Errors that can occur during file reading operations.
///
/// Provides specific error cases for common file system failures with detailed
/// context for troubleshooting and user-friendly error reporting.
///
/// ## Error Recovery
/// Most errors provide actionable information for recovery:
/// - `invalidProjectPath`: Configure project local folder
/// - `fileNotFound`: Verify file exists or repository structure
/// - `readPermissionDenied`: Check folder permissions or re-authorize access
/// - `invalidEncoding`: Check file format and encoding
///
/// - SeeAlso: `FileReadError.LocalizedError` for user-friendly error messages
enum FileReadError: Error {
	/// Project local folder path is not configured or invalid
	case invalidProjectPath
	
	/// Requested file does not exist at the specified path
	case fileNotFound
	
	/// Application lacks permission to read the file
	case readPermissionDenied
	
	/// File contains text that cannot be decoded as UTF-8
	case invalidEncoding
	
	/// Unexpected file system error with underlying cause
	case unknownError(Error)
}

/// Errors that can occur during YAML parsing operations.
///
/// Specialized error cases for YAML parsing failures, particularly when processing
/// Antora configuration files. Provides detailed error context for debugging
/// repository structure issues.
///
/// ## Common Scenarios
/// - `emptyString`: Missing or empty antora.yml file
/// - `invalidYAML`: Malformed YAML syntax or structure
/// - `parsingFailed`: Unexpected parsing error with underlying cause
///
/// - SeeAlso: `YAMLParseError.LocalizedError` for user-friendly error descriptions
enum YAMLParseError: Error {
	/// Attempted to parse empty or whitespace-only string
	case emptyString
	
	/// YAML content contains syntax errors or invalid structure
	case invalidYAML(String)
	
	/// Unexpected error during YAML decoding process
	case parsingFailed(Error)
}

extension YAMLParseError: LocalizedError {
	var errorDescription: String? {
		switch self {
		case .emptyString:
			return "Cannot parse empty string as YAML"
		case .invalidYAML(let details):
			return "Invalid YAML format: \(details)"
		case .parsingFailed(let error):
			return "YAML parsing failed: \(error.localizedDescription)"
		}
	}
}

extension FileReadError: LocalizedError {
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

/// Reads a file from the project's repository directory with security-scoped access.
///
/// Provides secure file reading for repository content with proper error handling
/// and UTF-8 text decoding. Combines the project's repository path with the relative
/// file path to construct the complete file location.
///
/// ## Path Resolution
/// - Uses `project.repositoryLocalPath` as the base directory
/// - Appends the relative path to form the complete file path
/// - Handles `nil` relative paths by reading from the base directory
///
/// ## Error Handling
/// Maps system file errors to specific `FileReadError` cases:
/// - File not found errors
/// - Permission denied errors  
/// - Text encoding failures
/// - Other unexpected file system errors
///
/// ## Example
/// ```swift
/// do {
///     // Read Antora configuration
///     let configContent = try readFileFromProject(project, relativePath: "content/antora.yml")
///     let config = try parseAntoraConfig(configContent)
/// } catch FileReadError.fileNotFound {
///     // Handle missing configuration file
/// } catch FileReadError.readPermissionDenied {
///     // Request folder access re-authorization
/// }
/// ```
///
/// - Parameters:
///   - project: Project containing repository configuration and local path
///   - relativePath: Path relative to the repository content directory, or `nil` for base directory
/// - Returns: File contents decoded as UTF-8 string
/// - Throws: `FileReadError` for various file access failures
/// 
/// - Important: Project must have valid `repositoryLocalPath` configuration
/// - Note: Does not use security-scoped bookmark access; assumes project folder is accessible
func readFileFromProject(_ project: Project, relativePath: String?) throws -> String {
	guard let localFolderPath = project.repositoryLocalPath, !localFolderPath.isEmpty else {
		throw FileReadError.invalidProjectPath
	}
	
	
	let fullPath = URL(fileURLWithPath: localFolderPath).appendingPathComponent(relativePath ?? "").path
	
	do {
		let fileContents = try String(contentsOfFile: fullPath, encoding: .utf8)
		return fileContents
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

// MARK: - Antora Configuration Structures

/// Represents a page link element in Antora configuration.
///
/// Used for defining navigation links and external references within
/// Antora documentation sites. Contains URL and display text for the link.
///
/// ## Usage in Configuration
/// Typically appears in AsciiDoc attributes for navigation or cross-references:
/// ```yaml
/// asciidoc:
///   attributes:
///     page-links:
///       - url: "https://example.com/docs"
///         text: "External Documentation"
/// ```
struct PageLink: Codable {
	/// Target URL for the link (can be relative or absolute)
	let url: String
	
	/// Display text shown to users for the link
	let text: String
}

/// AsciiDoc configuration attributes for Antora documentation processing.
///
/// Defines custom attributes that control AsciiDoc processing and provide
/// variables for use within documentation content. These attributes are
/// commonly used for lab environments, version control, and dynamic content.
///
/// ## Common Attributes
/// - **Lab Configuration**: Lab name, SSH credentials, and environment settings
/// - **Version Control**: Release versions and build information
/// - **UI Behavior**: Pagination and navigation customization
/// - **Dynamic Content**: Variables and links for content generation
///
/// ## Example Configuration
/// ```yaml
/// asciidoc:
///   attributes:
///     lab_name: "Advanced API Workshop"
///     release-version: "2.1.0"
///     page-pagination: true
/// ```
struct AsciidocAttributes: Codable {
	/// Laboratory or workshop name for lab-based documentation
	let labName: String?
	
	/// Software release version for documentation versioning
	let releaseVersion: String?
	
	/// Enable page pagination in generated documentation
	let pagePagination: Bool?
	
	/// Custom variable for template substitution
	let myVar: String?
	
	/// Unique identifier for the documentation set
	let guid: String?
	
	/// SSH username for lab environment connections
	let sshUser: String?
	
	/// SSH password for lab environment connections
	let sshPassword: String?
	
	/// SSH command template for lab environment access
	let sshCommand: String?
	
	/// Collection of navigation and reference links
	let pageLinks: [PageLink]?
	
	enum CodingKeys: String, CodingKey {
		case labName = "lab_name"
		case releaseVersion = "release-version"
		case pagePagination = "page-pagination"
		case myVar = "my_var"
		case guid
		case sshUser = "ssh_user"
		case sshPassword = "ssh_password"
		case sshCommand = "ssh_command"
		case pageLinks = "page-links"
	}
}

/// AsciiDoc processing configuration for Antora documentation.
///
/// Container for AsciiDoc-specific settings that control how documentation
/// content is processed and rendered. Primarily holds attribute definitions
/// that are available throughout the documentation site.
///
/// - SeeAlso: `AsciidocAttributes` for detailed attribute documentation
struct AsciidocConfig: Codable {
	/// Collection of AsciiDoc attributes for content processing
	let attributes: AsciidocAttributes
}

/// Complete Antora site configuration parsed from antora.yml.
///
/// Represents the full configuration structure for an Antora documentation component.
/// This is the primary configuration file that defines how a documentation
/// repository should be processed and integrated into an Antora site.
///
/// ## Required Fields
/// Antora requires `name` and `version` for proper site generation.
/// Other fields provide additional configuration and customization.
///
/// ## Example Configuration
/// ```yaml
/// name: api-docs
/// title: API Documentation  
/// version: 2.1.0
/// nav:
///   - modules/ROOT/nav.adoc
/// asciidoc:
///   attributes:
///     release-version: 2.1.0
/// ```
///
/// ## Integration with ShowroomParser
/// This configuration is used by ShowroomParser to understand the
/// repository structure and extract content appropriately.
///
/// - Important: Missing `name` or `version` will cause validation failures
struct AntoraConfig: Codable {
	/// Component name identifier (required for Antora processing)
	let name: String?
	
	/// Human-readable title for the documentation component
	let title: String?
	
	/// Version identifier for the documentation component (required)
	let version: String?
	
	/// Array of navigation file paths relative to component root
	let nav: [String]?
	
	/// AsciiDoc processing configuration and attributes
	let asciidoc: AsciidocConfig?
}

/// Parses Antora configuration from YAML content string.
///
/// Converts the contents of an antora.yml file into a structured `AntoraConfig` object.
/// Handles YAML parsing errors and provides detailed error context for debugging
/// repository configuration issues.
///
/// ## Validation
/// - Checks for empty or whitespace-only input
/// - Validates YAML syntax using the Yams library
/// - Maps decoding errors to specific error types
/// - Preserves underlying error information for debugging
///
/// ## Example Usage
/// ```swift
/// do {
///     let yamlContent = try readFileFromProject(project, relativePath: "content/antora.yml")
///     let config = try parseAntoraConfig(yamlContent)
///     
///     guard let name = config.name, let version = config.version else {
///         throw ValidationError.missingRequiredFields
///     }
/// } catch YAMLParseError.invalidYAML(let details) {
///     // Handle malformed YAML
/// }
/// ```
///
/// - Parameter yamlString: Raw YAML content from antora.yml file
/// - Returns: Parsed configuration structure with optional fields
/// - Throws: `YAMLParseError` for various parsing failures
/// 
/// - Important: Returns optional fields; validate required `name` and `version` after parsing
/// - Note: Uses YAMLDecoder from the Yams library for parsing
func parseAntoraConfig(_ yamlString: String) throws -> AntoraConfig {
	guard !yamlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
		throw YAMLParseError.emptyString
	}
	
	do {
		let decoder = YAMLDecoder()
		let result = try decoder.decode(AntoraConfig.self, from: yamlString)
		return result
	} catch let yamlError as YamlError {
		throw YAMLParseError.invalidYAML(yamlError.localizedDescription)
	} catch {
		throw YAMLParseError.parsingFailed(error)
	}
}

#if canImport(Playgrounds)
// MARK: - Playground Testing
/*:
 # Test readFileFromProject Function
 
 This playground tests the file reading functionality with various scenarios.
 */


// To make this playground work, the app sandbox setting has to be turned off.
// TODO: make sure app sandbox is turned on for production code
//#Playground {
//	
//	// Create a test project
//	var testProject = Project(name: "Test Project")
//	testProject.localFolderPath = "/Users/rnaszcyn/Development/TESTING/showroom/githubcontent/content/"
//	// /Users/rnaszcyn/Development/TESTING/showroom/githubcontent/content
//	let testFileName = "antora.yml"
//	
//	let fullPath = URL(fileURLWithPath: testProject.localFolderPath!).appendingPathComponent(testFileName ?? "").path
//	
//	do {
//		let content = try readFileFromProject(testProject, relativePath: testFileName)
//		let antoraConfig = try parseAntoraConfig(content)
//		let navDoc = try readFileFromProject(testProject, relativePath: antoraConfig.nav?[0] ?? "" )
//	} catch {
//		print("❌ Error: \(error)")
//	}
//	let contents = try FileManager.default.contentsOfDirectory(atPath: testProject.localFolderPath! + "modules/ROOT")
//	
//	
//}
#endif
