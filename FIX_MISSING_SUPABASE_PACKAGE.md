# 🔧 Fix Missing Supabase Package

## Error
```
Missing package product 'Supabase'
```

This error occurs when Xcode's Swift Package Manager cache becomes corrupted or desynchronized, typically after cleaning derived data.

---

## 🚀 Quick Fix (In Xcode)

### Method 1: Reset Package Caches (Fastest)
1. **Open Xcode**
2. **File → Packages → Reset Package Caches**
3. Wait for packages to download
4. **File → Packages → Resolve Package Versions**
5. **Product → Clean Build Folder** (⌘⇧K)
6. **Build** (⌘B)

### Method 2: Manual Package Resolution
If Method 1 doesn't work:

1. **Close Xcode completely**
2. **Run the fix script:**
   ```bash
   cd /Users/swiezytv/Documents/Unknown/ProTech
   ./fix_packages.sh
   ```
3. **Open Xcode**
4. **Build**

### Method 3: Re-add Package Dependency
If Methods 1-2 don't work:

1. **Open Xcode**
2. Select **ProTech** project in navigator (top-level)
3. Select **ProTech** target
4. Go to **Package Dependencies** tab
5. Find **supabase-swift** in the list
6. If it shows an error or is missing:
   - Click **+** button
   - Enter: `https://github.com/supabase-community/supabase-swift`
   - Choose version: **Up to Next Major Version: 2.34.0**
   - Click **Add Package**
7. Make sure **Supabase** product is checked for ProTech target
8. **Clean and Build**

---

## 🔍 Verify Package Is Installed

### Check Package.resolved
```bash
cat ProTech.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved | grep -A 5 supabase-swift
```

**Expected output:**
```json
"identity" : "supabase-swift",
"kind" : "remoteSourceControl",
"location" : "https://github.com/supabase-community/supabase-swift",
"state" : {
  "version" : "2.34.0"
}
```

### Check Project Settings
In Xcode:
1. Select **ProTech** project
2. **Package Dependencies** tab
3. Should show: `supabase-swift` @ 2.34.0 ✅

---

## 🧹 Manual Cache Cleanup (Terminal)

If Xcode methods don't work, try this complete cleanup:

```bash
# Navigate to project
cd /Users/swiezytv/Documents/Unknown/ProTech

# Close Xcode first!

# Clean all caches
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf .build
rm -rf build/

# Clean project-specific SPM state
rm -rf .swiftpm/

# Resolve packages
xcodebuild -resolvePackageDependencies -project ProTech.xcodeproj -scheme ProTech

# Now open Xcode and build
```

---

## 🔧 Why This Happens

When you clean derived data (which we did to fix the disk I/O errors), Xcode sometimes loses track of Swift Package Manager dependencies. The packages are still defined in `Package.resolved`, but Xcode needs to re-download and re-link them.

**Common triggers:**
- Cleaning derived data
- Xcode crashes
- Disk I/O errors during build
- Git operations that affect `.swiftpm/` folder
- Network interruptions during package download

---

## ✅ Verification Steps

After applying the fix, verify these are working:

```bash
# Check imports compile
grep -r "import Supabase" ProTech/ProTech/Services/*.swift
```

**Expected:** All these files should compile without errors:
- ✅ `SupabaseService.swift`
- ✅ `SupabaseAuthService.swift`
- ✅ `SupabaseConfig.swift`
- ✅ `CustomerSyncer.swift`
- ✅ `EmployeeSyncer.swift`
- ✅ `TicketSyncer.swift`
- ✅ `InventorySyncer.swift`

---

## 🆘 If Nothing Works

### Nuclear Option: Re-add from Scratch

1. **Close Xcode**
2. **Remove all package references:**
   ```bash
   rm -rf ~/Library/Caches/org.swift.swiftpm
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   rm -rf .swiftpm/
   rm -rf build/
   rm ProTech.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
   ```

3. **Open Xcode**
4. **Add package manually:**
   - File → Add Package Dependencies...
   - Search: `https://github.com/supabase-community/supabase-swift`
   - Version: Up to Next Major 2.34.0
   - Add to target: ProTech
   - Click Add Package

5. **Wait for download** (may take a few minutes)
6. **Build**

---

## 📊 Package Details

**Current Configuration:**
- **Package:** supabase-swift
- **Version:** 2.34.0
- **Repository:** https://github.com/supabase-community/supabase-swift
- **Product Used:** Supabase

**Dependencies (automatically included):**
- swift-crypto
- swift-http-types
- swift-clocks
- swift-concurrency-extras
- xctest-dynamic-overlay

All dependencies are already resolved in your `Package.resolved` file.

---

## 🎯 TL;DR

**Quick fix in Xcode:**
1. File → Packages → Reset Package Caches
2. File → Packages → Resolve Package Versions
3. Clean Build Folder (⌘⇧K)
4. Build (⌘B)

**If that fails, run:**
```bash
./fix_packages.sh
```

The package is already configured - Xcode just needs to re-link it after the derived data cleanup.
