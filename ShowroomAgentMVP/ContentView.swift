/*
 * ContentView.swift
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

import SwiftUI
import SwiftData
import ShowroomParser

// MARK: - Inspector State Management

/// Enum representing all possible inspector types
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

/// Observable state manager for the unified inspector
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

    /// Checks if the inspector is currently showing a workflow that conflicts with the requested type
    func hasConflictingWorkflow(for requestedType: InspectorType) -> Bool {
        guard isVisible, let current = currentType else { return false }

        switch (current, requestedType) {
        // Configuration conflicts with all workflows
        case (.configureProject, .blogGoal), (.configureProject, .activity):
            return true
        case (.blogGoal, .configureProject), (.activity, .configureProject):
            return true
        // Blog workflow conflicts with configuration
        case (.blogGoal, .blogGoal), (.activity, .activity):
            // Same workflow type for same project is allowed (just switches content)
            return false
        default:
            return false
        }
    }

    /// Checks if configuration inspector can be shown
    var canShowConfiguration: Bool {
        guard isVisible, let current = currentType else { return true }

        switch current {
        case .blogGoal, .activity:
            return false
        default:
            return true
        }
    }

    /// Checks if workflow inspectors can be shown
    var canShowWorkflow: Bool {
        guard isVisible, let current = currentType else { return true }

        switch current {
        case .configureProject:
            return false
        default:
            return true
        }
    }
}

/// Activity types for content generation cards
enum ActivityType: String, CaseIterable {
	case blogPost = "Blog Post"
	case socialMedia = "Social Media"
	case email = "Email"
	//	case presentation = "Presentation"
	//	case newsletter = "Newsletter"
	
	/// SF Symbol to use
	var systemImage: String {
		switch self {
			case .blogPost: return "document"
			case .socialMedia: return "photo"
			case .email: return "mail"
				//		case .presentation: return "presentation"
				//		case .newsletter: return "envelope"
		}
	}
	
	/// color to use for icon on content generation card
	var color: Color {
		switch self {
			case .blogPost: return .blue
			case .socialMedia: return .green
			case .email: return .orange
				//		case .presentation: return .purple
				//		case .newsletter: return .pink
		}
	}
	
	/// message describing a content generation card
	var subtitle: String {
		switch self {
			case .blogPost: return "Generate engaging blog content"
			case .socialMedia: return "Create social media posts"
			case .email: return "Create email templates to engage your audience"
				//		case .presentation: return "Create presentation slides"
				//		case .newsletter: return "Draft newsletter content"
		}
	}
}

/// main view for the app
struct ContentView: View {
	@Environment(\.modelContext) private var modelContext
	@Query private var projects: [Project]
	@State private var selectedProject: Project?
	@State private var showingDeleteConfirmation = false
	@State private var projectToDelete: Project?
	@State private var inspectorState = InspectorState()

	/// Creates sample projects if none exist in the database
	/// WARNING: This function is currently DISABLED to prevent unwanted sample projects
	private func createSampleProjectsIfNeeded() {
		// This function is disabled - sample projects will not be created
		guard projects.isEmpty else { return }

		// DISABLED: Sample project creation is commented out
		/*
		let sampleProjects = [
			Project(name: "SwiftUI Documentation Generator"),
			Project(name: "iOS App Showcase"),
			Project(name: "API Reference Builder"),
			Project(name: "Technical Blog Creator")
		]

		for project in sampleProjects {
			modelContext.insert(project)
		}

		try? modelContext.save()
		*/
	}

	var body: some View {
		NavigationSplitView {
			ProjectListView(
				projects: projects,
				selectedProject: $selectedProject,
				onDeleteProjects: deleteProjects,
				onNewProject: { inspectorState.show(.newProject) }
			)
			.navigationSplitViewColumnWidth(min: 300, ideal: 400, max: 400)
		} detail: {
			if let selectedProject = selectedProject {
				ProjectDetailView(
					project: selectedProject,
					onConfigureProject: showProjectConfiguration,
					onShowBlogGoal: showBlogGoal,
					inspectorState: inspectorState
				)
			} else {
				ContentUnavailableView(
					"Select a Project",
					systemImage: "folder.badge.plus",
					description: Text("Choose a project from the sidebar to view its details and manage content generation.")
				)
			}
		}
		.inspector(isPresented: $inspectorState.isVisible) {
			UnifiedInspector(onCreateProject: createProject)
				.inspectorColumnWidth(min: 300, ideal: 400, max: 500)
		}
		.frame(minWidth: 900, minHeight: 500)
		.environment(inspectorState)
		.onAppear {
			// createSampleProjectsIfNeeded() - PERMANENTLY DISABLED
		}
		.confirmationDialog(
			"Delete Project",
			isPresented: $showingDeleteConfirmation,
			titleVisibility: .visible
		) {
			Button("Delete", role: .destructive) {
				confirmDeleteProject()
			}
			Button("Cancel", role: .cancel) {
				projectToDelete = nil
			}
		} message: {
			if let projectToDelete = projectToDelete {
				Text("Are you sure you want to delete \"\(projectToDelete.name)\"? This action cannot be undone.")
			}
		}
	}
	
	private func createProject(name: String, repositoryURL: String? = nil, localFolderPath: String? = nil, bookmark: Data? = nil) {
		withAnimation {
			let newProject = Project(name: name)
			newProject.updateRepositorySettings(repositoryURL: repositoryURL, localFolderPath: localFolderPath, localFolderBookmark: bookmark)
			modelContext.insert(newProject)
		}
	}
	
	private func deleteProjects(offsets: IndexSet) {
		// For now, only handle single project deletion with confirmation
		// In the future, this could be enhanced to handle multiple projects
		guard let index = offsets.first else { return }
		projectToDelete = projects[index]
		showingDeleteConfirmation = true
	}
	
	private func confirmDeleteProject() {
		guard let projectToDelete = projectToDelete else { return }
		withAnimation {
			if selectedProject == projectToDelete {
				selectedProject = nil
			}
			modelContext.delete(projectToDelete)
			self.projectToDelete = nil
		}
	}
	
	func showProjectConfiguration(for project: Project) {
		inspectorState.show(.configureProject(project))
	}

	func showBlogGoal(for project: Project) {
		inspectorState.show(.blogGoal(project))
	}
}

