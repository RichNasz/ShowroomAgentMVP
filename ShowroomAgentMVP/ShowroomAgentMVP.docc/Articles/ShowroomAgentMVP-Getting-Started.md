# Getting Started with ShowroomAgentMVP

Learn how to set up and use ShowroomAgentMVP to transform your technical documentation into engaging marketing content.

## Overview

ShowroomAgentMVP streamlines the process of converting technical documentation stored in GitHub repositories into compelling blog posts and social media content. This guide will walk you through the complete setup and usage process.

## Prerequisites

Before you begin, ensure you have the following:

### System Requirements
- **macOS 15.0** or later
- **Internet connection** for repository access and LLM services
- **Local storage space** for repository clones (typically 100MB-1GB per project)

### Documentation Requirements
- **GitHub Repository** containing your technical documentation
- **Antora Structure** with proper configuration files:
  - `content/antora.yml` - Site configuration
  - `content/modules/ROOT/nav.adoc` - Navigation structure
  - `content/modules/ROOT/pages/` - Documentation pages (`.adoc` or `.md` files)

### LLM Service Access
Choose one of the following AI service options:
- **OpenAI API** account with API key
- **Local Ollama** installation with compatible models
- **Custom LLM endpoint** with OpenAI-compatible API

## Installation

### Download and Launch
1. Download ShowroomAgentMVP from the source repository
2. Move the application to your Applications folder
3. Launch the application - you'll see the main project management interface

### First Launch Setup
On first launch, the application will:
- Request necessary file system permissions
- Create local data storage for projects
- Display the welcome interface with project creation options

## Creating Your First Project

### Step 1: Project Creation

1. Click the **"+" button** in the sidebar or use **"New Project"** from the menu
2. Enter a **descriptive name** for your project (e.g., "API Documentation Blog")
3. Optionally configure repository settings immediately, or set them up later
4. Click **"Create"** to establish your project

### Step 2: Repository Configuration

Configure your GitHub repository source:

1. **Select your project** from the sidebar
2. Click **"Configure"** in the project detail view
3. **Repository URL**: Enter your GitHub repository URL
   ```
   https://github.com/your-organization/documentation-repo
   ```
4. **Local Folder**: Choose a directory for storing cloned content
   - Click "Choose Folder" to select location
   - Grant permission when prompted by macOS
5. **Save configuration** to persist settings

### Step 3: Repository Validation

Validate that your repository is compatible:

1. Click **"Clone Repository"** to download content locally
2. Wait for the download to complete (progress will be shown)
3. The system automatically validates repository structure
4. Review validation results:
   - ✅ **Success**: Repository is ready for content generation
   - ❌ **Failure**: Review error messages and fix repository structure

#### Common Validation Issues

**Missing Configuration Files**:
```
Error: Required file missing: antora.yml
Solution: Add antora.yml to your content/ directory
```

**Invalid Navigation Structure**:
```
Error: Navigation file not found: modules/ROOT/nav.adoc
Solution: Create navigation file with proper Antora structure
```

**No Content Pages**:
```
Error: No content pages found
Solution: Add .adoc or .md files to modules/ROOT/pages/
```

## LLM Service Configuration

### OpenAI Configuration

