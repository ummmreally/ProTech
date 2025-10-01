#!/bin/bash

# ProTech Setup Verification Script
# Run this to check if everything is ready

echo "🔍 ProTech Setup Verification"
echo "=============================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check counters
PASS=0
FAIL=0
WARN=0

# Function to check file exists
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $2"
        ((PASS++))
    else
        echo -e "${RED}✗${NC} $2"
        ((FAIL++))
    fi
}

# Function to check directory exists
check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓${NC} $2"
        ((PASS++))
    else
        echo -e "${RED}✗${NC} $2"
        ((FAIL++))
    fi
}

# Function to check file does NOT exist (should be deleted)
check_not_exists() {
    if [ ! -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $2 (correctly deleted)"
        ((PASS++))
    else
        echo -e "${YELLOW}⚠${NC} $2 (should be deleted)"
        ((WARN++))
    fi
}

# Function to count files
count_files() {
    count=$(find "$1" -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')
    echo -e "${GREEN}✓${NC} $2: $count files"
}

echo "📁 Project Structure"
echo "-------------------"
check_file "ProTech.xcodeproj/project.pbxproj" "Xcode project exists"
check_dir "ProTech" "ProTech source folder exists"
echo ""

echo "🗑️  Old Files Removed"
echo "--------------------"
check_not_exists "ProTech/ContentView.swift" "Old ContentView.swift"
check_not_exists "ProTech/Persistence.swift" "Old Persistence.swift"
echo ""

echo "📱 Core App Files"
echo "----------------"
check_file "ProTech/ProTechApp.swift" "ProTechApp.swift (updated)"
check_file "ProTech/App/Configuration.swift" "Configuration.swift"
echo ""

echo "⚙️  Services"
echo "----------"
check_file "ProTech/Services/CoreDataManager.swift" "CoreDataManager.swift"
check_file "ProTech/Services/TwilioService.swift" "TwilioService.swift"
check_file "ProTech/Services/SubscriptionManager.swift" "SubscriptionManager.swift"
check_file "ProTech/Services/FormService.swift" "FormService.swift"
echo ""

echo "🔒 Utilities"
echo "-----------"
check_file "ProTech/Utilities/SecureStorage.swift" "SecureStorage.swift"
echo ""

echo "🎨 Views"
echo "-------"
count_files "ProTech/Views" "View files"
check_dir "ProTech/Views/Main" "Main views"
check_dir "ProTech/Views/Customers" "Customer views"
check_dir "ProTech/Views/Settings" "Settings views"
check_dir "ProTech/Views/Forms" "Forms views"
check_dir "ProTech/Views/SMS" "SMS views"
check_dir "ProTech/Views/Reports" "Reports views"
check_dir "ProTech/Views/Onboarding" "Onboarding views"
echo ""

echo "💾 Core Data"
echo "-----------"
check_file "ProTech/ProTech.xcdatamodeld/ProTech.xcdatamodel/contents" "Core Data model file"
echo -e "${YELLOW}⚠${NC}  Core Data entities must be configured manually in Xcode"
echo ""

echo "📦 Resources"
echo "-----------"
check_dir "ProTech/Assets.xcassets" "Assets catalog"
check_file "ProTech/ProTech.entitlements" "Entitlements file"
echo ""

echo "📚 Documentation"
echo "---------------"
check_file "../PROJECT_PLAN.md" "Project plan"
check_file "../XCODE_SETUP_GUIDE.md" "Xcode setup guide"
check_file "../APP_STORE_CHECKLIST.md" "App Store checklist"
check_file "../TWILIO_INTEGRATION_GUIDE.md" "Twilio integration guide"
check_file "../FORMS_SYSTEM_GUIDE.md" "Forms system guide"
check_file "SETUP_INSTRUCTIONS.md" "Setup instructions"
check_file "XCODE_STEPS.md" "Xcode steps guide"
check_file "README.md" "Project README"
echo ""

echo "=============================="
echo "📊 Summary"
echo "=============================="
echo -e "${GREEN}Passed:${NC} $PASS"
if [ $WARN -gt 0 ]; then
    echo -e "${YELLOW}Warnings:${NC} $WARN"
fi
if [ $FAIL -gt 0 ]; then
    echo -e "${RED}Failed:${NC} $FAIL"
fi
echo ""

if [ $FAIL -eq 0 ] && [ $WARN -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed! Ready for Xcode setup.${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Open ProTech.xcodeproj in Xcode"
    echo "2. Configure Core Data entities (see XCODE_STEPS.md)"
    echo "3. Add capabilities (iCloud, In-App Purchase)"
    echo "4. Build and run (⌘R)"
elif [ $FAIL -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Setup mostly complete with warnings.${NC}"
    echo ""
    echo "Please review warnings above and follow XCODE_STEPS.md"
else
    echo -e "${RED}❌ Setup incomplete. Please check failed items above.${NC}"
    echo ""
    echo "Run the migration again or check SETUP_INSTRUCTIONS.md"
fi

echo ""
echo "📖 For detailed instructions, see:"
echo "   - XCODE_STEPS.md (step-by-step Xcode setup)"
echo "   - SETUP_INSTRUCTIONS.md (complete guide)"
echo ""