/// Row view for displaying project information in the sidebar
struct ProjectRowView: View {
	let project: Project
	
	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(project.name)
				.font(.headline)
				.lineLimit(2)

			HStack(spacing: 8) {
				Image(systemName: "calendar")
					.foregroundStyle(.secondary)
					.font(.caption)

				Text(project.createdDate, format: .dateTime.month(.abbreviated).day().year())
					.font(.caption)
					.foregroundStyle(.secondary)

				Spacer()

				// Show clone status indicator
				switch project.cloneStatus {
					case .notStarted:
						if project.repositoryURL != nil || project.localFolderPath != nil {
							Image(systemName: "gear")
								.foregroundStyle(.orange)
								.font(.caption)
						}
					case .cloning:
						Image(systemName: "arrow.down.circle")
							.foregroundStyle(.blue)
							.font(.caption)
					case .completed:
						Image(systemName: "checkmark.circle.fill")
							.foregroundStyle(.green)
							.font(.caption)
					case .failed:
						Image(systemName: "exclamationmark.circle.fill")
							.foregroundStyle(.red)
							.font(.caption)
				}
			}
		}
		.padding(.vertical, 2)
		.frame(maxWidth: .infinity, alignment: .leading)
	}
}

/// List view for displaying projects in the sidebar
struct ProjectListView: View {
	let projects: [Project]
	@Binding var selectedProject: Project?
	let onDeleteProjects: (IndexSet) -> Void
	let onNewProject: () -> Void

