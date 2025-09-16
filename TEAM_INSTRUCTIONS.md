# ShowroomAgentMVP - Team Installation Instructions

**Quick Installation Guide for Internal Users**

## Quick Start (2 Simple Steps)

### Step 1: Download
Download `ShowroomAgentMVP-unsigned.zip` from your team's shared location or distribution point.

### Step 2: Install & Run
1. **Extract**: Double-click the ZIP file to extract `ShowroomAgentMVP.app`
2. **First Launch**: Right-click on `ShowroomAgentMVP.app` → Select "Open"
3. **Security Dialog**: Click "Open" in the macOS security warning dialog
4. **Done**: The app will launch and work normally from now on

## That's It! 🎉

After this one-time security approval:
- ✅ Double-click the app to launch it normally (no more right-clicking needed)
- ✅ Move it to your Applications folder if desired
- ✅ Create a dock shortcut for quick access
- ✅ App will receive automatic updates through normal distribution channels

## About the App

**ShowroomAgentMVP** is an AI-powered content generation tool that:
- Transforms technical documentation into engaging blog posts
- Generates social media content from GitHub repositories
- Uses structured Antora documentation as source material
- Integrates with various LLM providers (OpenAI, local Ollama, etc.)

## System Requirements

- **macOS**: 15.0 (macOS Sequoia) or later
- **Storage**: ~50MB for the application
- **Network**: Internet connection for GitHub repository access and LLM services
- **Permissions**: The app will request folder access permissions when needed

## Why Right-Click "Open"?

Since this is an internal company application (not distributed through the Mac App Store), macOS Gatekeeper shows a security warning the first time you launch it. Using right-click → "Open" bypasses the stricter security check that prevents double-clicking unsigned apps.

**This is normal and safe** - it's standard procedure for internal company software.

## Troubleshooting

### Common Issues

**Problem**: "Cannot open because it is from an unidentified developer"
**Solution**: Make sure you right-clicked and selected "Open" (don't double-click the first time)

**Problem**: App won't open after moving to Applications folder
**Solution**: Right-click → "Open" again after moving to complete the security approval

**Problem**: App asks for folder permissions
**Solution**: This is normal - grant access to folders where you want to store projects and generated content

**Problem**: App won't connect to GitHub or LLM services
**Solution**: Check your network connection and verify any API keys are configured correctly

**Problem**: Still having issues or need help?
**Contact**: Your IT support team or the application administrator

## Security Notes

- ✅ This app is built and distributed by your organization
- ✅ The security warning is expected for internal apps
- ✅ The app uses standard macOS security practices
- ✅ No sensitive data is transmitted without your explicit configuration
- ✅ All data remains local unless you configure external LLM services

## Getting Started

After installation:

1. **Create Your First Project**: Launch the app and create a new project with a descriptive name
2. **Configure Repository**: Add a GitHub repository URL containing your technical documentation
3. **Set Storage Location**: Choose a local folder for storing projects and generated content
4. **Configure LLM Service**: Set up your preferred AI service (OpenAI, local Ollama, or custom endpoint)
5. **Generate Content**: Use the guided workflow to transform documentation into content

## Version Information

- **Current Version**: 1.0
- **Build Type**: Unsigned (Internal Distribution)
- **Support**: Internal company use only
- **Updates**: Distributed through your team's normal software distribution channels

---

**ShowroomAgentMVP** - Transforming technical documentation into compelling content with AI assistance.