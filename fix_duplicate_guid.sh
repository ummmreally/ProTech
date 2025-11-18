#!/bin/bash

# Fix Duplicate GUID Error in Xcode
echo "🔧 Fixing Duplicate GUID Error"
echo "==============================="
echo ""

# IMPORTANT: Close Xcode before running this!
echo "⚠️  CLOSE XCODE NOW if it's open, then press Enter to continue..."
read

cd /Users/swiezytv/Documents/Unknown/ProTech

echo "1. Removing all Xcode caches..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/Caches/com.apple.dt.Xcode
echo "✅ Xcode caches cleared"
echo ""

echo "2. Removing project-specific build artifacts..."
rm -rf .swiftpm
rm -rf build
rm -rf .build
echo "✅ Build artifacts removed"
echo ""

echo "3. Removing workspace user data..."
rm -rf ProTech.xcodeproj/project.xcworkspace/xcuserdata/*
rm -rf ProTech.xcodeproj/xcuserdata/*
echo "✅ User data cleared"
echo ""

echo "4. Removing Package.resolved to force fresh resolution..."
rm -f ProTech.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
echo "✅ Package state reset"
echo ""

echo "5. Resolving packages from scratch..."
xcodebuild -resolvePackageDependencies -project ProTech.xcodeproj -scheme ProTech 2>&1 | grep -E "(Fetching|Resolved|error:)"
echo ""

echo "✅ Done!"
echo ""
echo "📖 Now open Xcode and:"
echo "1. Let Xcode index the project (wait for spinner to finish)"
echo "2. File → Packages → Reset Package Caches"
echo "3. Product → Clean Build Folder (Cmd+Shift+K)"
echo "4. Product → Build (Cmd+B)"
echo ""
echo "The duplicate GUID error should be gone!"
