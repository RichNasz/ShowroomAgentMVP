# ShowroomAgentMVP

AI-powered content generation platform that transforms technical documentation into engaging marketing content.

## Project Introduction

ShowroomAgentMVP is a native macOS application designed to bridge the gap between technical documentation and compelling marketing content. Built for documentation teams, developer relations professionals, and technical writers, this tool leverages AI-powered Large Language Models to automatically transform structured Antora documentation from GitHub repositories into professional blog posts, social media content, and email campaigns. The application provides a complete workflow from repository integration through content generation, featuring a guided process that validates source content, configures AI services, and produces publication-ready marketing materials while maintaining technical accuracy and brand consistency.

## Important Associated Content

This documentation provides comprehensive guidance for using and developing ShowroomAgentMVP. The content is organized into the following categories:

### Getting Started
- <doc:ShowroomAgentMVP-Getting-Started> - Integration guide and basic usage patterns for new users

### Technical Reference  
- <doc:ShowroomAgentMVP-Architecture-Overview> - Technical architecture, design patterns, and system components

### Development & Contribution
- <doc:ShowroomAgentMVP-Project-Specifications> - Comprehensive project specifications and development methodology

Browse all articles to find detailed information about installation, configuration, usage patterns, and contribution guidelines.

## Overview

ShowroomAgentMVP is a native macOS application that bridges the gap between technical documentation and marketing content. Using structured Antora documentation and AI-powered Large Language Models, it automatically generates professional blog posts, social media content, and email campaigns from existing technical assets.

### Core Capabilities

The platform provides comprehensive content generation capabilities:

- **Project Management**: Create and organize content generation projects with persistent configuration
- **Repository Integration**: Connect to GitHub repositories containing Antora-structured documentation  
- **Content Validation**: Verify ShowroomParser compatibility and repository structure
- **AI-Powered Generation**: Transform technical content using configurable LLM services
- **Multi-Format Output**: Generate content optimized for blogs, social media, and email campaigns
- **Secure Access**: Handle macOS security permissions and folder access seamlessly

### Target Use Cases

ShowroomAgentMVP serves multiple professional scenarios:

- **Technical Documentation Teams**: Converting API documentation and tutorials into marketing content
- **Developer Relations**: Creating engaging blog content from product documentation
- **Technical Writers**: Transforming technical content into accessible storytelling
- **Product Teams**: Generating social media content about technical features and releases

### Key Benefits

- **Automated Workflow**: Eliminates manual effort in content transformation
- **Technical Accuracy**: Preserves factual correctness while improving readability
- **Brand Consistency**: Maintains consistent voice and style across all generated content
- **Time Efficiency**: Reduces content creation time from hours to minutes
- **Zero Infrastructure**: Self-contained application with no server dependencies

## Architecture

ShowroomAgentMVP follows a modern Swift architecture using SwiftUI for the interface and SwiftData for persistence:

### Core Components

- **Project Model**: SwiftData entity managing project configuration and state
- **Content Processing**: ShowroomParser integration for documentation parsing
- **LLM Integration**: SwiftChatCompletionsDSL for AI content generation
- **Security Management**: macOS security-scoped bookmarks for file system access

### Data Flow

```
User Input → Project Creation → Repository Configuration → 
Security Access → Repository Download → Content Validation → 
LLM Configuration → Content Generation → Output Processing
```

### Platform Integration

The application leverages native macOS capabilities:

- **Security Framework**: Security-scoped bookmarks for sandboxed file access
- **AppKit Integration**: Native folder selection dialogs
- **SwiftUI Interface**: Modern declarative user interface
- **SwiftData Persistence**: Efficient local data storage

## Getting Started

### Prerequisites

- macOS 15.0 or later
- Internet connection for repository access and LLM services
- GitHub repositories with Antora-structured documentation

### Quick Start

1. **Launch** the application and create a new project
2. **Configure** your GitHub repository URL
3. **Select** a local folder for content storage
4. **Validate** your repository structure
5. **Set up** your preferred LLM service
6. **Generate** content using the guided workflow

### Example Usage

