# ProTech macOS DMG Build Guide

This guide explains how to create a distributable DMG installer for the ProTech macOS app.

## Quick Start (Automated)

The easiest way to create a DMG is to use the provided script:

```bash
cd /Users/swiezytv/Documents/Unknown/ProTech
./create_dmg.sh
```

This will:
1. Clean previous builds
2. Build the ProTech app in Release mode
3. Create a DMG installer with:
   - The ProTech.app
   - Applications folder symlink (for drag-and-drop installation)
   - README with installation instructions

**Output:** `ProTech-Installer.dmg` in the ProTech directory

## Manual Build Process

If you prefer to build manually or need more control:

### Step 1: Build the App

```bash
cd /Users/swiezytv/Documents/Unknown/ProTech

xcodebuild clean build \
    -project ProTech.xcodeproj \
    -scheme ProTech \
    -configuration Release \
    -derivedDataPath ./build \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO
```

### Step 2: Locate Built App

The built app will be in:
```
./build/Build/Products/Release/ProTech.app
```

### Step 3: Create DMG Directory Structure

```bash
mkdir -p dmg_contents
cp -R ./build/Build/Products/Release/ProTech.app dmg_contents/
ln -s /Applications dmg_contents/Applications
```

### Step 4: Create the DMG

```bash
hdiutil create -volname "ProTech Installer" \
    -srcfolder dmg_contents \
    -ov -format UDZO \
    ProTech-Installer.dmg
```

### Step 5: Clean Up

```bash
rm -rf dmg_contents build
```

## Installation Instructions

After creating the DMG, you can install ProTech on any Mac:

1. **Double-click** `ProTech-Installer.dmg` to mount it
2. **Drag** ProTech.app to the Applications folder
3. **Eject** the disk image
4. **Launch** ProTech from Applications

### Handling Security Warnings

Since this is an unsigned app (no Apple Developer certificate), macOS will show a security warning on first launch:

1. Go to **System Settings** > **Privacy & Security**
2. Scroll down to the Security section
3. Click **"Open Anyway"** next to the ProTech message
4. Confirm by clicking **"Open"**

**Note:** You only need to do this once per computer.

## DMG Contents

The installer includes:
- **ProTech.app** - The main application
- **Applications** (symlink) - For easy drag-and-drop installation
- **README.txt** - Installation instructions

## Build Configuration

### Code Signing

The script builds without code signing for personal use. If you want to distribute publicly:

1. Enroll in the [Apple Developer Program](https://developer.apple.com/programs/) ($99/year)
2. Create a Developer ID Application certificate
3. Modify the build command to use your signing identity:

```bash
xcodebuild ... \
    CODE_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
    CODE_SIGNING_REQUIRED=YES
```

### Notarization (Optional)

For public distribution, you should also notarize the app:

```bash
# Submit for notarization
xcrun notarytool submit ProTech-Installer.dmg \
    --apple-id "your@email.com" \
    --team-id "TEAMID" \
    --password "app-specific-password"

# Staple the notarization ticket
xcrun stapler staple ProTech-Installer.dmg
```

## Troubleshooting

### Build Errors

**Problem:** "Scheme 'ProTech' is not configured"
```bash
# List available schemes
xcodebuild -project ProTech.xcodeproj -list
```

**Problem:** Missing dependencies
```bash
# Open in Xcode and let it download Swift packages
open ProTech.xcodeproj
```

### DMG Creation Errors

**Problem:** "Resource busy" error
```bash
# Unmount any existing volumes
hdiutil detach "/Volumes/ProTech Installer" -force
```

**Problem:** Permission denied
```bash
# Make sure you own the build directory
sudo chown -R $(whoami) build
```

### Installation Issues

**Problem:** "ProTech is damaged and can't be opened"
- This happens when you try to open an unsigned app
- Solution: Use the "Open Anyway" option in System Settings

**Problem:** App crashes on launch
- Check Console.app for crash logs
- Ensure all dependencies (Supabase credentials) are configured

## Distribution

### For Personal Use (Multiple Macs)
- Copy the DMG to other Macs via AirDrop, USB, or cloud storage
- Install using the same drag-and-drop method

### For Team Distribution
- Share the DMG via internal file sharing
- Provide installation instructions (see above)
- Users will need to approve in System Settings

### For Public Distribution
- **Required:** Code signing + notarization
- **Recommended:** Distribute via your website or App Store
- Consider creating an installer package (.pkg) for automated deployment

## Advanced: Custom DMG Appearance

To create a custom background and icon layout:

1. Create the DMG with extra space:
```bash
hdiutil create -size 200m -format UDRW -volname "ProTech" temp.dmg
hdiutil attach temp.dmg
```

2. Customize the mounted volume:
- Add custom background image
- Arrange icons in Finder
- Set view options

3. Convert to compressed, read-only:
```bash
hdiutil detach "/Volumes/ProTech"
hdiutil convert temp.dmg -format UDZO -o ProTech-Installer.dmg
```

## File Sizes

Expected sizes:
- Built app: ~15-30 MB
- DMG (compressed): ~10-20 MB

Actual size depends on assets and dependencies.

## Next Steps

After building the DMG:

1. **Test** the installation on a clean Mac (or VM)
2. **Verify** all features work (database, cloud sync, etc.)
3. **Update** the Configuration.swift file with production Supabase credentials
4. **Document** any setup steps for end users
5. **Create** a support page for troubleshooting

## Support

For issues with:
- **Building:** Check Xcode build logs
- **DMG creation:** Verify disk space and permissions
- **Installation:** Check macOS security settings
- **Runtime:** Review app logs and Supabase connection

---

**Ready to build?** Run `./create_dmg.sh` and you'll have a distributable DMG in minutes!
