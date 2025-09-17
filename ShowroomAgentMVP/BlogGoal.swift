/*
 * BlogGoal.swift
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
import SwiftUI
import SwiftData
import SwiftChatCompletionsDSL
import MarkdownUI

// Removed Playgrounds import to fix dyld linking issues
// #if canImport(Playgrounds)
// import Playgrounds
// #endif
import ShowroomParser

/// Activity types for the blog creation workflow process.
///
/// Defines the sequential steps in the guided blog generation workflow,
/// from initial introduction through content validation, prompt configuration,
/// content generation, and final review. Each activity type provides
/// its own view and functionality within the process flow.
///
/// ## Workflow Sequence
/// 1. **Introduction**: Welcome and process overview
/// 2. **Validate Content**: Verify repository structure and showroom content
/// 3. **Provide Prompt**: Configure LLM prompt for content generation
/// 4. **Generate Content**: Execute LLM-based content generation
/// 5. **Review/Edit**: Review and refine generated content
///
/// ## UI Integration
/// Each activity type includes an associated SF Symbol for consistent
/// visual representation throughout the user interface.
///
/// - SeeAlso: `BlogActivityModel` for activity instance management
enum BlogActivityType: String, CaseIterable {
	case introduction = "Introduction"
	case validateContent = "Validate Showroom Content"
	case providePrompt = "Provide LLM Prompt"
	case generateContent = "Generate Content"
	case reviewEdit = "Review Generated Content"
	
	/// SF Symbol icon name for visual representation in the UI.
	///
	/// Provides consistent iconography throughout the blog creation workflow.
	/// Each activity type has a distinctive symbol that represents its purpose
	/// and helps users understand the current step in the process.
	///
	/// - Returns: SF Symbol name appropriate for the activity type
	var imageName: String {
		switch self {
			case .introduction:
				return "hand.wave"
			case .validateContent:
				return "checkmark.shield"
			case .providePrompt:
				return "text.cursor"
			case .generateContent:
				return "sparkles"
			case .reviewEdit:
				return "pencil.and.outline"
		}
	}
}

/// Model representing an individual activity within the blog creation workflow.
///
/// `BlogActivityModel` encapsulates the state and behavior of a single step
/// in the blog generation process. Each activity maintains its completion status
/// and provides view creation functionality for the step-by-step interface.
///
/// ## Lifecycle Management
/// - Created with incomplete status (`isCompleted = false`)
/// - Marked as completed when user advances to next step
/// - Provides dynamic view creation based on activity type
///
/// ## View Factory Pattern
/// Uses the `createView` method to instantiate appropriate SwiftUI views
/// for each activity type, enabling a flexible and extensible workflow system.
///
/// - SeeAlso: `BlogActivityType` for available activity types
struct BlogActivityModel {
	/// Unique identifier for tracking activity instances
	let id = UUID()
	
	/// The type of blog activity this model represents
	let type: BlogActivityType
	
	/// Completion status of this activity in the workflow
	var isCompleted: Bool = false
	
	/// Human-readable title for display in the UI.
	///
	/// - Returns: The raw value of the activity type as display text
	var title: String {
		type.rawValue
	}
	
	/// SF Symbol icon name for UI representation.
	///
	/// - Returns: The SF Symbol name associated with this activity type
	var imageName: String {
		type.imageName
	}
	
	/// Creates the appropriate SwiftUI view for this activity type.
	///
	/// Factory method that instantiates the correct view based on the activity type.
	/// Each view focuses solely on content and validation, with navigation handled
	/// centrally by the BlogGoalInspector.
	///
	/// ## View Types
	/// - **Introduction**: `WelcomeActivityView` with process overview
	/// - **Validate Content**: `ValidateContentActivityView` with repository validation
	/// - **Provide Prompt**: `GatherPromptView` for LLM prompt configuration
	/// - **Generate Content**: `GenerateContentView` for content generation
	/// - **Review/Edit**: `ReviewContentView` for content review
	///
	/// - Parameters:
	///   - project: The project context containing repository and configuration data
	/// - Returns: Type-erased SwiftUI view appropriate for this activity
	///
	/// - Important: Must be called on the main actor for UI safety
	@MainActor func createView(project: Project, validationState: Binding<ValidationState>? = nil) -> AnyView {
		switch type {
			case .introduction:
				return AnyView(WelcomeActivityView())
			case .validateContent:
				if let validationBinding = validationState {
					return AnyView(ValidateContentActivityView(project: project, externalValidationState: validationBinding))
				} else {
					// Fallback for when no binding is provided
					return AnyView(ValidateContentActivityView(project: project, externalValidationState: .constant(.notStarted)))
				}
			case .providePrompt:
				return AnyView(GatherPromptView(project: project))
			case .generateContent:
				return AnyView(GenerateContentView(project: project))
			case .reviewEdit:
				return AnyView(ReviewContentView(project: project))
			default:
				return AnyView(PlaceholderActivityView(title: title))
		}
	}

	/// Gets the validation interface for the current activity
	@MainActor func getValidation(project: Project, validationState: ValidationState = .notStarted) -> ActivityValidation {
		switch type {
			case .introduction:
				return WelcomeActivityView()
			case .validateContent:
				// For validation activity, use the actual validation state
				return ValidateContentActivityValidation(validationState: validationState)
			case .providePrompt:
				return GatherPromptView(project: project)
			case .generateContent:
				return GenerateContentView(project: project)
			case .reviewEdit:
				return ReviewContentView(project: project)
			default:
				return PlaceholderActivityView(title: title)
		}
	}
}

/// Primary coordinator view for the blog creation workflow process.
///
/// `BlogGoalInspector` orchestrates the complete blog generation workflow,
/// managing the sequence of activities from initial setup through content
/// generation and review. Provides a step-by-step guided experience with
/// progress tracking and navigation controls.
///
/// ## Workflow Management
/// - Maintains current activity index and completion state
/// - Provides forward and backward navigation between steps
/// - Displays progress indicators and step information
/// - Handles workflow completion and cleanup
///
/// ## User Interface Structure
/// ```
/// ┌─────────────────────────────────┐
/// │ Header with Progress Indicator  │
/// ├─────────────────────────────────┤
/// │                                 │
/// │     Current Activity View       │
/// │                                 │
/// ├─────────────────────────────────┤
/// │ Footer with Navigation Controls │
/// └─────────────────────────────────┘
/// ```
///
/// ## Example Usage
/// ```swift
/// BlogGoalInspector(
///     project: selectedProject,
///     onCleanupAndDismiss: {
///         // Handle workflow completion
///         inspectorState.hide()
///     }
/// )
/// ```
///
/// - Important: Designed for use within inspector panels or modal presentations
/// - Note: All activities are initialized in sequence but activated individually
struct BlogGoalInspector: View {
	@State private var currentActivityIndex: Int = 0
	@State private var activities: [BlogActivityModel]
	@State private var validationState: ValidationState = .notStarted
	let project: Project
	let onCleanupAndDismiss: () -> Void
	
	init(project: Project, onCleanupAndDismiss: @escaping () -> Void) {
		self.project = project
		self.onCleanupAndDismiss = onCleanupAndDismiss
		
		// Initialize the sequence of activities
		self._activities = State(initialValue: BlogActivityType.allCases.map { type in
			BlogActivityModel(type: type)
		})
	}
	
	var body: some View {
		VStack(spacing: 0) {
			// Header with progress indicator
			headerView

			// Current activity view
			if currentActivityIndex < activities.count {
				ScrollView {
					activities[currentActivityIndex].createView(project: project, validationState: $validationState)
						.padding(.horizontal)
				}
			}

			// Enhanced footer with context-aware navigation
			enhancedFooterView
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
	
	/// Header view displaying workflow progress and current step information.
	///
	/// Provides visual feedback about the user's progress through the blog
	/// creation workflow with a progress indicator and step counter.
	/// Maintains consistent styling and layout throughout the process.
	///
	/// ## Visual Components
	/// - Workflow title with emphasized typography
	/// - Circular progress indicators for each step
	/// - Current step highlighting with color and stroke
	/// - Step counter with activity title
	///
	/// - Returns: SwiftUI view with header content and progress visualization
	private var headerView: some View {
		VStack(spacing: 12) {
			Text("Blog Creation Goal ")
				.font(.title2)
				.fontWeight(.semibold)
			
			// Progress indicator
			HStack(spacing: 8) {
				ForEach(activities.indices, id: \.self) { index in
					Circle()
						.fill(index <= currentActivityIndex ? Color.cyan : Color.gray.opacity(0.3))
						.frame(width: 10, height: 10)
						.overlay(
							Circle()
								.stroke(index == currentActivityIndex ? Color.blue : Color.clear, lineWidth: 2)
						)
				}
			}
			
			Text("Step \(currentActivityIndex + 1) of \(activities.count): \(activities[currentActivityIndex].title)")
				.font(.caption)
				.foregroundStyle(.secondary)
		}
		.padding()
		.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
		.padding(.horizontal)
		.padding(.top)
	}
	
	/// Enhanced footer view with context-aware navigation controls.
	///
	/// Provides centralized navigation for the workflow using the activity validation
	/// interface to determine button states and text. Follows Apple HIG for consistent
	/// navigation patterns.
	///
	/// ## Navigation Controls
	/// - Cancel button: Always visible for workflow termination
	/// - Previous button: Visible when not on first step
	/// - Context-aware Continue/Next button: Text and state based on current activity
	///
	/// - Returns: SwiftUI view with enhanced navigation controls
	private var enhancedFooterView: some View {
		HStack(spacing: 16) {
			Button("Cancel Process") {
				onCleanupAndDismiss()
			}
			.buttonStyle(.bordered)

			Spacer()

			if currentActivityIndex > 0 {
				Button("Previous") {
					moveToPreviousActivity()
				}
				.buttonStyle(.bordered)
			}

			// Context-aware next button
			if currentActivityIndex < activities.count {
				let currentValidation = activities[currentActivityIndex].getValidation(project: project, validationState: validationState)

				Button(currentValidation.nextButtonText) {
					// Perform any pre-navigation actions (like saving)
					if currentValidation.requiresPreNavigationAction {
						currentValidation.performPreNavigationAction()
					}
					moveToNextActivity()
				}
				.buttonStyle(.borderedProminent)
				.disabled(!currentValidation.canProceed)
			}
		}
		.padding()
	}
	
	/// Advances the workflow to the next activity step.
	///
	/// Handles forward navigation through the workflow sequence, marking
	/// the current activity as completed and transitioning to the next step.
	/// Triggers workflow completion when reaching the final activity.
	///
	/// ## State Management
	/// - Marks current activity as completed
	/// - Increments activity index with animation
	/// - Calls completion handler when workflow finishes
	///
	/// - Note: Includes bounds checking to prevent index overflow
	private func moveToNextActivity() {
		guard currentActivityIndex < activities.count - 1 else {
			// Process completed
			onCleanupAndDismiss()
			return
		}

		let previousIndex = currentActivityIndex

		// First, navigate to next activity
		withAnimation(.easeInOut(duration: 0.3)) {
			currentActivityIndex += 1
		}

		// Then mark previous activity as completed (after navigation)
		DispatchQueue.main.async {
			var updatedActivities = self.activities
			updatedActivities[previousIndex].isCompleted = true
			self.activities = updatedActivities
		}
	}
	
	/// Returns the workflow to the previous activity step.
	///
	/// Handles backward navigation through the workflow sequence with
	/// smooth animation transitions. Includes bounds checking to prevent
	/// navigation before the first step.
	///
	/// ## State Management
	/// - Decrements activity index with animation
	/// - Maintains activity completion states
	/// - Respects workflow boundaries
	///
	/// - Note: Does not affect completion status of activities
	private func moveToPreviousActivity() {
		guard currentActivityIndex > 0 else { return }
		
		withAnimation(.easeInOut(duration: 0.3)) {
			currentActivityIndex -= 1
		}
	}
}

// MARK: - Activity Validation Protocol

/// Protocol for activity views to provide validation status for navigation control
protocol ActivityValidation {
	/// Indicates whether the current activity can proceed to the next step
	var canProceed: Bool { get }

	/// Provides context-specific button text for the inspector footer
	var nextButtonText: String { get }

	/// Indicates if the activity requires special handling (like auto-save)
	var requiresPreNavigationAction: Bool { get }

	/// Performs any necessary actions before navigation (like saving)
	func performPreNavigationAction()
}

// MARK: - Activity Validation Helpers

/// Validation wrapper for ValidateContentActivityView
struct ValidateContentActivityValidation: ActivityValidation {
	let validationState: ValidationState

	var canProceed: Bool {
		validationState == .success
	}

	var nextButtonText: String {
		switch validationState {
		case .notStarted:
			return "Validating..."
		case .running:
			return "Validating..."
		case .success:
			return "Continue"
		case .failure:
			return "Fix Issues First"
		}
	}

	var requiresPreNavigationAction: Bool { false }
	func performPreNavigationAction() { }
}

// MARK: - Activity Views

struct WelcomeActivityView: View, ActivityValidation {

	// MARK: - ActivityValidation
	var canProceed: Bool { true }
	var nextButtonText: String { "Start Process" }
	var requiresPreNavigationAction: Bool { false }
	func performPreNavigationAction() { }
	var body: some View {
		VStack(spacing: 20) {
			Image(systemName: "flowchart")
				.font(.system(size: 48))
				.foregroundStyle(.blue)

			Text("Process Flow")
				.font(.title3)
				.fontWeight(.semibold)

			Text("This guided process flow will help you create engaging blog content from your showroom documentation.")
				.multilineTextAlignment(.center)
				.foregroundStyle(.secondary)

			VStack(alignment: .leading, spacing: 8) {
				ForEach(BlogActivityType.allCases.filter { $0 != .introduction }, id: \.self) { activityType in
					Label(activityType.rawValue, systemImage: activityType.imageName)
				}
			}
			.font(.subheadline)
			.foregroundStyle(.secondary)
		}
		.padding()
	}
}

/// View for reviewing generated blog content (read-only).
///
/// `ReviewContentView` provides a read-only interface for users to review
/// generated blog content. The view loads content from the project's
/// BlogPostContent.md file and displays it with markdown rendering.
///
/// ## Features
/// - Load generated content from file system using security-scoped access
/// - Markdown preview with GitHub styling
/// - Error handling for file operations
/// - Navigation controls for workflow progression
///
/// ## Usage
/// Used in the blog creation workflow after content generation to allow users
/// to review the AI-generated content before finalizing or proceeding to next steps.
struct ReviewContentView: View, ActivityValidation {
	let project: Project

	@State private var blogContent: String = ""
	@State private var isLoading: Bool = true
	@State private var loadError: String?
	
	private var hasContent: Bool {
		!blogContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
	}

	// MARK: - ActivityValidation
	var canProceed: Bool { hasContent }
	var nextButtonText: String { "Done" }
	var requiresPreNavigationAction: Bool { false }
	func performPreNavigationAction() { }
	
	var body: some View {
		VStack(spacing: 0) {
			// Header section
			VStack(spacing: 16) {
				Image(systemName: BlogActivityType.reviewEdit.imageName)
					.font(.system(size: 40))
					.foregroundStyle(.green)
					.symbolRenderingMode(.hierarchical)
				
				VStack(spacing: 8) {
					Text(BlogActivityType.reviewEdit.rawValue)
						.font(.title2)
						.fontWeight(.semibold)
						.foregroundStyle(.primary)
					
					Text("Review your generated blog content. The content is displayed with markdown formatting for easy reading.")
						.font(.subheadline)
						.multilineTextAlignment(.center)
						.foregroundStyle(.secondary)
						.fixedSize(horizontal: false, vertical: true)
				}
			}
			.padding(.bottom, 24)
			
			// Content area
			if isLoading {
				VStack(spacing: 16) {
					ProgressView()
						.controlSize(.large)
					Text("Loading generated content...")
						.foregroundStyle(.secondary)
				}
				.frame(maxWidth: .infinity, maxHeight: .infinity)
			} else if let error = loadError {
				VStack(spacing: 16) {
					Image(systemName: "exclamationmark.triangle")
						.font(.system(size: 48))
						.foregroundStyle(.orange)
					
					Text("Error Loading Content")
						.font(.headline)
					
					Text(error)
						.multilineTextAlignment(.center)
						.foregroundStyle(.secondary)
					
					Button("Retry") {
						loadContent()
					}
					.buttonStyle(.bordered)
				}
				.frame(maxWidth: .infinity, maxHeight: .infinity)
			} else {
				VStack(spacing: 0) {
					// Content toolbar
					HStack {
						Text("Generated Content")
							.font(.subheadline)
							.fontWeight(.medium)
							.foregroundStyle(.secondary)
						
						Spacer()
						
						Button(action: copyToClipboard) {
							HStack(spacing: 4) {
								Image(systemName: "doc.on.clipboard")
								Text("Copy")
							}
						}
						.buttonStyle(.bordered)
						.controlSize(.small)
						.disabled(!hasContent)
					}
					.padding(.horizontal)
					.padding(.bottom, 8)
					
					// Content preview (read-only)
					ScrollView {
						if hasContent {
							Markdown(blogContent)
								.markdownTheme(.gitHub)
								.padding()
						} else {
							VStack(spacing: 12) {
								Image(systemName: "doc.text")
									.font(.system(size: 48))
									.foregroundStyle(.secondary)
								Text("No content to review")
									.foregroundStyle(.secondary)
							}
							.frame(maxWidth: .infinity, maxHeight: .infinity)
						}
					}
					.background(Color(.controlBackgroundColor))
					.clipShape(RoundedRectangle(cornerRadius: 8))
					.padding(.horizontal)
				}
			}
		}
		.padding()
		.onAppear {
			loadContent()
		}
	}
	
	/// Copies the current blog content to the system clipboard.
	///
	/// Uses NSPasteboard to copy the markdown content to the system clipboard,
	/// making it available for pasting into other applications.
	private func copyToClipboard() {
		let pasteboard = NSPasteboard.general
		pasteboard.clearContents()
		pasteboard.setString(blogContent, forType: .string)
	}
	
	/// Loads the generated blog content from the project's file system.
	///
	/// Uses security-scoped access to read the BlogPostContent.md file from the
	/// project's local folder. Updates the view state based on success or failure.
	private func loadContent() {
		isLoading = true
		loadError = nil
		
		Task {
			do {
				let content = try await project.withSecureFolderAccess {
					guard let localFolderPath = project.localFolderPath else {
						throw NSError(domain: "ReviewContentError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Local folder path not configured"])
					}
					
					let filePath = URL(fileURLWithPath: localFolderPath)
						.appendingPathComponent("BlogPostContent.md")
					
					// Check if file exists
					guard FileManager.default.fileExists(atPath: filePath.path) else {
						throw NSError(domain: "ReviewContentError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Blog content file not found. Generate content first."])
					}
					
					return try String(contentsOf: filePath, encoding: .utf8)
				}
				
				await MainActor.run {
					blogContent = content
					isLoading = false
				}
			} catch {
				await MainActor.run {
					loadError = error.localizedDescription
					isLoading = false
				}
			}
		}
	}
}

struct PlaceholderActivityView: View, ActivityValidation {
	let title: String

	// MARK: - ActivityValidation
	var canProceed: Bool { true }
	var nextButtonText: String { "Continue" }
	var requiresPreNavigationAction: Bool { false }
	func performPreNavigationAction() { }

	var body: some View {
		VStack(spacing: 20) {
			Image(systemName: "gear")
				.font(.system(size: 48))
				.foregroundStyle(.orange)

			Text(title)
				.font(.title3)
				.fontWeight(.semibold)

			Text("This activity will be implemented in a future update.")
				.multilineTextAlignment(.center)
				.foregroundStyle(.secondary)

			Text("Navigation is handled by the inspector controls.")
				.font(.caption)
				.multilineTextAlignment(.center)
				.foregroundStyle(.tertiary)
		}
		.padding()
	}
}

/// State management for repository content validation process.
///
/// Tracks the progress and outcome of showroom repository validation,
/// providing granular state information for UI updates and user feedback.
/// Used throughout the validation workflow to manage process flow.
///
/// ## State Transitions
/// ```
/// notStarted → running → success/failure
///     ↑                    │
///     └────────────────────┘
/// ```
///
/// - SeeAlso: `ValidateContentActivityView` for state usage
enum ValidationState: Equatable {
	case notStarted
	case running
	case success
	case failure(String)
}

/// Activity view for validating showroom repository content and structure.
///
/// `ValidateContentActivityView` performs comprehensive validation of the cloned
/// repository content to ensure it contains valid showroom documentation that
/// can be used for blog generation. Handles security-scoped access and provides
/// detailed feedback about validation progress and results.
///
/// ## Validation Process
/// 1. **Path Validation**: Verifies showroom local path configuration
/// 2. **Security Access**: Establishes security-scoped bookmark access
/// 3. **Directory Validation**: Confirms directory exists and is readable
/// 4. **Content Validation**: Checks for readable files in showroom directory
/// 5. **Repository Parsing**: Uses ShowroomParser to validate structure
///
/// ## User Experience
/// - Automatic validation start on view appearance
/// - Real-time progress indicator during validation
/// - Clear success/failure messaging with actionable feedback
/// - Navigation controls for workflow progression
///
/// ## Error Handling
/// Provides specific error messages for common failure scenarios:
/// - Missing security bookmarks
/// - Invalid directory paths
/// - Empty or unreadable repositories
/// - ShowroomParser validation failures
///
/// - Important: Automatically starts validation process on view appearance
/// - Note: Stores parsed repository in project's transient property for later use
struct ValidateContentActivityView: View, ActivityValidation {
	let project: Project
	@Binding var externalValidationState: ValidationState

	@State private var validationTask: Task<Void, Never>?

	private var validationState: ValidationState {
		externalValidationState
	}

	// MARK: - ActivityValidation
	var canProceed: Bool {
		validationState == .success
	}

	var nextButtonText: String {
		switch validationState {
		case .notStarted:
			return "Validating..."
		case .running:
			return "Validating..."
		case .success:
			return "Continue"
		case .failure:
			return "Fix Issues First"
		}
	}

	var requiresPreNavigationAction: Bool { false }
	func performPreNavigationAction() { }
	
	var body: some View {
		VStack(spacing: 24) {
			// Header icon and title
			Image(systemName: "checkmark.shield")
				.font(.system(size: 48))
				.foregroundStyle(iconColor)
			
			Text("Validate Source Content")
				.font(.title3)
				.fontWeight(.semibold)
			
			// Status content
			statusContentView
			
			// Progress indicator (shown only when running)
			if case .running = validationState {
				VStack(spacing: 12) {
					ProgressView()
						.progressViewStyle(.circular)
						.controlSize(.large)
						.tint(.blue)
					
					Text("Validating repository content...")
						.font(.caption)
						.foregroundStyle(.secondary)
				}
			}
			
			// Action buttons
			actionButtonsView
		}
		.padding()
		.onAppear {
			startValidationProcess(project)
		}
		.onDisappear {
			cancelValidation()
		}
	}
	
	@ViewBuilder
	private var statusContentView: some View {
		switch validationState {
			case .notStarted:
				Text("Preparing to validate showroom source content...")
					.multilineTextAlignment(.center)
					.foregroundStyle(.secondary)
				
			case .running:
				Text("Checking showroom structure and files...")
					.multilineTextAlignment(.center)
					.foregroundStyle(.secondary)
				
			case .success:
				VStack(spacing: 8) {
					Text("✅ Showroom content validation successful!")
						.font(.headline)
						.foregroundStyle(.green)
					
					Text("Your showroom contains valid content that can be used for blog generation.")
						.multilineTextAlignment(.center)
						.foregroundStyle(.secondary)
				}
				
			case .failure(let errorMessage):
				VStack(spacing: 8) {
					Text("❌ Validation failed")
						.font(.headline)
						.foregroundStyle(.red)
					
					Text(errorMessage)
						.multilineTextAlignment(.center)
						.foregroundStyle(.secondary)
				}
		}
	}
	
	@ViewBuilder
	private var actionButtonsView: some View {
		HStack(spacing: 16) {
			Spacer()

			switch validationState {
				case .notStarted, .running:
					// Cancel button during validation
					Button("Cancel Validation") {
						cancelValidation()
					}
					.buttonStyle(.bordered)
					.foregroundStyle(.red)

				case .success:
					// No action needed - navigation handled by inspector
					EmptyView()

				case .failure:
					// Retry button after failure
					Button("Retry Validation") {
						startValidationProcess(project)
					}
					.buttonStyle(.borderedProminent)
			}
		}
	}
	
	private var iconColor: Color {
		switch validationState {
			case .notStarted, .running:
				return .blue
			case .success:
				return .green
			case .failure:
				return .red
		}
	}
	
	private func startValidationProcess(_ project: Project) {
		guard validationState != .running else { return }

		externalValidationState = .running

		// Start the actual validation task
		validationTask = Task {
			await performValidation(project)
		}
	}
	
	private func performValidation(_ project: Project) async {
		// Simulate validation process with realistic timing
		do {
			//			// validate that the cloned files path exists
			//			guard let localFolderPath = project.localFolderPath else {
			//				validationState = .failure("Local path for the showroom files is missing.")
			//				return
			//			}
			
			// validate that the showroom file path exists
			guard let showroomLocalPath = project.showroomLocalPath else {
				await MainActor.run {
					externalValidationState = .failure("Local path for the showroom files is missing.")
				}
				return
			}
			
			// Use security-scoped bookmark to access the directory if available
			var accessStarted = false
			var bookmarkURL: URL?
			
			if let bookmarkData = project.localFolderBookmark {
				do {
					var isStale = false
					bookmarkURL = try URL(resolvingBookmarkData: bookmarkData,
												 options: .withSecurityScope,
												 relativeTo: nil,
												 bookmarkDataIsStale: &isStale)
					if let url = bookmarkURL {
						accessStarted = url.startAccessingSecurityScopedResource()
					}
				} catch {
					await MainActor.run {
						externalValidationState = .failure("Failed to resolve security bookmark: \(error.localizedDescription)")
					}
					return
				}
			} else {
				// If no bookmark available, we may not have sandbox permissions
				await MainActor.run {
					externalValidationState = .failure("No security bookmark available. Please reconfigure the project folder to grant access permissions.")
				}
				return
			}
			
			defer {
				if accessStarted, let url = bookmarkURL {
					url.stopAccessingSecurityScopedResource()
				}
			}
			
			// Verify that showroomLocalPath is within the bookmarked directory
			if let url = bookmarkURL {
				let bookmarkedPath = url.path
				if !showroomLocalPath.hasPrefix(bookmarkedPath) {
					await MainActor.run {
						externalValidationState = .failure("Showroom path '\(showroomLocalPath)' is not within the authorized directory '\(bookmarkedPath)'")
					}
					return
				}
			}
			
			// Validate that the showroom directory exists
			guard FileManager.default.fileExists(atPath: showroomLocalPath) else {
				await MainActor.run {
					externalValidationState = .failure("Showroom directory does not exist at path: \(showroomLocalPath)")
				}
				return
			}
			
			// Validate that files in the showroom directory can be read
			do {
				let contents = try FileManager.default.contentsOfDirectory(atPath: showroomLocalPath)
				guard !contents.isEmpty else {
					await MainActor.run {
						externalValidationState = .failure("Showroom directory is empty: \(showroomLocalPath)")
					}
					return
				}
				
				// Check if we can read at least one file in the directory
				var canReadFiles = false
				for fileName in contents {
					let filePath = (showroomLocalPath as NSString).appendingPathComponent(fileName)
					if FileManager.default.isReadableFile(atPath: filePath) {
						canReadFiles = true
						break
					}
				}
				
				guard canReadFiles else {
					await MainActor.run {
						externalValidationState = .failure("Cannot read files in showroom directory: \(showroomLocalPath)")
					}
					return
				}
			} catch {
				await MainActor.run {
					externalValidationState = .failure("Failed to access showroom directory: \(error.localizedDescription)")
				}
				return
			}
			
			// Use ShowroomParser to validate and parse the repository
			do {
				guard let repositoryPath = project.repositoryLocalPath else {
					await MainActor.run {
						externalValidationState = .failure("Repository local path is not configured")
					}
					return
				}
				
				// Parse the showroom repository using ShowroomParser
				guard let showroomRepository = ShowroomParser.parseRepository(at: repositoryPath) else {
					await MainActor.run {
						externalValidationState = .failure("Failed to parse showroom repository at path: \(repositoryPath)")
					}
					return
				}
				
				// Store the parsed repository in the project for use in content generation
				// Note: This is @Transient and will not be persisted to the data store
				await MainActor.run {
					project.showroomRepository = showroomRepository
					externalValidationState = .success
				}
			} catch {
				await MainActor.run {
					externalValidationState = .failure("Failed to parse showroom repository: \(error.localizedDescription)")
				}
				return
			}
		} catch {
			await MainActor.run {
				externalValidationState = .failure("Validation was cancelled or interrupted.")
			}
		}
	}
	
	private func cancelValidation() {
		validationTask?.cancel()
		validationTask = nil

		if case .running = validationState {
			externalValidationState = .notStarted
		}
	}
}

/// Activity view for configuring the LLM prompt used in content generation.
///
/// `GatherPromptView` provides an interface for users to customize the prompt
/// that will be sent to the language model along with the showroom content.
/// Features a rich text editor with change tracking and save/revert functionality.
///
/// ## Prompt Configuration
/// - Loads existing prompt from project configuration
/// - Provides rich text editing with monospaced font
/// - Tracks unsaved changes with visual indicators
/// - Offers save and revert controls for change management
///
/// ## User Interface Features
/// - **Change Tracking**: Visual indicators for unsaved modifications
/// - **Save/Revert Controls**: Immediate feedback and change management
/// - **Validation**: Ensures prompt is properly configured for generation
/// - **Accessibility**: Keyboard shortcuts and helpful tooltips
///
/// ## Data Management
/// Prompt text is stored in the project's `blogPrompt` property and persists
/// across workflow sessions. Changes are only saved when explicitly requested.
///
/// - Important: Changes are not automatically saved; users must explicitly save
/// - Note: Supports multi-line prompts with rich text editing capabilities
struct GatherPromptView: View, ActivityValidation {

	let project: Project

	@State private var promptText: String = ""
	@State private var originalPromptText: String = ""

	private var hasChanges: Bool {
		promptText != originalPromptText
	}

	// MARK: - ActivityValidation
	var canProceed: Bool { true }

	var nextButtonText: String {
		hasChanges ? "Save & Continue" : "Continue"
	}

	var requiresPreNavigationAction: Bool { hasChanges }

	func performPreNavigationAction() {
		if hasChanges {
			savePrompt()
		}
	}
	
	var body: some View {
		VStack(spacing: 0) {
			// Header section
			VStack(spacing: 16) {
				Image(systemName: BlogActivityType.providePrompt.imageName)
					.font(.system(size: 40))
					.foregroundStyle(.blue)
					.symbolRenderingMode(.hierarchical)
				
				VStack(spacing: 8) {
					Text(BlogActivityType.providePrompt.rawValue)
						.font(.title2)
						.fontWeight(.semibold)
						.foregroundStyle(.primary)
					
					Text("Configure the prompt that will be sent to the LLM along with your showroom content to generate the blog post.")
						.font(.subheadline)
						.multilineTextAlignment(.center)
						.foregroundStyle(.secondary)
						.fixedSize(horizontal: false, vertical: true)
				}
			}
			.padding(.top, 24)
			.padding(.horizontal, 24)
			
			// Content section
			VStack(spacing: 0) {
				// Form-like container for the text editor
				GroupBox {
					VStack(alignment: .leading, spacing: 12) {
						// Header with save/revert controls
						HStack(alignment: .center) {
							Label("Prompt Text", systemImage: "text.cursor")
								.font(.headline)
								.foregroundStyle(.primary)
							
							Spacer()
							
							if hasChanges {
								HStack(spacing: 8) {
									Button("Revert") {
										revertChanges()
									}
									.buttonStyle(.bordered)
									.controlSize(.small)
									.help("Discard changes and restore original prompt")
									
									Button("Save") {
										savePrompt()
									}
									.buttonStyle(.borderedProminent)
									.controlSize(.small)
									.help("Save prompt to project")
								}
							}
						}
						
						// Text editor with proper styling
						TextEditor(text: $promptText)
							.font(.system(.body, design: .monospaced))
							.scrollContentBackground(.hidden)
							.background(Color(NSColor.textBackgroundColor))
							.frame(minHeight: 200, maxHeight: 300)
							.overlay(
								RoundedRectangle(cornerRadius: 8)
									.stroke(
										hasChanges ? Color.accentColor : Color(NSColor.separatorColor),
										lineWidth: hasChanges ? 2 : 1
									)
							)
							.cornerRadius(8)
						
						// Footer info
						HStack {
							Text("Use this field to specify how the LLM should process your showroom content.")
								.font(.caption)
								.foregroundStyle(.secondary)
							
							Spacer()
							
							if hasChanges {
								HStack(spacing: 6) {
									Image(systemName: "exclamationmark.circle.fill")
										.foregroundStyle(.orange)
										.font(.caption)
									Text("Unsaved changes")
										.font(.caption)
										.foregroundStyle(.orange)
										.fontWeight(.medium)
								}
							}
						}
					}
					.padding(16)
				}
				.padding(.horizontal, 24)
				.padding(.top, 24)
			}
		}
		.onAppear {
			loadPromptFromProject()
		}
	}
	
	private func loadPromptFromProject() {
		// Load the prompt from the project (assuming there's a blogPrompt property)
		// If the project doesn't have this property yet, you'll need to add it to the Project model
		let currentPrompt = project.blogPrompt ?? ""
		promptText = currentPrompt
		originalPromptText = currentPrompt
	}
	
	private func savePrompt() {
		// Save the prompt to the project
		project.blogPrompt = promptText
		originalPromptText = promptText
	}
	
	private func revertChanges() {
		promptText = originalPromptText
	}
}

/// Activity view for LLM configuration and blog content generation.
///
/// `GenerateContentView` combines LLM service configuration with content generation
/// functionality. Users configure their language model settings and execute
/// the blog generation process using their showroom repository content.
///
/// ## Configuration Management
/// - **LLM Connection**: URL endpoint for OpenAI-compatible chat completions
/// - **Model Selection**: Model name specification (GPT-4, Ollama models, etc.)
/// - **Authentication**: Secure API key storage and management
/// - **Generation Settings**: Temperature control for output creativity
///
/// ## Content Generation Process
/// 1. Validates LLM configuration completeness
/// 2. Loads showroom repository content from project
/// 3. Constructs chat completion request with system and user prompts
/// 4. Executes LLM inference with configured parameters
/// 5. Processes and presents generated content
///
/// ## User Experience Features
/// - **Change Tracking**: Visual indicators for unsaved configuration changes
/// - **Validation**: Real-time validation of required configuration fields
/// - **Progress Feedback**: Generation status with loading indicators
/// - **Error Handling**: Detailed error reporting for troubleshooting
///
/// ## Integration Points
/// - Uses `SwiftChatCompletionsDSL` for LLM communication
/// - Integrates with project's showroom repository content
/// - Applies user-configured blog prompt from previous workflow step
///
/// - Important: Requires valid LLM configuration before content generation
/// - Note: Supports various OpenAI-compatible LLM providers including local models
struct GenerateContentView: View, ActivityValidation {
	let project: Project

	@State private var llmUrl: String = ""
	@State private var llmModelName: String = ""
	@State private var llmAPIKey: String = ""
	@State private var originalLlmUrl: String = ""
	@State private var originalLlmModelName: String = ""
	@State private var originalLlmAPIKey: String = ""
	@State private var isGenerating: Bool = false
	
	
	private var hasChanges: Bool {
		llmUrl != originalLlmUrl ||
		llmModelName != originalLlmModelName ||
		llmAPIKey != originalLlmAPIKey
	}
	
	private var canGenerate: Bool {
		!llmUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
		!llmModelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
	}

	// MARK: - ActivityValidation
	var canProceed: Bool { true }

	var nextButtonText: String { "Continue" }

	var requiresPreNavigationAction: Bool { hasChanges }

	func performPreNavigationAction() {
		if hasChanges {
			saveLlmConfiguration()
		}
	}
	
	var body: some View {
		VStack(spacing: 0) {
			// Header section
			VStack(spacing: 16) {
				Image(systemName: BlogActivityType.generateContent.imageName)
					.font(.system(size: 40))
					.foregroundStyle(.blue)
					.symbolRenderingMode(.hierarchical)
				
				VStack(spacing: 8) {
					Text(BlogActivityType.generateContent.rawValue)
						.font(.title2)
						.fontWeight(.semibold)
						.foregroundStyle(.primary)
					
					Text("In this step, you will configure an LLM connection, and then generate the blog text.")
						.font(.subheadline)
						.multilineTextAlignment(.center)
						.foregroundStyle(.secondary)
						.fixedSize(horizontal: false, vertical: true)
				}
			}
			
			Spacer()
			
			/// This is the form used to collect information about the LLM connection
			Form {
				Section {
					HStack {
						TextField("LLM URL", text: $llmUrl, prompt: Text("https://api.openai.com/v1/chat/completions"))
							.textContentType(.URL)
							.autocorrectionDisabled()
							.textFieldStyle(.roundedBorder)
						
						// Required field indicator
						Image(systemName: llmUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "exclamationmark.circle" : "checkmark.circle.fill")
							.foregroundColor(llmUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : .green)
							.font(.title3)
					}
				} header: {
					HStack {
						Label("LLM Connection", systemImage: "link")
							.font(.headline)
						Text("(Required)")
							.font(.caption)
							.foregroundStyle(.orange)
							.fontWeight(.medium)
					}
				} footer: {
					Text("Enter the URL for your LLM's OpenAI-compatible Chat Completions endpoint.")
						.font(.caption)
				}
				
				Section {
					HStack {
						TextField("Model Name", text: $llmModelName, prompt: Text("gpt-4"))
							.autocorrectionDisabled()
							.textFieldStyle(.roundedBorder)
						
						// Required field indicator
						Image(systemName: llmModelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "exclamationmark.circle" : "checkmark.circle.fill")
							.foregroundColor(llmModelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : .green)
							.font(.title3)
					}
				} header: {
					HStack {
						Label("Model Configuration", systemImage: "brain")
							.font(.headline)
						Text("(Required)")
							.font(.caption)
							.foregroundStyle(.orange)
							.fontWeight(.medium)
					}
				} footer: {
					Text("Specify the model name to use for content generation.")
						.font(.caption)
				}
				
				Section {
					SecureField("API Key", text: $llmAPIKey, prompt: Text("sk-..."))
						.textFieldStyle(.roundedBorder)
				} header: {
					HStack {
						Label("Authentication", systemImage: "key.fill")
							.font(.headline)
						Text("(Optional)")
							.font(.caption)
							.foregroundStyle(.secondary)
							.fontWeight(.medium)
					}
				} footer: {
					Text("Your API key will be stored securely and used for authentication. Some local models don't require an API key.")
						.font(.caption)
				}
				
				Section {
					VStack(alignment: .leading, spacing: 8) {
						Text("Temperature: \(String(format: "%.1f", project.temperature))")
							.font(.subheadline)
							.fontWeight(.medium)
						
						Slider(
							value: Binding(
								get: { project.temperature },
								set: { project.temperature = $0 }
							),
							in: 0...2,
							step: 0.1
						)
						.tint(.blue)
						
						Text("Controls randomness in output. Lower values (0.2) = more focused and consistent. Higher values (1.8) = more creative and diverse.")
							.font(.caption)
							.foregroundStyle(.secondary)
							.fixedSize(horizontal: false, vertical: true)
					}
				} header: {
					Label("Generation Settings", systemImage: "slider.horizontal.3")
						.font(.headline)
				}
				
				if hasChanges {
					Section {
						HStack(spacing: 12) {
							Button("Revert Changes") {
								revertLLMConfigChanges()
							}
							.buttonStyle(.bordered)
							
							Button("Save Configuration") {
								saveLlmConfiguration()
							}
							.buttonStyle(.borderedProminent)
						}
					} footer: {
						HStack {
							Image(systemName: "exclamationmark.circle.fill")
								.foregroundStyle(.orange)
							Text("You have unsaved changes to the LLM configuration.")
								.font(.caption)
								.foregroundStyle(.orange)
						}
					}
				}
			}
			.formStyle(.grouped)
			
			// Generate button section (progressive disclosure)
			VStack(spacing: 16) {
				if !canGenerate {
					// Guidance section when requirements not met
					VStack(spacing: 12) {
						HStack {
							Image(systemName: "info.circle.fill")
								.foregroundStyle(.blue)
								.font(.title3)
							
							VStack(alignment: .leading, spacing: 4) {
								Text("Ready to Generate?")
									.font(.headline)
									.foregroundStyle(.primary)
								
								Text("Complete the required fields above to enable content generation.")
									.font(.subheadline)
									.foregroundStyle(.secondary)
							}
							
							Spacer()
						}
						
						// Progress indicators
						VStack(spacing: 8) {
							HStack {
								Image(systemName: llmUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "circle" : "checkmark.circle.fill")
									.foregroundColor(llmUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : .green)
								Text("LLM URL configured")
									.foregroundStyle(llmUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : .primary)
								Spacer()
							}
							
							HStack {
								Image(systemName: llmModelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "circle" : "checkmark.circle.fill")
									.foregroundColor(llmModelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : .green)
								Text("Model name specified")
									.foregroundStyle(llmModelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : .primary)
								Spacer()
							}
						}
						.font(.subheadline)
						.padding(.leading, 8)
					}
					.padding()
					.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
				} else {
					// Generate button appears when ready
					VStack(spacing: 12) {
						Button(action: {
							Task {
								isGenerating = true
								defer { isGenerating = false }
								
								// Save LLM configuration to project before generating
								saveLlmConfiguration()
								
								do {
									if let result = try await generateBlogContent(project), !result.isEmpty {
										// Write the generated content to file using security-scoped access
										try await project.withSecureFolderAccess {
											guard let localFolderPath = project.localFolderPath else {
												throw NSError(domain: "BlogGoalError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Local folder path not configured"])
											}
											
											let filePath = URL(fileURLWithPath: localFolderPath)
												.appendingPathComponent("BlogPostContent.md")
											
											try result.write(to: filePath, atomically: true, encoding: .utf8)
											
											// Record the generated file in the project
											project.setGeneratedFile(for: .blogPost, fileName: "BlogPostContent.md")
										}
									}
								} catch {
									// TODO: Add error handling UI feedback
									print("Error generating or saving blog content: \(error.localizedDescription)")
								}
							}
						}) {
							HStack(spacing: 8) {
								Image(systemName: isGenerating ? "sparkles.rectangle.stack.fill" : "sparkles")
									.symbolEffect(.bounce.down.wholeSymbol, isActive: isGenerating)
								Text(isGenerating ? "Generating..." : "Generate Content")
							}
						}
						.buttonStyle(.borderedProminent)
						.controlSize(.large)
						.frame(maxWidth: .infinity)
						.disabled(isGenerating)
						
						Text("✓ Configuration complete - ready to generate!")
							.font(.caption)
							.foregroundStyle(.green)
							.fontWeight(.medium)
					}
				}
			}
			.padding(.horizontal, 16)
			.animation(.easeInOut(duration: 0.3), value: canGenerate)
			
		}
		.padding()
		.onAppear {
			loadLlmConfigurationFromProject()
		}
	}
	
	private func loadLlmConfigurationFromProject() {
		let currentUrl = project.llmUrl ?? ""
		let currentModelName = project.llmModelName ?? ""
		let currentAPIKey = project.llmAPIKey ?? ""
		
		llmUrl = currentUrl
		llmModelName = currentModelName
		llmAPIKey = currentAPIKey
		
		originalLlmUrl = currentUrl
		originalLlmModelName = currentModelName
		originalLlmAPIKey = currentAPIKey
	}
	
	private func saveLlmConfiguration() {
		project.llmUrl = llmUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : llmUrl.trimmingCharacters(in: .whitespacesAndNewlines)
		project.llmModelName = llmModelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : llmModelName.trimmingCharacters(in: .whitespacesAndNewlines)
		project.llmAPIKey = llmAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : llmAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
		
		originalLlmUrl = llmUrl
		originalLlmModelName = llmModelName
		originalLlmAPIKey = llmAPIKey
	}
	
	private func revertLLMConfigChanges() {
		llmUrl = originalLlmUrl
		llmModelName = originalLlmModelName
		llmAPIKey = originalLlmAPIKey
	}
	
	/// Define the full scope of errors that could be thrown
	private enum inferenceError: Error {
		case invalidServerType
		case noURL
		case noModelName
		case invalidURL
		case apiError(statusCode: Int, description: String)
		case encodingError
		case decodingError
	}
	
	/// This function will actiually call the LLM using the chat completions endpoint
	private func generateBlogContent(_ project: Project) async throws -> String? {
		
		// series of guard stements used since we will use the let values later in the code
		guard let urlComponents = URLComponents(string: project.llmUrl ?? "") else {
			throw inferenceError.invalidURL
		}
		// make sure scheme is valid (i.e. https), and host contains a value
		guard urlComponents.scheme != nil, urlComponents.host != nil else {
			throw inferenceError.invalidURL
		}
		// need a model name to make an inference call
		guard let modelName = project.llmModelName else {
			throw inferenceError.noModelName
		}
		
		guard let repo = project.showroomRepository else {
			throw inferenceError.apiError(statusCode: -1, description: "The showroom repository needs to be parsed before inference can be performed.")
		}
		
		let textToSummarize = repo.toMarkdown()
		guard !textToSummarize.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
			throw inferenceError.apiError(statusCode: -1, description: "No text from showroom was generated. Check to see if showroom is empty or incomplete.")
		}
		
		// default value is 60 seconds, and if you need longer than that, set the durations here
		let configuration = URLSessionConfiguration.default
		configuration.timeoutIntervalForRequest = 60 // set same as default for now.
		
		let client = try LLMClient(
			baseURL: project.llmUrl ?? "http://localhost:8321/v1/openai/v1/chat/completions",
			apiKey: project.llmAPIKey ?? ""
		)
		
		let request = try ChatRequest(model: modelName) {
			// Configure optional parameters
			try Temperature(project.temperature)
			//			try MaxTokens(150)
		} messages: {
			// Build the conversation using result builders
			TextMessage(role: .system, content: "You are a helpful assistant that excels at generating compelling technical blog articles.")
			TextMessage(role: .user, content: project.blogPrompt ?? "Generate a markdown formatted blog article using the text I will provide to in my next prompt.")
			TextMessage(role: .user, content: "The following content is what you think about and use to generate the blog article: \(textToSummarize)")
		}
		
		// Send the request and get the complete response
		do {
			let response = try await client.complete(request)
			
			// Process the response
			if let choice = response.choices.first {
				//				print("Assistant: \(choice.message.content)")
				//				print("Finish reason: \(choice.finishReason ?? "none")")
				return choice.message.content
			}
		} catch let error as LLMError {
			print("LLM Error: \(error)")
		} catch {
			print("Unexpected error: \(error)")
		}
		
		return ""
	}
}

//#Preview {
//	let sampleProject = Project(name: "Sample Project")
//	sampleProject.localFolderPath = "/Users/rnaszcyn/Development/TESTING/showroom"
//	sampleProject.repositoryURL = "https://github.com/rnaszcyn/showroom"
//	sampleProject.llmUrl = "http://localhost:8321/v1/openai/v1/chat/completions"
//	sampleProject.llmModelName	= "ollama/llama3.2:3b"
//	return BlogGoalInspector(
//		project: sampleProject,
//		onCleanupAndDismiss: {
//			// do nothing
//		}
//	)
//	.modelContainer(for: Project.self, inMemory: true)
//	.frame(height: 800)
//	.padding()
//}

//#Playground {
//	let client = try LLMClient(
//		baseURL: "http://localhost:8321/v1/openai/v1/chat/completions",
//		apiKey: ""
//	)
//
//	let request = try ChatRequest(model: "ollama/llama3.2:3b") {
//		// Configure optional parameters
//		try Temperature(0.7)
//		try MaxTokens(150)
//	} messages: {
//		// Build the conversation using result builders
//		TextMessage(role: .system, content: "You are a helpful assistant.")
//		TextMessage(role: .user, content: "Say hello.")
//	}
//
//	// Send the request and get the complete response
//	do {
//		let response = try await client.complete(request)
//
//		// Process the response
//		if let choice = response.choices.first {
//			print("Assistant: \(choice.message.content)")
//			print("Finish reason: \(choice.finishReason ?? "none")")
//		}
//
//		// Show token usage if available
//		if let usage = response.usage {
//			print("Tokens used: \(usage.totalTokens) (prompt: \(usage.promptTokens), completion: \(usage.completionTokens))")
//		}
//
//	} catch let error as LLMError {
//		print("LLM Error: \(error)")
//	} catch {
//		print("Unexpected error: \(error)")
//	}
//}
