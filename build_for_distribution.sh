#!/bin/bash

# ShowroomAgentMVP Distribution Build Script
# This script builds and prepares the app for unsigned distribution (internal use)

set -e  # Exit on any error

# Configuration
APP_NAME="ShowroomAgentMVP"
SCHEME_NAME="ShowroomAgentMVP"
BUILD_DIR="build"
DIST_DIR="dist"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
EXPORT_PATH="$DIST_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting unsigned distribution build for $APP_NAME${NC}"
echo -e "${BLUE}📋 Configuration: Unsigned build for internal company use${NC}"

# Clean previous builds
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
rm -rf "$BUILD_DIR"
rm -rf "$DIST_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$DIST_DIR"

# Build the archive
echo -e "${YELLOW}🔨 Building archive...${NC}"
xcodebuild archive \
    -scheme "$SCHEME_NAME" \
    -archivePath "$ARCHIVE_PATH" \
    -configuration Release \
    -destination "generic/platform=macOS"

# Export the app (unsigned)
echo -e "${YELLOW}📦 Exporting unsigned app for distribution...${NC}"

# Create export options plist for unsigned distribution
cat > "$BUILD_DIR/ExportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>mac-application</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>destination</key>
    <string>export</string>
</dict>
</plist>
EOF

# Export the archive
if command -v xcpretty &> /dev/null; then
    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist "$BUILD_DIR/ExportOptions.plist" \
        | xcpretty
else
    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist "$BUILD_DIR/ExportOptions.plist"
fi

# Create ZIP for easy distribution
echo -e "${YELLOW}📦 Creating ZIP for distribution...${NC}"
cd "$DIST_DIR"
zip -r "$APP_NAME-unsigned.zip" "$APP_NAME.app"
cd ..

# Create DMG (optional, only if create-dmg is available)
if command -v create-dmg &> /dev/null; then
    echo -e "${YELLOW}💿 Creating DMG...${NC}"
    create-dmg \
        --volname "$APP_NAME" \
        --window-pos 200 120 \
        --window-size 800 400 \
        --icon-size 100 \
        --icon "$APP_NAME.app" 200 190 \
        --hide-extension "$APP_NAME.app" \
        --app-drop-link 600 185 \
        "$DIST_DIR/$APP_NAME-unsigned.dmg" \
        "$DIST_DIR/$APP_NAME.app" || echo -e "${YELLOW}⚠️  DMG creation failed, ZIP file is available${NC}"
fi

echo -e "${GREEN}✅ Unsigned build complete!${NC}"
echo -e "${GREEN}📁 App location: $DIST_DIR/$APP_NAME.app${NC}"
echo -e "${GREEN}📦 ZIP file: $DIST_DIR/$APP_NAME-unsigned.zip${NC}"
echo -e "${GREEN}📋 Archive location: $ARCHIVE_PATH${NC}"

# Distribution instructions
echo ""
echo -e "${BLUE}📝 Distribution Instructions:${NC}"
echo -e "${BLUE}===========================${NC}"
echo ""
echo -e "${YELLOW}For Team Distribution:${NC}"
echo "1. Share the file: $DIST_DIR/$APP_NAME-unsigned.zip"
echo "2. Provide installation instructions from TEAM_INSTRUCTIONS.md"
echo "3. Team members should:"
echo "   - Extract the ZIP file"
echo "   - Right-click the app → Select 'Open'"
echo "   - Click 'Open' in the security dialog"
echo ""
echo -e "${YELLOW}Testing:${NC}"
echo "- Test the app on a different Mac before distributing"
echo "- Verify it launches properly using right-click → Open"
echo ""
echo -e "${YELLOW}Note:${NC}"
echo "- This is an unsigned build for internal use only"
echo "- Users will see a security warning on first launch"
echo "- For broader distribution, consider signed builds (see DISTRIBUTION_GUIDE.md)"
echo ""
echo -e "${GREEN}🎉 Your unsigned app is ready for team distribution!${NC}"