	var body: some View {
		List(selection: $selectedProject) {
			ForEach(projects) { project in
				NavigationLink(value: project) {
					ProjectRowView(project: project)
				}
			}
			.onDelete(perform: onDeleteProjects)
		}
		.navigationTitle("Projects")
		.toolbar {
			ToolbarItem(placement: .primaryAction) {
				Button(action: onNewProject) {
					Label("New Project", systemImage: "plus")
				}
				.help("Create a new project")
			}
		}
		.onDeleteCommand {
			// Handle delete command for selected items (macOS Delete key)
			if let selectedProject = selectedProject,
			   let index = projects.firstIndex(where: { $0.id == selectedProject.id }) {
				onDeleteProjects(IndexSet(integer: index))
			}
		}
		.contextMenu {
			if let selectedProject = selectedProject,
			   let index = projects.firstIndex(where: { $0.id == selectedProject.id }) {
				Button(role: .destructive) {
					onDeleteProjects(IndexSet(integer: index))
				} label: {
					Label("Delete Project", systemImage: "trash")
				}
			}
		}
	}
}

/// Unified inspector view for creating new projects or configuring existing ones
struct ProjectSetupInspector: View {
	@State private var projectName: String
	@State private var repositoryURL: String
	@State private var localFolderPath: String
	@FocusState private var isProjectNameFocused: Bool

	// Original values for change detection
	private let originalProjectName: String
	private let originalRepositoryURL: String
	private let originalLocalFolderPath: String

	let mode: SetupMode
	let onComplete: (String, String?, String?, Data?) -> Void
	let onDismiss: () -> Void
	
	enum SetupMode {
		case create
		case configure(Project)
		
		var title: String {
			switch self {
			case .create: return "New Project"
			case .configure: return "Configure Project"
			}
		}
		
		var subtitle: String {
			switch self {
			case .create: return "Create a new content generation project"
			case .configure(let project): return "Update \(project.name) settings"
			}
		}
		
	}
	
	init(mode: SetupMode, onComplete: @escaping (String, String?, String?, Data?) -> Void, onDismiss: @escaping () -> Void) {
		self.mode = mode
		self.onComplete = onComplete
		self.onDismiss = onDismiss

		switch mode {
		case .create:
			let initialName = ""
			let initialRepoURL = ""
			let initialFolderPath = ""

			self._projectName = State(initialValue: initialName)
			self._repositoryURL = State(initialValue: initialRepoURL)
			self._localFolderPath = State(initialValue: initialFolderPath)

			self.originalProjectName = initialName
			self.originalRepositoryURL = initialRepoURL
			self.originalLocalFolderPath = initialFolderPath

		case .configure(let project):
			let initialName = project.name
			let initialRepoURL = project.repositoryURL ?? ""
			let initialFolderPath = project.localFolderPath ?? ""

			self._projectName = State(initialValue: initialName)
			self._repositoryURL = State(initialValue: initialRepoURL)
			self._localFolderPath = State(initialValue: initialFolderPath)

			self.originalProjectName = initialName
			self.originalRepositoryURL = initialRepoURL
			self.originalLocalFolderPath = initialFolderPath
		}
	}
	