```swift
// Create and configure a project
let project = Project(name: "API Documentation Blog")
project.repositoryURL = "https://github.com/company/api-docs"
project.localFolderPath = "/Users/username/Projects"

// Validate and generate content
let validation = try await project.validateRepository()
if validation.isSuccess {
    let content = try await project.generateBlogContent()
}
```

## Advanced Features

### Custom Prompt Configuration

Customize content generation with tailored prompts:

- **Template Library**: Pre-built prompts for different content types
- **Custom Editing**: Rich text editor for prompt refinement
- **Project-Specific**: Store unique prompts per project
- **Version Control**: Track prompt changes and revert when needed

### Multi-Activity Support

Generate content for various marketing channels:

- **Blog Posts**: Long-form technical articles with engaging narratives
- **Social Media**: Platform-optimized posts for Twitter, LinkedIn, and others
- **Email Campaigns**: Newsletter content and product announcements
- **Documentation**: Enhanced user guides and tutorials

### LLM Flexibility

Support for multiple AI service providers:

- **OpenAI**: GPT models via official API
- **Local Models**: Ollama and other local inference engines
- **Custom Endpoints**: Any OpenAI-compatible API service
- **Cost Optimization**: Choose appropriate models for different content types

## Performance

ShowroomAgentMVP is optimized for efficient content processing:

- **Memory Management**: Lazy loading and efficient caching for large repositories
- **Network Optimization**: HTTP-based downloading with resume capabilities
- **Concurrent Processing**: Background operations with responsive UI
- **Resource Efficiency**: Minimal system resource usage

### Scalability

The application handles various repository sizes:

- **Small Repositories**: < 10MB processed in-memory for speed
- **Medium Repositories**: 10-100MB using chunked processing
- **Large Repositories**: 100MB+ with streaming and disk-based operations

## Integration

### Workflow Integration

ShowroomAgentMVP integrates with existing development workflows:

- **CI/CD Pipelines**: Automated content generation on documentation updates
- **Content Management**: Export to popular CMS platforms
- **Social Media**: Direct integration with posting APIs
- **Analytics**: Content performance tracking and optimization

### API Extensibility

The application provides extension points for customization:

- **Custom LLM Providers**: Plugin architecture for additional AI services
- **Content Formats**: Extensible output format support
- **Workflow Hooks**: API endpoints for external system integration
- **Template System**: Custom content generation templates

## Security

Security is a fundamental aspect of ShowroomAgentMVP:

### File System Security

- **Sandboxing**: Compatible with App Store sandbox requirements
- **Scoped Access**: Security-scoped bookmarks for folder permissions
- **Permission Management**: Clear user consent for file system access
- **Data Isolation**: Project data stored securely with proper access controls

### Network Security

- **HTTPS Only**: All network communications use secure protocols
- **API Key Protection**: Secure storage of LLM service credentials
- **Repository Access**: Safe handling of public and private repositories
- **Privacy**: No data transmitted beyond necessary API calls

## Troubleshooting

Common issues and solutions:

### Repository Issues

- **Invalid Structure**: Ensure Antora configuration files are present
- **Access Permissions**: Verify repository accessibility and credentials
- **Content Format**: Check for supported AsciiDoc and Markdown files

### LLM Configuration

- **Connection Failures**: Validate endpoint URLs and API keys
- **Model Availability**: Ensure selected models are accessible
- **Rate Limiting**: Handle API quotas and request throttling

### File System

- **Permission Errors**: Re-select folders to refresh security bookmarks
- **Disk Space**: Ensure sufficient storage for repository clones
- **Path Issues**: Use absolute paths for reliable access

## Contributing

ShowroomAgentMVP welcomes contributions from the community:

### Development Setup

1. **Clone** the repository from GitHub
2. **Install** dependencies using Swift Package Manager
3. **Build** the project using Xcode 15.0+
4. **Run** tests using Swift Testing framework

### Contribution Guidelines

- **Code Style**: Follow Swift API Design Guidelines
- **Documentation**: Add DocC comments for all public APIs
- **Testing**: Include comprehensive test coverage
- **Review Process**: Submit pull requests for community review

### Community

- **GitHub Issues**: Bug reports and feature requests
- **Discussions**: Community support and questions
- **Documentation**: Improvements and translations welcome

---

For detailed implementation guidance, see the comprehensive specifications in the project repository's `Specs/` folder.