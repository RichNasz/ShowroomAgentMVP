# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ShowroomAgentMVP is a macOS Swift application that generates text for blogs and social media posts, based on technical content stored within GitHub repositories that contain documentation structured for Antora site generation.

The application follows a project-based workflow where users:
1. Create projects with descriptive names
2. Configure GitHub repository URLs for documentation sources
3. Set local folder paths for storing cloned repositories and generated content
4. Generate blog and social media content from the technical documentation

## Architecture

### Data Model
- **Project**: Core SwiftData model representing a content generation project
  - `name`: Project identifier
  - `repositoryURL`: Optional GitHub repository URL for documentation source
  - `localFolderPath`: Optional local storage path for files
  - `createdDate` / `modifiedDate`: Timestamps for project lifecycle

### User Interface
- **NavigationSplitView**: Main interface with sidebar and detail views
- **Project Creation Flow**: Modal sheet for creating new projects with configuration
- **Project Configuration**: Editable repository and folder settings
- **Apple HIG Compliance**: All interfaces follow Apple Human Interface Guidelines

### Key Components
- `ContentView`: Main NavigationSplitView interface
- `ProjectRowView`: Sidebar project list items with status indicators
- `NewProjectSheet`: Project creation modal with repository configuration
- `ProjectDetailView`: Detail view showing project info and configuration status
- `ProjectConfigurationSheet`: Settings editor for repository and folder configuration

## Development Commands

### Building and Testing
- **Build**: `swift build`
- **Test**: `swift test` 
- **Clean**: `swift package clean`

### Package Management
- **Resolve dependencies**: `swift package resolve`
- **Update dependencies**: `swift package update`

## Key Requirements

- **Swift Version**: Requires Swift 6.1+ (enforced in Package.swift)
- **Testing Framework**: Uses Swift Testing (not XCTest)
- **Concurrency**: Designed for modern Swift async/await patterns
- **UI Framework**: SwiftUI with SwiftData for persistence
- **Platform**: macOS only (uses AppKit for folder selection dialogs)
- **Design**: Follows Apple Human Interface Guidelines
- **Important**: Cannot use UIKit - macOS only, use AppKit when platform-specific code is needed
- **Observation**: Always use @Observable macro instead of ObservableObject protocol
- **Sandboxing**: App can run with or without App Sandbox. If sandboxed, git operations use HTTP download instead of command-line git
- **Distribution**: Currently configured for unsigned distribution (internal use) - no code signing or notarization required

## Distribution Configuration

- **Build Type**: Unsigned (internal company distribution)
- **Code Signing**: Disabled (CODE_SIGN_IDENTITY = "", CODE_SIGN_STYLE = Manual)
- **Hardened Runtime**: Disabled (compatible with unsigned builds)
- **App Sandbox**: Disabled (for broader file system access)
- **Target Platform**: macOS 15.5+
- **Build Script**: `./build_for_distribution.sh` creates unsigned ZIP for team distribution
