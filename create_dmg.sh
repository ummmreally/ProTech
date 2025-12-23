#!/bin/bash

# ProTech macOS App DMG Builder
# This script builds the ProTech app and creates a DMG installer

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}ProTech DMG Builder${NC}"
echo -e "${BLUE}======================================${NC}"

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="ProTech"
SCHEME="ProTech"
APP_NAME="ProTech.app"
BUILD_DIR="${PROJECT_DIR}/build"
RELEASE_DIR="${BUILD_DIR}/Release"
DMG_NAME="ProTech-Installer.dmg"
DMG_TEMP_DIR="${BUILD_DIR}/dmg_temp"
VOLUME_NAME="ProTech Installer"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"
NOTARIZE="${NOTARIZE:-0}"
APPLE_ID="${APPLE_ID:-}"
TEAM_ID="${TEAM_ID:-}"
NOTARY_PASSWORD="${NOTARY_PASSWORD:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"

# Clean previous builds
echo -e "\n${BLUE}Cleaning previous builds...${NC}"
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Build the app
echo -e "\n${BLUE}Building ProTech app for macOS...${NC}"
if [ -n "${SIGN_IDENTITY}" ]; then
    xcodebuild clean build \
        -project "${PROJECT_DIR}/ProTech.xcodeproj" \
        -scheme "${SCHEME}" \
        -configuration Release \
        -derivedDataPath "${BUILD_DIR}" \
        CODE_SIGN_IDENTITY="${SIGN_IDENTITY}" \
        CODE_SIGNING_REQUIRED=YES \
        CODE_SIGNING_ALLOWED=YES
else
    xcodebuild clean build \
        -project "${PROJECT_DIR}/ProTech.xcodeproj" \
        -scheme "${SCHEME}" \
        -configuration Release \
        -derivedDataPath "${BUILD_DIR}" \
        CODE_SIGN_IDENTITY="-" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO
fi

# Find the built app
BUILT_APP=$(find "${BUILD_DIR}" -name "${APP_NAME}" -type d | head -n 1)

if [ ! -d "${BUILT_APP}" ]; then
    echo -e "${RED}Error: Could not find built app${NC}"
    exit 1
fi

echo -e "${GREEN}✓ App built successfully${NC}"
echo -e "  Location: ${BUILT_APP}"

if [ -n "${SIGN_IDENTITY}" ]; then
    echo -e "\n${BLUE}Signing app...${NC}"
    /usr/bin/codesign --force --deep --options runtime --timestamp --sign "${SIGN_IDENTITY}" "${BUILT_APP}"
    /usr/bin/codesign --verify --deep --strict "${BUILT_APP}"
    echo -e "${GREEN}✓ App signed successfully${NC}"
fi

# Create DMG
echo -e "\n${BLUE}Creating DMG installer...${NC}"

# Create temporary directory for DMG contents
rm -rf "${DMG_TEMP_DIR}"
mkdir -p "${DMG_TEMP_DIR}"

# Copy app to temp directory
cp -R "${BUILT_APP}" "${DMG_TEMP_DIR}/"

# Create Applications symlink for easy installation
ln -s /Applications "${DMG_TEMP_DIR}/Applications"

# Create README file
cat > "${DMG_TEMP_DIR}/README.txt" << 'EOF'
ProTech Installation Instructions
==================================

To install ProTech:
1. Drag the ProTech app to the Applications folder
2. Open ProTech from your Applications folder
3. If you see a security warning, go to System Settings > Privacy & Security
   and click "Open Anyway"

Requirements:
- macOS 13.0 or later
- Internet connection for cloud sync features

For support, visit: https://yourwebsite.com/support
EOF

# Remove any existing DMG
rm -f "${PROJECT_DIR}/${DMG_NAME}"

# Create the DMG
echo -e "${BLUE}Packaging DMG...${NC}"
hdiutil create \
    -volname "${VOLUME_NAME}" \
    -srcfolder "${DMG_TEMP_DIR}" \
    -ov \
    -format UDZO \
    "${PROJECT_DIR}/${DMG_NAME}"

# Clean up temp directory
rm -rf "${DMG_TEMP_DIR}"

# Get DMG size
DMG_SIZE=$(du -h "${PROJECT_DIR}/${DMG_NAME}" | cut -f1)

echo -e "\n${GREEN}======================================${NC}"
echo -e "${GREEN}✓ DMG created successfully!${NC}"
echo -e "${GREEN}======================================${NC}"
echo -e "\nFile: ${PROJECT_DIR}/${DMG_NAME}"
echo -e "Size: ${DMG_SIZE}"

if [ "${NOTARIZE}" = "1" ]; then
    if [ -z "${SIGN_IDENTITY}" ]; then
        echo -e "${RED}Error: NOTARIZE=1 requires SIGN_IDENTITY to be set${NC}"
        exit 1
    fi

    if [ -n "${NOTARY_PROFILE}" ]; then
        echo -e "\n${BLUE}Submitting DMG for notarization (keychain profile)...${NC}"
        xcrun notarytool submit "${PROJECT_DIR}/${DMG_NAME}" --keychain-profile "${NOTARY_PROFILE}" --wait
    else
        if [ -z "${APPLE_ID}" ] || [ -z "${TEAM_ID}" ] || [ -z "${NOTARY_PASSWORD}" ]; then
            echo -e "${RED}Error: NOTARIZE=1 requires either NOTARY_PROFILE or (APPLE_ID, TEAM_ID, NOTARY_PASSWORD)${NC}"
            exit 1
        fi
        echo -e "\n${BLUE}Submitting DMG for notarization...${NC}"
        xcrun notarytool submit "${PROJECT_DIR}/${DMG_NAME}" --apple-id "${APPLE_ID}" --team-id "${TEAM_ID}" --password "${NOTARY_PASSWORD}" --wait
    fi

    echo -e "\n${BLUE}Stapling notarization ticket...${NC}"
    xcrun stapler staple "${PROJECT_DIR}/${DMG_NAME}"
    echo -e "${GREEN}✓ Notarization complete (stapled)${NC}"
fi

echo -e "\n${BLUE}To install:${NC}"
echo -e "1. Double-click ${DMG_NAME}"
echo -e "2. Drag ProTech.app to the Applications folder"
echo -e "3. Eject the disk image"
echo -e "4. Launch ProTech from Applications"
echo -e "\n${BLUE}Note:${NC} If you see a security warning, go to"
echo -e "System Settings > Privacy & Security > Open Anyway"