	var body: some View {
		ScrollView {
			VStack(spacing: 20) {
				// Header
				VStack(spacing: 8) {
					Text(mode.title)
						.font(.title3)
						.fontWeight(.semibold)

					Text(mode.subtitle)
						.font(.caption)
						.foregroundStyle(.secondary)
						.multilineTextAlignment(.center)
				}
				.padding(.top, 8)

				// Form sections
				VStack(spacing: 16) {
					// Project Information - shown for both create and configure modes
					GroupBox {
						VStack(alignment: .leading, spacing: 12) {
							Label("Project Information", systemImage: "folder.badge.plus")
								.font(.subheadline)
								.fontWeight(.medium)

							TextField("Project Name", text: $projectName, prompt: Text("My Project"))
								.focused($isProjectNameFocused)
								.textFieldStyle(.roundedBorder)

							Text("Enter a descriptive name that will help you identify this project.")
								.font(.caption2)
								.foregroundStyle(.secondary)
						}
						.padding()
					}

					GroupBox {
						VStack(alignment: .leading, spacing: 12) {
							Label("Source Repository", systemImage: "link")
								.font(.subheadline)
								.fontWeight(.medium)

							TextField("Repository URL", text: $repositoryURL, prompt: Text("https://github.com/username/repository"))
								.textContentType(.URL)
								.autocorrectionDisabled()
								.textFieldStyle(.roundedBorder)

							VStack(alignment: .leading, spacing: 8) {
								Text("Local Folder")
									.font(.caption)
									.fontWeight(.medium)

								HStack {
									TextField("Choose a folder...", text: $localFolderPath)
										.disabled(true)
										.foregroundStyle(localFolderPath.isEmpty ? .tertiary : .primary)
										.textFieldStyle(.roundedBorder)

									Button("Browse") {
										selectLocalFolder()
									}
									.buttonStyle(.bordered)
									.controlSize(.small)
								}

								if !localFolderPath.isEmpty {
									Text(localFolderPath)
										.font(.caption2)
										.foregroundStyle(.secondary)
										.lineLimit(2)
								}
							}

							Text("The GitHub repository containing your documentation and the folder where files will be stored. Both can be configured later.")
								.font(.caption2)
								.foregroundStyle(.secondary)
						}
						.padding()
					}
				}

				// Bottom buttons - Following Apple HIG: Cancel (left), Primary Action (right)
				HStack(spacing: 12) {
					Button("Cancel") {
						onDismiss()
					}
					.buttonStyle(.bordered)
					.keyboardShortcut(.cancelAction)

					Spacer()

					Button(dynamicPrimaryButtonTitle) {
						handlePrimaryAction()
					}
					.buttonStyle(.borderedProminent)
					.disabled(isPrimaryButtonDisabled)
					.keyboardShortcut(.defaultAction)
				}
				.padding(.bottom, 20)
			}
			.padding(.horizontal, 20)
		}
		.onAppear {
			// Focus on project name field when inspector appears for new projects
			if case .create = mode {
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
					isProjectNameFocused = true
				}
			}
		}
	}
	
	/// Tracks whether any changes have been made to the form
	private var hasChanges: Bool {
		projectName != originalProjectName ||
		repositoryURL != originalRepositoryURL ||
		localFolderPath != originalLocalFolderPath
	}

	/// Dynamic button text based on changes and mode
	private var dynamicPrimaryButtonTitle: String {
		switch mode {
		case .create:
			return "Create Project"
		case .configure:
			return hasChanges ? "Save Changes" : "No Changes"
		}
	}

	private var isPrimaryButtonDisabled: Bool {
		switch mode {
		case .create:
			return projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
		case .configure:
			return !hasChanges
		}
	}
	
	private func handlePrimaryAction() {
		let repoURL = repositoryURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : repositoryURL.trimmingCharacters(in: .whitespacesAndNewlines)
		let folderPath = localFolderPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : localFolderPath.trimmingCharacters(in: .whitespacesAndNewlines)
		
		// Create security-scoped bookmark if folder is selected
		var bookmark: Data?
		if let folderPath = folderPath {
			// For configuration mode, only create bookmark if path changed
			let shouldCreateBookmark: Bool
			switch mode {
			case .create:
				shouldCreateBookmark = true
			case .configure(let project):
				shouldCreateBookmark = folderPath != project.localFolderPath
			}
			
			if shouldCreateBookmark {
				let url = URL(fileURLWithPath: folderPath)
				do {
					bookmark = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
					// Validate bookmark size to prevent data store issues
					if let bookmarkData = bookmark, bookmarkData.count > 1024 * 1024 { // 1MB limit
						print("WARNING: Created bookmark is too large (\(bookmarkData.count) bytes). This may cause data store issues.")
					}
				} catch {
					print("Failed to create bookmark for \(folderPath): \(error.localizedDescription)")
					// Don't fail the entire operation if bookmark creation fails
					bookmark = nil
				}
			}
		}
		
		onComplete(projectName.trimmingCharacters(in: .whitespacesAndNewlines), repoURL, folderPath, bookmark)
		onDismiss()
	}
	
	private func selectLocalFolder() {
		let panel = NSOpenPanel()
		panel.allowsMultipleSelection = false
		panel.canChooseDirectories = true
		panel.canChooseFiles = false
		panel.canCreateDirectories = true
		panel.prompt = "Choose"
		panel.message = "Select a folder to store project files and repository clones."
		panel.title = "Choose Project Folder"
		
		if panel.runModal() == .OK {
			if let selectedURL = panel.url {
				localFolderPath = selectedURL.path
			}
		}
	}
}

