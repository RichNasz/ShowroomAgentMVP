# ShowroomAgentMVP Documentation Specification

## Overview
This document specifies the comprehensive documentation requirements for the ShowroomAgentMVP Swift application.

## Requirements
- **Documentation**: Include a README.md with an overview of the project, a description of user interface floe, and a description of the architecture. Use DocC for comprehensive documentation, with a `.docc` folder containing articles.


## Exclusions
- **DO NOT include GitHub Actions workflows or CI/CD automation**
- **DO NOT include build status badges or automated testing references**
- **DO NOT include continuous integration or continuous deployment content**
- **DO NOT include automated deployment or pipeline automation**
- **DO NOT include links to hosted DocC documentation unless actually hosted and verified**
- **DO NOT use incorrect file paths or non-prefixed article names when linking to DocC content**

## README.md Structure
The root README.md file is must include the following sections in order:

1. **Package Title and Badge Section**
   - Project name and brief tagline
   - Swift version badge: `![Swift](https://img.shields.io/badge/Swift-6.1+-orange.svg)`
   - Platform badges:
     - `![macOS](https://img.shields.io/badge/macOS-15.0+-blue.svg)`

2. **Overview Section**
   - Clear description of what the application does
   - Key benefits and use cases

3. **Quick Start Section**
   - Basic example of how to use the user interface
   
4. **Documentation Links Section**
   - **DocC Articles**: Use relative paths to actual DocC article files in `[TargetName]/[TargetName].docc/Articles/`
   - **Correct Naming**: All article links must use the prefixed naming convention (e.g., `ShowroomAgentMVP-Getting-Started.md`)
   - **No Hosted Links**: DO NOT include links to hosted DocC documentation (e.g., GitHub Pages) unless actually hosted
   - **Xcode Instructions**: Include clear instructions for accessing rendered DocC documentation through Xcode Developer Documentation
   - **Alternative Access**: Provide note about browsing raw DocC articles in the repository structure

5. **Requirements Section**
   - Swift version requirements (6.1+)
   - Platform support:
     - macOS 15.0+
   - Dependencies (if any)

6. **API Reference Section**
   - Link to complete API documentation
   - Search functionality for API symbols
   - Code examples for each major API component

