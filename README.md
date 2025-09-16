# ShowroomAgentMVP

**AI-Powered Content Generation from Technical Documentation**

![Swift](https://img.shields.io/badge/Swift-6.1+-orange.svg)
![macOS](https://img.shields.io/badge/macOS-15.0+-blue.svg)

## Overview

ShowroomAgentMVP is a native macOS application that transforms technical documentation stored in GitHub repositories into engaging blog posts and social media content. Using structured Antora/ShowroomParser documentation and AI-powered Large Language Models (LLMs), the system automatically generates professional content for technical communications.

The application bridges the gap between technical documentation and marketing content, enabling documentation teams, developer relations professionals, and technical writers to efficiently create compelling content from existing technical assets while maintaining accuracy and consistency.

### Key Benefits

- **Automated Content Creation**: Eliminates manual effort in converting technical docs to marketing content
- **Consistency**: Maintains brand voice and technical accuracy across all generated content  
- **Time Efficiency**: Reduces content creation time from hours to minutes
- **Multi-Platform Output**: Generates content optimized for blogs, social media, and email campaigns
- **Zero Infrastructure**: Self-contained macOS application with no server dependencies

## Quick Start

1. **Create a Project**: Launch the app and create a new project with a descriptive name
2. **Configure Repository**: Add your GitHub repository URL containing Antora-structured documentation
3. **Set Local Storage**: Choose a local folder for storing cloned repositories and generated content
4. **Validate Content**: The app automatically validates your repository structure for compatibility
5. **Configure AI Service**: Set up your preferred LLM provider (OpenAI, local Ollama, or custom endpoint)
6. **Generate Content**: Use the guided workflow to transform your documentation into engaging content

### Example Workflow

```
Project Creation → Repository Clone → Content Validation → 
LLM Configuration → Prompt Customization → Content Generation → Review & Export
```

## Documentation Links

### DocC Articles

Access comprehensive documentation through Xcode's Developer Documentation:

1. **Product** → **Build Documentation** in Xcode
2. Navigate to **ShowroomAgentMVP** in the documentation browser
3. Browse articles organized by category

**Available Articles:**
- **[Getting Started](ShowroomAgentMVP/ShowroomAgentMVP.docc/Articles/ShowroomAgentMVP-Getting-Started.md)**: Integration and basic usage guide
- **[Architecture Overview](ShowroomAgentMVP/ShowroomAgentMVP.docc/Articles/ShowroomAgentMVP-Architecture-Overview.md)**: Technical architecture and design patterns  
- **[Project Specifications](ShowroomAgentMVP/ShowroomAgentMVP.docc/Articles/ShowroomAgentMVP-Project-Specifications.md)**: Comprehensive project specifications and development methodology

### Alternative Access

You can also browse the raw DocC articles directly in the repository structure under `ShowroomAgentMVP/ShowroomAgentMVP.docc/Articles/`.

## Requirements

### System Requirements
- **macOS**: 15.0 or later
- **Swift**: 6.1+ (for building from source)
- **Xcode**: 15.0+ (for development)

### Dependencies
- **Yams**: YAML parsing for Antora configuration
- **ShowroomParser**: Documentation parsing and content extraction
- **SwiftChatCompletionsDSL**: LLM integration with OpenAI-compatible APIs

## API Reference

### Core Components

- **`Project`**: SwiftData model representing content generation projects
- **`ContentView`**: Main NavigationSplitView interface with project management
- **`GitService`**: Repository operations and content validation
- **`ShowroomUtilities`**: Utility functions for content processing

### Search Functionality

Use Xcode's documentation browser search to find specific API symbols:
- Open **Developer Documentation** in Xcode
- Search for **ShowroomAgentMVP** symbols
- Filter by **Classes**, **Structs**, **Protocols**, or **Functions**

### Code Examples

```swift
// Create a new project
let project = Project(name: "My Documentation Project")

// Configure repository and local storage
project.repositoryURL = "https://github.com/user/docs-repo"
project.localFolderPath = "/Users/username/ShowroomProjects"

// Validate repository content
let validation = try await project.validateRepository()
if validation.isSuccess {
    // Proceed with content generation
    let content = try await project.generateContent()
}
```

## Repository and Contribution

### Source Code
- **Repository**: [https://github.com/RichNasz/ShowroomAgentMVP.git](https://github.com/RichNasz/ShowroomAgentMVP.git)
- **License**: Apache License 2.0 - see [LICENSE](LICENSE) file for details
- **Platform**: macOS native application using SwiftUI and SwiftData

### Issues and Feature Requests
- **Bug Reports**: Use GitHub Issues for bug reports with detailed reproduction steps
- **Feature Requests**: Submit enhancement requests through GitHub Issues
- **Discussions**: Use GitHub Discussions for questions and community support

### Contributing
We welcome contributions to ShowroomAgentMVP! Please see our contribution guidelines:

1. **Fork** the repository and create a feature branch
2. **Follow** Swift coding conventions and add appropriate tests
3. **Document** new functionality with DocC comments
4. **Submit** a pull request with clear description of changes

### Specifications
Comprehensive project specifications are available in the `Specs/` folder:

- **[ShowroomAgentMVPSpec.md](Specs/ShowroomAgentMVPSpec.md)**: Functional specification and capabilities
- **[CodeGenerationSpec.md](Specs/CodeGenerationSpec.md)**: Language-agnostic implementation guidance  
- **[SwiftCodeGeneration.md](Specs/SwiftCodeGeneration.md)**: Swift-specific implementation details
- **[DocumentationSpec.md](Specs/DocumentationSpec.md)**: Documentation standards and requirements

These specifications enable independent implementation and provide detailed guidance for developers and AI code generation tools.

---

**ShowroomAgentMVP** - Transforming technical documentation into compelling content with the power of AI.