/// Detail view for a selected project
struct ProjectDetailView: View {
	let project: Project
	let onConfigureProject: (Project) -> Void
	let onShowBlogGoal: (Project) -> Void
	let inspectorState: InspectorState
	@State private var gitService = GitService()
	@State private var showingCloneError = false
	@State private var cloneErrorMessage = ""
	
	var body: some View {
		ScrollView {
			VStack(spacing: 24) {
				projectHeaderView

				repositoryConfigurationCard

				horizontalCardScrollView

				ContentUnavailableView(
					"Additional Features Coming Soon",
					systemImage: "wand.and.stars",
					description: Text("Project configuration and content generation features will be added here.")
				)
				.padding(.top, 40)
			}
			.padding()
		}
		.navigationTitle(project.name)
		.toolbar {
			ToolbarItem(placement: .primaryAction) {
				Button(action: { onConfigureProject(project) }) {
					Label("Configure", systemImage: "gear")
				}
				.help(inspectorState.canShowConfiguration ? "Configure project settings" : "Cannot configure while workflow is active")
				.disabled(!inspectorState.canShowConfiguration)
			}
		}
		.alert("Clone Error", isPresented: $showingCloneError) {
			Button("OK", role: .cancel) { }
		} message: {
			Text(cloneErrorMessage)
		}
	}
	
	// MARK: - Computed Properties
	
	private var cloneStatusIcon: String {
		switch project.cloneStatus {
			case .notStarted:
				return "arrow.down.circle"
			case .cloning:
				return "arrow.down.circle"
			case .completed:
				return "checkmark.circle.fill"
			case .failed:
				return "exclamationmark.circle.fill"
		}
	}
	
	private var cloneStatusColor: Color {
		switch project.cloneStatus {
			case .notStarted:
				return .blue
			case .cloning:
				return .blue
			case .completed:
				return .green
			case .failed:
				return .red
		}
	}
	
	private var cloneStatusText: String {
		switch project.cloneStatus {
			case .notStarted:
				return "Ready to clone"
			case .cloning:
				return "Cloning repository..."
			case .completed:
				return "Repository cloned"
			case .failed:
				return "Clone failed"
		}
	}
	
	private var cloneButtonText: String {
		switch project.cloneStatus {
			case .notStarted:
				return "Clone"
			case .cloning:
				return "Cloning..."
			case .completed:
				return "Re-clone"
			case .failed:
				return "Retry"
		}
	}
	
	// MARK: - Actions
	
	private func cloneRepository() {
		guard let repositoryURL = project.repositoryURL,
				let localFolderPath = project.localFolderPath else {
			return
		}
		
		Task {
			// Update status to cloning
			project.updateCloneStatus(.cloning)
			
			// Perform the clone operation (pass the base localFolderPath, not repositoryLocalPath)
			let result = await gitService.cloneRepository(from: repositoryURL, to: localFolderPath, project: project)
			
			switch result {
				case .success:
					project.updateCloneStatus(.completed)
				case .failure(let error):
					project.updateCloneStatus(.failed, errorMessage: error.localizedDescription)
					cloneErrorMessage = error.localizedDescription
					showingCloneError = true
			}
		}
	}
	