7. **Repository and Contribution Section**
   - **Source Code**: Link to project repository (https://github.com/RichNasz/ShowroomAgentMVP.git)
   - **Issues**: GitHub Issues for bug reports and feature requests
   - **Contributing**: Guidelines for contributing to the project
   - **Specifications**: Link to comprehensive project specifications in Specs/ folder


## Documentation Strategy & Planning

### Content Strategy
- **Target Audience Analysis**: Identify and prioritize different user personas:
  - **Technical Documentation Teams**: Converting API documentation, tutorials, and guides into marketing content
  - **Developer Relations**: Creating blog content from existing technical repositories  
  - **Technical Writers**: Transforming dry documentation into engaging storytelling
  - **Product Teams**: Generating social media content about technical features
- **Content Maturity Model**: Define documentation progression paths
- **Success Metrics**: Establish KPIs for documentation effectiveness including parsing accuracy and conversion speed

### Documentation Planning Process
1. **Content Inventory**: Audit existing documentation and identify gaps
2. **User Research**: Gather feedback from target audiences
3. **Content Roadmap**: Plan documentation releases aligned with code releases
4. **Quality Gates**: Establish review processes for documentation changes
5. **Maintenance Schedule**: Regular content updates and reviews

## DocC Documentation
Documentation must be generated using DocC, Apple's documentation compiler for Swift. All public APIs in source files must include triple-slash (///) comments structured with Markdown sections (e.g., Summary, Discussion, Parameters, Returns, Throws) as per Apple standards.

**CRITICAL REQUIREMENT**: The documentation must include a comprehensive example guide that makes usage accessible to developers at all experience levels. The documentation is essential for package adoption and significantly lowers the barrier to entry for new users.

### DocC Best Practices
- **Progressive Disclosure**: Present information from simple to complex
- **Cross-Platform Consistency**: Ensure documentation works across all supported platforms
- **Version Awareness**: Clearly indicate feature availability by platform/version
- **Interactive Elements**: Leverage DocC's capabilities for enhanced user experience
- **Important Associated Content Section**: Main documentation files must include a comprehensive reference section that:
  - Lists all available DocC articles with descriptive summaries
  - Groups articles by category (Getting Started, Technical Reference, Development, Support)
  - Uses proper DocC cross-reference syntax (`<doc:ArticleName>`)
  - Appears immediately after the main title/description and before the Overview section
  - Provides clear navigation to all documentation resources

Create a DocC catalog in the target source directory: `ShowroomAgentMVP`. The catalog must be located within the target's source directory for Xcode's DocC plugin to properly associate documentation with the target and build it automatically. This folder contains markdown articles and resources. To build the DocC archive, run:
```bash
swift package generate-documentation --target ShowroomAgentMVP
```
This produces a `.doccarchive` file for hosting or viewing in Xcode/Preview.



### API Documentation Standards
All public APIs must include comprehensive triple-slash comments following this structure:

```swift
/// Brief summary of what the function/type does (max 120 characters).
///
/// Detailed discussion explaining the purpose, behavior, and any important
/// implementation details. This section can span multiple paragraphs and
/// should include context about when and why to use this API.
///
/// ## Overview
/// Provide additional context about the API's role in the larger system.
///
/// ## Usage Notes
/// Include important usage patterns, best practices, or common pitfalls.
///
/// - Parameters:
///   - parameterName: Description of what this parameter does, including:
///     - Valid ranges or values
///     - Default behavior if optional
///     - Performance implications
///   - anotherParam: Description with constraints or validation rules
/// - Returns: Description of what is returned, including:
///   - Type information and structure
///   - Possible values or ranges
///   - Performance characteristics
/// - Throws: List of specific errors that can be thrown with descriptions:
///   - `SpecificError.case`: Detailed explanation of when this error occurs
///   - Include recovery suggestions when applicable
/// - Note: Additional important information for developers
/// - Warning: Critical warnings about usage or potential issues
/// - Important: Information that developers must be aware of
/// - SeeAlso: References to related APIs or documentation
/// - Precondition: Requirements that must be met before calling
/// - Postcondition: Guarantees about the state after execution
///
/// ## Example Usage
/// ```swift
/// // Preferred usage pattern
/// let example = try SomeType(parameter: "value")
/// let result = try example.someMethod()
///
/// // Alternative approaches
/// if let alternative = try? example.alternativeMethod() {
///     print("Alternative result: \(alternative)")
/// }
/// ```
///
/// ## Performance Considerations
/// - Time complexity: O(n) for typical usage
/// - Space complexity: O(1) additional space required
/// - Thread safety: Safe to call from any thread
///
/// ## Migration Notes
/// - Since version 2.0: This method replaces the deprecated `oldMethod()`
/// - Breaking change in 3.0: Parameter `oldParam` renamed to `newParam`
public func someMethod(parameter: String) throws -> ResultType {
    // Implementation
}
```

### Documentation Metadata Standards
All public symbols must include appropriate metadata:

```swift
/// A configuration parameter for controlling randomness in responses.
///
/// Use this parameter to control the randomness of the model's responses.
/// Higher values (closer to 1.0) make output more random, while lower values
/// make it more focused and deterministic.
///
/// ## Example
/// ```swift
/// let config = Temperature(0.7)  // Balanced creativity and focus
/// ```
public struct Temperature: ResponseConfigParameter {
    /// The temperature value between 0.0 and 2.0
    public let value: Double

    /// Creates a new temperature configuration.
    ///
    /// - Parameter value: The temperature value (0.0-2.0)
    /// - Throws: `LLMError.invalidValue` if value is outside valid range
    public init(_ value: Double) throws
}
```

### Symbol Visibility Guidelines
- **Public**: Core APIs intended for external use
- **Internal**: Implementation details not meant for external consumption
- **Private**: Internal implementation, not visible in documentation
- **Package**: Available within the package but not to external consumers


**Critical DocC Naming Conventions**:
- **Main documentation file**: Must be named to match the product module name (e.g., `ShowroomParser.md` for ShowroomParser module)
- **DocC catalog directory**: Named after the target (e.g., `ShowroomParser.docc`)
- **Location**: DocC catalogs must be within the target's source directory for Xcode integration

### Resource Management Guidelines
The `Resources/` folder within the DocC catalog should organize assets as follows:
- **Images**: Use `.png` for screenshots, `.svg` for diagrams when possible
- **Code Examples**: Store longer code examples in separate files for reuse
- **Naming Convention**: Use kebab-case with descriptive names (e.g., `streaming-example-diagram.png`)
- **File Size**: Optimize images for web viewing (< 500KB recommended)
- **Documentation**: Include alt-text for all images for accessibility

**Critical File Naming Convention**:
- **Main documentation file** must be named to match the product module name (e.g., `ShowroomParser.md` for ShowroomParser module) for proper DocC integration
- **DocC catalog directory** is named after the target (e.g., `ShowroomParser.docc`)
- **Articles** use `.md` extension with standard Markdown format
- **Location requirement**: DocC catalogs must be within the target's source directory

**Lesson Learned**: The main documentation file should be named to match the product module name (e.g., `ShowroomParser.md`) rather than a generic name. This ensures proper DocC tool integration and follows Apple's established conventions for framework documentation landing pages.

**Required Documentation Articles by Package Type**:

**For ShowroomParser Package**:
- **ShowroomParser.md** (REQUIRED): Main target documentation with API overview (named to match the product module)
  - Must include "Important Associated Content" section before Overview section
- **Getting-Started.md** (REQUIRED): Integration and basic usage guide
- **Architecture-Overview.md** (REQUIRED): Technical architecture and design patterns
- **AsciiDoc-Support.md** (REQUIRED): Supported AsciiDoc elements and conversion capabilities
- **Usage-Examples.md** (REQUIRED): Practical examples of parsing showroom repositories


**Target Source Directory Location Benefits**:
- **Xcode Integration**: DocC plugin automatically discovers and builds documentation when located in target source directory
- **SPM Compatibility**: `swift package generate-documentation` works seamlessly with target-associated documentation
- **Target Association**: Documentation correctly associates with the target by being in its source directory
- **Build Automation**: Documentation builds automatically when building the target in Xcode
- **Source Proximity**: Documentation lives alongside the source code it documents, improving maintainability
- **Distribution Ready**: Generated `.doccarchive` is properly structured for hosting with correct target association

The documentation files should be generated with content that aligns with the package's purpose:


### Code Example Standards
All code examples in documentation must follow these standards:

- **Language Tags**: Always specify `swift` for Swift code blocks
- **Complete Examples**: Provide runnable code when possible, not fragments
- **Comments**: Include explanatory comments for complex operations
- **Error Handling**: Show proper error handling patterns
- **Imports**: Include necessary import statements
- **Formatting**: Use consistent indentation (4 spaces) and Swift naming conventions

Example format:
```swift
import ShowroomParser

// Parse a showroom repository
let repository = ShowroomParser.parseRepository(at: "/path/to/showroom")

// Access parsed content
if let repo = repository {
    print("Found \(repo.modules.count) modules")

    // Get concatenated navigation content
    if let content = repo.concatenatedNavigationContent() {
        print("Navigation content length: \(content.count)")
    }

    // Convert entire repository to Markdown
    let markdown = repo.toMarkdown()
    print("Generated \(markdown.count) characters of Markdown")

    // Access individual pages
    for module in repo.modules {
        for page in module.pages {
            let pageMarkdown = page.toMarkdown()
            print("Page '\(page.title)' converted to Markdown")
        }
    }
}
```

### DocC Documentation Generation
- **File Extensions**: Articles use `.md` with standard Markdown format
- **Content Structure**: Use standard Markdown headers, lists, code blocks, and formatting
- **Cross-References**: Use `<doc:FileName>` syntax for linking between documentation files
- **Code Examples**: Include practical code examples directly in Markdown code blocks with proper language tags
- **Generation Command**: Document generation with `swift package generate-documentation --target ShowroomAgentMVP`
- **Documentation Generation**: Generate documentation for the ShowroomAgentMVP target

### Version and Release Documentation
- **Migration Guides**: Include detailed migration instructions for breaking changes with:
  - Before/after code examples
  - Step-by-step migration process
  - Compatibility matrices
  - Rollback procedures
- **Version Compatibility**: Document Swift and platform version requirements for each release
- **Deprecation Notices**: Clearly mark deprecated APIs with migration paths and timelines

### Additional Documentation Articles
- **AsciiDoc-Supported-Elements.md**: Complete matrix of supported AsciiDoc elements
- **Conversion-Rules.md**: Detailed conversion rules and edge cases
- **Security-Considerations.md**: Security implications of parsing user-provided content
- **Integration-Examples.md**: Real-world integration patterns and use cases
- **Troubleshooting.md**: Common parsing issues and solutions
- **FAQ.md**: Frequently asked questions organized by category
- **Performance.md**: Performance benchmarks and optimization tips
- **Contributing.md**: Detailed contribution guidelines for documentation
- **Migration.md**: Comprehensive migration guide for major version upgrades
- **Project-Specifications.md**: Documentation of specification files and development methodology

### Specifications Documentation Requirements

For projects with comprehensive specification folders (like `Specs/`):

#### Required Specs Documentation Article
- **Project-Specifications.md** (REQUIRED when Specs folder exists): DocC article documenting specification files
  - Overview of specification purpose and target audiences
  - Description of each specification file with its role and contents
  - Usage guidance for different audiences (developers, AI code generators, architects)
  - Relationships between specification files and implementation
  - Quality standards and success criteria for implementations
  - Links to actual specification files in repository (https://github.com/RichNasz/ShowroomAgentMVP.git)
  - Development methodology and process documentation

#### Specs Folder Documentation Standards
- **Purpose Clarity**: Each specification file must have clear purpose and target audience definition
- **Separation of Concerns**: Maintain clear distinction between WHAT (requirements) and HOW (implementation)
- **Completeness**: Specifications should enable independent implementation without additional context
- **AI-Friendly**: Format specifications for both human understanding and AI code generation consumption
- **Version Alignment**: Keep specifications synchronized with implementation changes and updates
- **Cross-References**: Establish clear relationships and dependencies between specification files
- **Quality Gates**: Define success criteria and validation approaches for specification-driven development

#### Integration with Main Documentation
- Reference specifications article from main DocC documentation in "Development & Contribution" section
- Include comprehensive specifications overview in "Important Associated Content" section
- Link from Contributing.md for developers wanting detailed implementation guidelines
- Provide clear navigation paths from user documentation to development specifications
- Ensure specifications are discoverable for both human developers and AI systems
- Maintain consistency between specification documentation and implementation reality

#### Specification-Driven Development Documentation
- **Process Documentation**: Document how specifications guide development workflow
- **Quality Assurance**: Establish verification that implementation matches specifications
- **Knowledge Preservation**: Capture development insights and lessons learned during implementation
- **Replication Enablement**: Ensure specifications support creating similar implementations
- **Methodology Standards**: Define approaches for creating and maintaining comprehensive specifications

### Advanced DocC Features
- **Custom Themes**: Utilize DocC's theming capabilities for branded documentation
- **Interactive Tutorials**: Include downloadable example projects
- **Documentation Extensions**: Leverage DocC extensions for enhanced formatting


### Internationalization & Accessibility
- **Localization Support**: Prepare documentation structure for multiple languages
- **Accessibility Standards**: Follow WCAG 2.1 guidelines for web documentation
- **Screen Reader Optimization**: Ensure documentation works with screen readers
- **Keyboard Navigation**: Support full keyboard navigation in web documentation

### Security Considerations
- **Input Validation**: Document how user-provided AsciiDoc content is validated
- **File Access Security**: Explain file system access patterns and sandboxing
- **Memory Safety**: Address memory usage with large or malicious documents
- **Path Traversal Protection**: How the parser prevents directory traversal attacks
- **Character Encoding Security**: Safe handling of different text encodings
- **Resource Limits**: Configurable limits for parsing operations

### Integration Examples
- **Static Site Generators**: Integration with Hugo, Jekyll, or custom generators
- **Documentation Platforms**: Integration with GitBook, ReadTheDocs, or Confluence
- **Content Management Systems**: Integration with CMS platforms
- **API Documentation**: Converting AsciiDoc API docs to various formats
- **Learning Platforms**: Integration with e-learning and tutorial platforms

### Developer Experience Enhancements
- **Quick Reference Cards**: Create printable AsciiDoc-to-Markdown conversion guides
- **Video Tutorials**: Include video walkthroughs for parsing complex documents
- **Interactive Examples**: Provide online playgrounds for testing AsciiDoc conversion
- **Community Resources**: Link to community discussions, Stack Overflow, etc.

### Quality Assurance
- **Link Validation**: Ensure all cross-references and external links work
- **Code Testing**: Verify all code examples compile and run correctly
- **Accessibility**: Include alt-text for images and diagrams, follow WCAG guidelines
- **Consistency**: Maintain consistent terminology and formatting throughout
- **SEO Optimization**: Include meta descriptions and structured data for search engines
- **Mobile Responsiveness**: Ensure documentation works well on mobile devices
- **Review Process**: Documentation changes should be reviewed alongside code changes

### Documentation Maintenance
- **Version Management**: Tag documentation versions with releases
  - Use GitHub release tags for version tracking
- **Archival Strategy**: Maintain archives of previous documentation versions
- **Feedback Integration**: Include mechanisms for user feedback and suggestions
  - GitHub Discussions for community feedback
  - GitHub Issues for documentation bugs and improvement requests
- **Analytics Integration**: Track documentation usage and popular sections
  - GitHub Insights for repository activity monitoring
- **Regular Updates**: Schedule regular documentation review and updates

## Documentation Governance & Workflow

### Review Process
- **Documentation Reviews**: Require documentation review alongside code reviews
- **Technical Accuracy**: Ensure all code examples compile and work as documented
- **Clarity Assessment**: Evaluate documentation for understandability at target skill levels
- **Completeness Check**: Verify all public APIs are documented

### Contribution Workflow
- **Branch Strategy**: Use feature branches for documentation changes
- **Pull Request Template**: Include documentation checklist in PR template
- **Review Assignments**: Assign documentation experts for technical content

### Content Ownership
- **Subject Matter Experts**: Identify SME for different documentation areas
- **Review Cycles**: Establish regular review schedules for different content types
- **Update Triggers**: Define when documentation must be updated (API changes, releases)
- **Stale Content**: Process for identifying and updating outdated documentation

### Tooling & Automation
- **Documentation Linters**: Use tools to check documentation quality
  - `markdownlint`: For Markdown formatting consistency
  - `vale`: For style and grammar checking
- **Link Checkers**: Manual validation of all documentation links
  - `lychee`: Fast link checker for documentation