1. **Obtain API Key**: Sign up at [OpenAI](https://platform.openai.com) and create an API key
2. **Configure in ShowroomAgentMVP**:
   - **Endpoint URL**: `https://api.openai.com/v1/chat/completions`
   - **Model Name**: `gpt-4` (or your preferred model)
   - **API Key**: Your OpenAI API key
   - **Temperature**: `0.7` (balance between creativity and consistency)

### Local Ollama Configuration

1. **Install Ollama**: Download from [ollama.ai](https://ollama.ai)
2. **Download Models**: 
   ```bash
   ollama pull llama2
   ollama pull codellama
   ```
3. **Configure in ShowroomAgentMVP**:
   - **Endpoint URL**: `http://localhost:11434/v1/chat/completions`
   - **Model Name**: `llama2` (or your installed model)
   - **API Key**: Leave empty for local models
   - **Temperature**: `0.7`

### Custom Endpoint Configuration

For other LLM providers with OpenAI-compatible APIs:

1. **Endpoint URL**: Your provider's chat completions endpoint
2. **Model Name**: Model identifier from your provider
3. **API Key**: Authentication token from your provider
4. **Temperature**: Creativity setting (0.0 = deterministic, 1.0 = creative)

## Generating Your First Content

### Step 1: Start Content Generation

1. **Select your configured project** from the sidebar
2. **Choose activity type**: 
   - **Blog Goal**: Generate blog posts from documentation
   - **Social Media**: Create social media content
   - **Email Campaign**: Generate email newsletter content
3. **Click "Blog Goal"** to begin the content generation workflow

### Step 2: Content Generation Workflow

The application guides you through a multi-step process:

#### Introduction
- Overview of the content generation process
- Confirmation of project configuration
- Preview of available content

#### Validate Content
- Automatic validation of repository structure
- Verification of ShowroomParser compatibility
- Display of discovered content and navigation

#### Configure Prompt
- **Default Prompt**: Pre-configured prompt for blog generation
- **Custom Prompt**: Edit prompt to match your brand voice and requirements
- **Preview**: See how the prompt will be used with your content

Example custom prompt:
```
Generate an engaging technical blog post suitable for a developer audience. 
Focus on practical benefits and include code examples where relevant. 
Use a conversational but professional tone that matches our company's voice.
Structure the content with clear headings and bullet points for readability.
```

#### Generate Content
- **Processing**: The LLM analyzes your documentation content
- **Generation**: AI creates engaging content based on your prompt
- **Progress**: Real-time status updates during generation

#### Review Content
- **Generated Output**: Review the AI-generated content
- **Edit Options**: Make adjustments or regenerate as needed
- **Export**: Copy content for use in your blog or CMS

### Step 3: Content Review and Refinement

After generation, review your content:

#### Quality Checklist
- ✅ **Technical Accuracy**: Verify all technical details are correct
- ✅ **Brand Voice**: Ensure tone matches your organization's style
- ✅ **Readability**: Check flow and structure for target audience
- ✅ **Call-to-Action**: Add appropriate CTAs for your goals

#### Regeneration Options
If content needs adjustment:
1. **Modify Prompt**: Refine your generation instructions
2. **Adjust Temperature**: Lower for more focused content, higher for creativity
3. **Regenerate**: Create new content with updated parameters

## Best Practices

### Repository Organization

**Optimal Structure**:
```
your-repo/
├── content/
│   ├── antora.yml              # Clear site configuration
│   └── modules/
│       └── ROOT/
│           ├── nav.adoc        # Well-organized navigation
│           └── pages/          # Logically grouped content
│               ├── getting-started.adoc
│               ├── tutorials/
│               └── reference/
```

**Content Quality**:
- **Comprehensive Documentation**: More content leads to richer generated articles
- **Clear Structure**: Well-organized navigation improves content flow
- **Up-to-Date Information**: Regular updates ensure generated content is current

### Prompt Engineering

**Effective Prompts**:
- **Be Specific**: Define target audience, tone, and format clearly
- **Include Context**: Mention your product, industry, and key messages
- **Specify Structure**: Request headings, bullet points, or specific sections
- **Set Constraints**: Define length limits and content requirements

**Example Professional Prompt**:
```
Create a technical blog post for enterprise developers about [topic].

Requirements:
- Target audience: Senior developers and technical leads
- Tone: Professional yet approachable
- Length: 1200-1500 words
- Include: Code examples, best practices, implementation tips
- Structure: Introduction, main concepts, practical examples, conclusion
- Style: Similar to posts on [your company blog]

Focus on practical value and real-world applications.
```

### Content Workflow Integration

**Efficient Process**:
1. **Batch Projects**: Set up multiple documentation repositories
2. **Template Prompts**: Create reusable prompts for different content types
3. **Regular Updates**: Refresh repository content for ongoing campaigns
4. **Quality Review**: Establish consistent review processes

**Content Calendar Integration**:
- **Plan Ahead**: Generate content aligned with product releases
- **Seasonal Content**: Create timely content around events and conferences
- **Series Development**: Use related documentation for content series

## Troubleshooting

### Common Issues and Solutions

#### Repository Access Problems

**Private Repository Access**:
- Ensure repository is publicly accessible or you have proper credentials
- For private repos, consider using personal access tokens

**Large Repository Downloads**:
- Allow sufficient time for initial clone (may take several minutes)
- Ensure stable internet connection during download
- Check available disk space in your chosen local folder

#### Content Generation Issues

**Empty or Poor Quality Output**:
- **Check Source Content**: Ensure sufficient documentation exists
- **Refine Prompt**: Add more specific instructions and context
- **Adjust Temperature**: Try different creativity settings
- **Verify LLM Configuration**: Test connection to your AI service

**LLM Service Errors**:
- **API Key Issues**: Verify key is valid and has sufficient credits
- **Network Problems**: Check internet connection and service status
- **Rate Limiting**: Wait and retry if hitting service limits

#### File System Permissions

**Folder Access Denied**:
- **Re-select Folder**: Choose folder again to refresh permissions
- **Check Permissions**: Ensure you have read/write access to chosen directory
- **Security Settings**: Review macOS Security & Privacy settings

### Getting Help

#### Documentation Resources
- **In-App Help**: Use help buttons throughout the interface
- **Architecture Guide**: See <doc:ShowroomAgentMVP-Architecture-Overview> for technical details
- **Specifications**: Review project specifications for detailed requirements

#### Community Support
- **GitHub Issues**: Report bugs and request features
- **GitHub Discussions**: Ask questions and share experiences
- **Documentation Updates**: Contribute improvements to guides

## Next Steps

### Explore Advanced Features

Once comfortable with basic content generation:

1. **Multi-Activity Support**: Try different content types (social media, email)
2. **Custom Prompt Libraries**: Build reusable prompt templates
3. **Workflow Integration**: Connect with your existing content pipelines
4. **Performance Optimization**: Fine-tune settings for your use cases

### Expand Your Content Strategy

**Scale Your Operations**:
- **Multiple Projects**: Manage different documentation sources
- **Content Variety**: Generate diverse content types for various channels
- **Team Collaboration**: Share projects and prompts with team members
- **Automated Workflows**: Integrate with CI/CD for automated content updates

**Measure Success**:
- **Content Performance**: Track engagement with generated content
- **Time Savings**: Measure efficiency gains in content creation
- **Quality Improvements**: Monitor technical accuracy and brand consistency

### Stay Updated

**Keep Current**:
- **Application Updates**: Install updates for new features and improvements
- **LLM Developments**: Explore new AI models and capabilities
- **Best Practices**: Follow evolving content generation techniques
- **Community Contributions**: Participate in the ShowroomAgentMVP community

---

You're now ready to transform your technical documentation into compelling marketing content with ShowroomAgentMVP. Start with a simple project and gradually explore the platform's advanced capabilities as you become more familiar with the workflow.