	private var projectHeaderView: some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack(spacing: 12) {
				Image(systemName: "folder.badge.plus")
					.font(.title2)
					.foregroundStyle(.blue)
				
				VStack(alignment: .leading, spacing: 4) {
					Text(project.name)
						.font(.title2)
						.fontWeight(.semibold)
					
					HStack(spacing: 16) {
						Label(project.createdDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
							.font(.caption)
							.foregroundStyle(.secondary)
						
						if project.createdDate != project.modifiedDate {
							Label("Modified", systemImage: "pencil")
								.font(.caption)
								.foregroundStyle(.secondary)
						}
					}
				}
				
				Spacer()
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 12)
		}
		.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
	}
	
	private var horizontalCardScrollView: some View {
		VStack(alignment: .leading, spacing: 12) {
			Text("Select Goal To Achieve")
				.font(.headline)
				.foregroundStyle(.primary)
				.padding(.horizontal, 16)

			ScrollView(.horizontal, showsIndicators: false) {
				HStack(spacing: 16) {
					ForEach(ActivityType.allCases, id: \.self) { activity in
						CardView(
							title: activity.rawValue,
							subtitle: activity.subtitle,
							systemImage: activity.systemImage,
							color: activity.color,
							action: {
								if activity == .blogPost {
									onShowBlogGoal(project)
								} else {
									inspectorState.show(InspectorType.activity(activity, project))
								}
							},
							isDisabled: !inspectorState.canShowWorkflow
						)
					}
				}
				.padding(.horizontal, 16)
			}
		}
	}
	
	private var repositoryConfigurationCard: some View {
		GroupBox {
			VStack(alignment: .leading, spacing: 16) {
				Label("Repository Configuration", systemImage: "server.rack")
					.font(.headline)
					.foregroundStyle(.primary)
				
				VStack(alignment: .leading, spacing: 12) {
					HStack(alignment: .top) {
						Image(systemName: "link")
							.foregroundStyle(.blue)
							.frame(width: 16)
						
						VStack(alignment: .leading, spacing: 4) {
							Text("GitHub Repository")
								.font(.subheadline)
								.fontWeight(.medium)
							
							if let repositoryURL = project.repositoryURL, !repositoryURL.isEmpty {
								Text(repositoryURL)
									.font(.body)
									.foregroundStyle(.primary)
									.textSelection(.enabled)
									.lineLimit(3)
							} else {
								Text("Not configured")
									.font(.body)
									.foregroundStyle(.secondary)
									.italic()
							}
						}
						
						Spacer()
					}
					
					Divider()
					
					HStack(alignment: .top) {
						Image(systemName: "folder")
							.foregroundStyle(.orange)
							.frame(width: 16)
						
						VStack(alignment: .leading, spacing: 4) {
							Text("Local Folder")
								.font(.subheadline)
								.fontWeight(.medium)
							
							if let localFolderPath = project.localFolderPath, !localFolderPath.isEmpty {
								Text(localFolderPath)
									.font(.body)
									.foregroundStyle(.primary)
									.textSelection(.enabled)
									.lineLimit(3)
							} else {
								Text("Not configured")
									.font(.body)
									.foregroundStyle(.secondary)
									.italic()
							}
						}
						
						Spacer()
					}
					
					// Clone status and action section
					if project.repositoryURL != nil && project.localFolderPath != nil {
						Divider()
						
						VStack(alignment: .leading, spacing: 12) {
							HStack {
								Image(systemName: cloneStatusIcon)
									.foregroundStyle(cloneStatusColor)
									.frame(width: 16)
								
								VStack(alignment: .leading, spacing: 4) {
									Text("Repository Status")
										.font(.subheadline)
										.fontWeight(.medium)
									
									Text(cloneStatusText)
										.font(.body)
										.foregroundStyle(cloneStatusColor)
									
									if let errorMessage = project.cloneErrorMessage {
										Text(errorMessage)
											.font(.caption)
											.foregroundStyle(.red)
											.lineLimit(2)
									}
									
									if let lastClonedDate = project.lastClonedDate {
										Text("Last cloned: \(lastClonedDate.formatted(date: .abbreviated, time: .shortened))")
											.font(.caption)
											.foregroundStyle(.secondary)
									}
								}
								
								Spacer()
								
								Button(action: cloneRepository) {
									HStack(spacing: 6) {
										if project.cloneStatus == .cloning {
											ProgressView()
												.controlSize(.small)
										} else {
											Image(systemName: "arrow.down.circle")
										}
										Text(cloneButtonText)
									}
								}
								.disabled(!project.canClone)
								.controlSize(.small)
							}
						}
					}
				}
			}
		}
	}
}

