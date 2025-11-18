#!/bin/bash

# Fix Missing Supabase Package in Xcode
echo "🔧 Fixing Supabase Package Dependencies"
echo "========================================"
echo ""

cd /Users/swiezytv/Documents/Unknown/ProTech

# Step 1: Clean package cache
echo "1. Cleaning Swift Package Manager cache..."
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf .build
echo "✅ Cache cleaned"
echo ""

# Step 2: Reset package resolved
echo "2. Resetting package resolution..."
rm -rf .swiftpm
echo "✅ Package state reset"
echo ""

# Step 3: Try to resolve packages via xcodebuild
echo "3. Resolving packages..."
xcodebuild -resolvePackageDependencies -project ProTech.xcodeproj -scheme ProTech 2>&1 | grep -E "(Resolved source packages:|error:|Fetching)"
echo ""

echo "✅ Done!"
echo ""
echo "📖 Next Steps:"
echo "1. Open Xcode"
echo "2. File → Packages → Reset Package Caches"
echo "3. File → Packages → Resolve Package Versions"
echo "4. Clean Build Folder (Cmd+Shift+K)"
echo "5. Build (Cmd+B)"
echo ""
echo "If still not working, in Xcode:"
echo "  - Select ProTech project in navigator"
echo "  - Go to 'Package Dependencies' tab"
echo "  - Click '+' and re-add: https://github.com/supabase-community/supabase-swift"
echo "  - Version: 2.34.0"
