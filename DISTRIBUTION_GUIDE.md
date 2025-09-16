# ShowroomAgentMVP Distribution Guide

This guide covers building and distributing your ShowroomAgentMVP application for **internal company use** without Apple App Store approval or code signing requirements.

## Current Configuration: Unsigned Distribution

This project is configured for **unsigned distribution** - the easiest approach for internal team sharing without requiring Apple Developer certificates or notarization.

## Prerequisites

### Required Tools
```bash
# Install xcpretty for prettier build output (optional)
gem install xcpretty

# Install create-dmg for DMG creation (optional)
brew install create-dmg
```

**No Apple Developer Account or certificates required!**

## Building for Distribution

### Quick Build (Recommended)
```bash
./build_for_distribution.sh
```

### Manual Build Process

1. **Clean and Archive:**
```bash
xcodebuild archive \
    -scheme ShowroomAgentMVP \
    -archivePath build/ShowroomAgentMVP.xcarchive \
    -configuration Release \
    -destination "generic/platform=macOS"
```

2. **Export Unsigned App:**
```bash
xcodebuild -exportArchive \
    -archivePath build/ShowroomAgentMVP.xcarchive \
    -exportPath dist \
    -exportOptionsPlist build/ExportOptions.plist
```

## Distribution Process

### Step 1: Build the App
Run the build script to create an unsigned version:
```bash
./build_for_distribution.sh
```

This creates:
- `dist/ShowroomAgentMVP.app` - The unsigned application
- `dist/ShowroomAgentMVP.zip` - ZIP file for easy distribution

### Step 2: Distribute to Team
1. Share the `ShowroomAgentMVP.zip` file with your team
2. Provide installation instructions (see `TEAM_INSTRUCTIONS.md`)
3. Team members extract and run using right-click → "Open"

## User Installation Process

Users need to follow these simple steps:

1. **Download** the `ShowroomAgentMVP.zip` file
2. **Extract** by double-clicking the ZIP file
3. **First Launch**: Right-click `ShowroomAgentMVP.app` → Select "Open"
4. **Security Dialog**: Click "Open" in the security warning
5. **Done**: App works normally from then on

## Project Configuration Details

### Build Settings (Current)
- **Code Signing Identity:** "" (empty - no signing)
- **Code Signing Style:** Manual
- **Hardened Runtime:** NO (disabled for unsigned apps)
- **App Sandbox:** NO (disabled for broader file system access)
- **Deployment Target:** macOS 15.5

### Entitlements
The app uses these entitlements (`ShowroomAgentMVP.entitlements`):
- ✅ Network client access (for GitHub API)
- ✅ User-selected file read/write access
- ✅ Downloads folder read/write access
- ❌ App Sandbox (disabled for broader file system access)
- ❌ Hardened Runtime (disabled for unsigned distribution)

### Bundle Configuration
- **Bundle Identifier:** `com.naszcyniec.ShowroomAgentMVP`
- **Version:** Uses `MARKETING_VERSION` (1.0)
- **Build Number:** Uses `CURRENT_PROJECT_VERSION` (1)

## Alternative: Signed Distribution (Advanced)

If you later want to distribute with code signing and notarization:

### Prerequisites for Signed Distribution
- Apple Developer Program membership ($99/year)
- Developer ID Application certificate
- App-specific password for notarization

### Configuration Changes Needed
1. Set `CODE_SIGN_IDENTITY` to "Developer ID Application"
2. Set `CODE_SIGN_STYLE` to "Automatic"
3. Enable `ENABLE_HARDENED_RUNTIME`
4. Update Team ID in build settings
5. Configure notarization credentials

See the original signed distribution section below for detailed steps.

## Troubleshooting

### Common Issues

1. **"Cannot open because it is from an unidentified developer"**
   - Solution: Use right-click → "Open" instead of double-clicking
   - This only happens on first launch

2. **App won't open after moving to Applications**
   - Solution: Right-click → "Open" again after moving

3. **Build failures**
   - Check Xcode is using the correct scheme
   - Verify all dependencies are resolved
   - Clean build folder and try again

### Checking Build Status
```bash
# View available schemes
xcodebuild -list

# Check current build settings
xcodebuild -showBuildSettings -scheme ShowroomAgentMVP

# Verify the app bundle
file dist/ShowroomAgentMVP.app/Contents/MacOS/ShowroomAgentMVP
```

## Updating for New Releases

1. Update `MARKETING_VERSION` in project settings for version updates
2. Update `CURRENT_PROJECT_VERSION` for build number increments
3. Run the build script: `./build_for_distribution.sh`
4. Test the unsigned app on a different Mac
5. Distribute the new ZIP file to your team

## Security Considerations

- Unsigned apps require user approval on first launch
- Only distribute to trusted team members
- Consider signed distribution for broader deployment
- Regularly update dependencies for security patches
- Users should verify the source of the app before installation

---

## Advanced: Signed Distribution Setup

*For future reference if you want to enable code signing and notarization:*

### 1. Apple Developer Setup
- Enroll in Apple Developer Program
- Generate Developer ID Application certificate
- Install certificate in Keychain

### 2. Notarization Setup
```bash
# Store credentials
xcrun notarytool store-credentials "notarytool-profile" \
    --apple-id "your-apple-id@example.com" \
    --team-id "YOUR_TEAM_ID" \
    --password "your-app-specific-password"

# Submit for notarization
xcrun notarytool submit dist/ShowroomAgentMVP.app \
    --keychain-profile "notarytool-profile" \
    --wait

# Staple the ticket
xcrun stapler staple dist/ShowroomAgentMVP.app
```

### 3. Project Configuration Changes
- Update `CODE_SIGN_IDENTITY` to "Developer ID Application"
- Enable `ENABLE_HARDENED_RUNTIME`
- Set proper Team ID
- Update build script for signed export

---

Your ShowroomAgentMVP is now configured for professional distribution outside the Mac App Store!