/// Card view for horizontal scrollable content
struct CardView: View {
	let title: String
	let subtitle: String
	let systemImage: String
	let color: Color
	let action: () -> Void
	let isDisabled: Bool

	init(title: String, subtitle: String, systemImage: String, color: Color, action: @escaping () -> Void, isDisabled: Bool = false) {
		self.title = title
		self.subtitle = subtitle
		self.systemImage = systemImage
		self.color = color
		self.action = action
		self.isDisabled = isDisabled
	}

	var body: some View {
		Button(action: action) {
			VStack(alignment: .leading, spacing: 12) {
				HStack {
					Image(systemName: systemImage)
						.font(.title2)
						.foregroundStyle(color)
						.opacity(isDisabled ? 0.4 : 1.0)

					Spacer()

					Image(systemName: "chevron.right")
						.font(.caption)
						.foregroundStyle(.secondary)
						.opacity(isDisabled ? 0.4 : 1.0)
				}

				VStack(alignment: .leading, spacing: 4) {
					Text(title)
						.font(.headline)
						.foregroundStyle(.primary)
						.opacity(isDisabled ? 0.4 : 1.0)

					Text(subtitle)
						.font(.caption)
						.foregroundStyle(.secondary)
						.opacity(isDisabled ? 0.4 : 1.0)
						.lineLimit(2)
				}
			}
			.padding(16)
			.frame(width: 160, height: 120)
			.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
			.overlay(
				RoundedRectangle(cornerRadius: 12)
					.stroke(Color.primary, lineWidth: 1)
					.opacity(isDisabled ? 0.05 : 0.1)
			)
		}
		.buttonStyle(.plain)
		.disabled(isDisabled)
	}
}


/// Inspector view for activity details and actions
struct ActivityInspector: View {
	let activity: ActivityType
	let project: Project
	@Environment(\.dismiss) private var dismiss
	@State private var isGenerating = false
	@State private var generationProgress = 0.0
	@State private var generationTimer: Timer?
	
	var body: some View {
		VStack(spacing: 0) {
			// Header
			VStack(spacing: 8) {
				HStack {
					Image(systemName: activity.systemImage)
						.font(.title2)
						.foregroundStyle(activity.color)
					
					VStack(alignment: .leading, spacing: 4) {
						Text(activity.rawValue)
							.font(.title3)
							.fontWeight(.semibold)
						
						Text(activity.subtitle)
							.font(.caption)
							.foregroundStyle(.secondary)
					}
					
					Spacer()
				}
			}
			.padding(.top, 16)
			.padding(.horizontal, 16)
			.padding(.bottom, 12)
			
			// Content area
			ScrollView {
				VStack(alignment: .leading, spacing: 16) {
					// Project context
					GroupBox {
						VStack(alignment: .leading, spacing: 8) {
							Label("Project Context", systemImage: "folder.badge.plus")
								.font(.subheadline)
								.fontWeight(.medium)
								.foregroundStyle(.primary)

							Text("Using content from: \(project.name)")
								.font(.caption)
								.foregroundStyle(.secondary)

							if let repoURL = project.repositoryURL {
								Text("Repository: \(repoURL)")
									.font(.caption2)
									.foregroundStyle(.tertiary)
									.lineLimit(1)
							}
						}
					}

					// Generation status
					if isGenerating {
						GroupBox {
							VStack(alignment: .leading, spacing: 12) {
								Label("Generating Content", systemImage: "gear")
									.font(.subheadline)
									.fontWeight(.medium)
									.foregroundStyle(.blue)

								ProgressView(value: generationProgress)
									.progressViewStyle(.linear)

								Text("Analyzing repository content and generating \(activity.rawValue.lowercased())...")
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						}
					}

					// Options and settings
					GroupBox {
						VStack(alignment: .leading, spacing: 12) {
							Label("Generation Options", systemImage: "slider.horizontal.3")
								.font(.subheadline)
								.fontWeight(.medium)

							VStack(alignment: .leading, spacing: 8) {
								Toggle("Include code examples", isOn: .constant(true))
									.font(.caption)

								Toggle("Add technical diagrams", isOn: .constant(false))
									.font(.caption)

								Toggle("Generate multiple variants", isOn: .constant(true))
									.font(.caption)
							}
						}
					}
				}
				.padding(.horizontal, 16)
			}
			
			// Action buttons
			VStack(spacing: 8) {
				Button(action: {
					startGeneration()
				}) {
					HStack {
						if isGenerating {
							ProgressView()
								.controlSize(.small)
						} else {
							Image(systemName: "sparkles")
						}
						Text(isGenerating ? "Generating..." : "Generate \(activity.rawValue)")
					}
				}
				.buttonStyle(.borderedProminent)
				.disabled(isGenerating || project.cloneStatus != .completed)
				.frame(maxWidth: .infinity)

				Button("Close") {
					dismiss()
				}
				.buttonStyle(.bordered)
				.frame(maxWidth: .infinity)
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 12)
		}
	}
}

// MARK: - Unified Inspector

/// Single inspector that switches content based on state
struct UnifiedInspector: View {
	@Environment(InspectorState.self) var inspectorState
	var onCreateProject: ((String, String?, String?, Data?) -> Void)?

	init(onCreateProject: ((String, String?, String?, Data?) -> Void)? = nil) {
		self.onCreateProject = onCreateProject
	}

	var body: some View {
		switch inspectorState.currentType {
		case .newProject:
			ProjectSetupInspector(
				mode: .create,
				onComplete: { projectName, repositoryURL, localFolderPath, bookmark in
					onCreateProject?(projectName, repositoryURL, localFolderPath, bookmark)
					inspectorState.hide()
				},
				onDismiss: {
					inspectorState.hide()
				}
			)

		case .configureProject(let project):
			ProjectSetupInspector(
				mode: .configure(project),
				onComplete: { projectName, repositoryURL, localFolderPath, bookmark in
					// Update project name if it changed
					project.name = projectName
					// Update repository settings
					project.updateRepositorySettings(repositoryURL: repositoryURL, localFolderPath: localFolderPath, localFolderBookmark: bookmark)
					inspectorState.hide()
				},
				onDismiss: {
					inspectorState.hide()
				}
			)

		case .blogGoal(let project):
			BlogGoalInspector(
				project: project,
				onCleanupAndDismiss: {
					inspectorState.hide()
				}
			)

		case .activity(let activity, let project):
			ActivityInspector(activity: activity, project: project)

		case nil:
			Text("Select an action")
				.foregroundStyle(.secondary)
		}
	}
}

extension ActivityInspector {
	private func startGeneration() {
		isGenerating = true
		generationProgress = 0.0
		
		// Simulate generation process
		generationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
			Task { @MainActor in
				generationProgress += 0.02
				if generationProgress >= 1.0 {
					generationTimer?.invalidate()
					generationTimer = nil
					isGenerating = false
					generationProgress = 0.0
				}
			}
		}
	}
}

#Preview {
	ContentView()
		.modelContainer(for: Project.self, inMemory: true)
}

