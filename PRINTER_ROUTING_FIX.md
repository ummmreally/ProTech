# Printer Routing Fix - Check-In Process

## Issue Fixed

**Problem:** During customer check-in, both the Dymo device label and the service agreement were trying to print to whichever printer was set as default, potentially sending paper documents to the label printer or labels to the paper printer.

**User Request:** "Make sure that the dymo label goes to the dymo printer and the agreement goes to the actual printer when checking in the customer."

## Solution

Implemented intelligent printer routing in `DymoPrintService.swift` to ensure:
- **Device labels** → Dymo label printer (automatically detected)
- **Service agreements** → Standard paper printer (excludes label printers)

## Changes Made

### 1. Added Standard Printer Detection

**New Method:** `findStandardPrinter()`

```swift
/// Find a standard paper printer (excludes Dymo label printers)
private func findStandardPrinter() -> NSPrinter? {
    let printers = NSPrinter.printerNames
    
    // Patterns to exclude (label printers)
    let excludePatterns = ["dymo", "labelwriter", "label writer", "lw", "brother ql", "zebra"]
    
    // Find first printer that's NOT a label printer
    for printerName in printers {
        let nameLowercase = printerName.lowercased()
        var isLabelPrinter = false
        
        for pattern in excludePatterns {
            if nameLowercase.contains(pattern) {
                isLabelPrinter = true
                break
            }
        }
        
        // If not a label printer, use it
        if !isLabelPrinter {
            return NSPrinter(name: printerName)
        }
    }
    
    return nil // Falls back to system default
}
```

**Excluded Patterns:**
- `dymo` - DYMO LabelWriter series
- `labelwriter` / `label writer` - Alternative DYMO naming
- `lw` - DYMO LW abbreviation
- `brother ql` - Brother label printers
- `zebra` - Zebra label printers

### 2. Updated Document Printing

**Modified:** `printDocument()` method

**Before:**
```swift
// Create print info (used system default printer)
let printInfo = NSPrintInfo()
// ... no printer selection ...
```

**After:**
```swift
// Create print info
let printInfo = NSPrintInfo()

// IMPORTANT: Set a standard paper printer (not Dymo)
if let standardPrinter = self.findStandardPrinter() {
    printInfo.printer = standardPrinter
    print("📄 Routing document '\(title)' to standard printer: \(standardPrinter.name)")
} else {
    print("⚠️ No standard printer found, using default")
}
```

### 3. Enhanced Logging

Added console logging for debugging printer routing:
- 🏷️ `Routing label to Dymo printer: [name]`
- 📄 `Routing document to standard printer: [name]`
- ⚠️ `No Dymo/standard printer found`

## How It Works

### Check-In Print Flow

When user completes check-in and clicks "Print & Continue":

**1. Device Label (Dymo)**
```
CheckInPrintDialog.printDocuments()
  ↓
DymoPrintService.printDeviceLabel()
  ↓
printLabel() [calls findDymoPrinter()]
  ↓
🏷️ Routes to: Dymo LabelWriter 450
```

**2. Service Agreement (Paper)**
```
CheckInPrintDialog.printDocuments()
  ↓
DymoPrintService.printCheckInAgreement()
  ↓
printDocument() [calls findStandardPrinter()]
  ↓
📄 Routes to: HP LaserJet Pro (or other standard printer)
```

## Printer Selection Priority

### For Labels (Dymo)
1. Search for printer matching: `dymo`, `labelwriter`, `lw`
2. If found → Set as target printer
3. If not found → Show print panel for manual selection

### For Documents (Standard)
1. Search for printer NOT matching label patterns
2. If found → Set as target printer
3. If not found → Use system default printer

## User Experience

### Best Case (Both Printers Available)
1. User clicks "Print & Continue"
2. **Device Label** → Prints automatically to Dymo
3. **Agreement** → Prints automatically to paper printer
4. Print panels show with correct printers pre-selected
5. User can verify/change if needed

### Edge Case (Only Dymo Available)
1. Device Label → Routes to Dymo ✅
2. Agreement → Falls back to system default (might be Dymo)
3. Print panel allows user to change printer

### Edge Case (No Dymo Available)
1. Device Label → Shows print panel for manual selection
2. Agreement → Routes to available standard printer ✅
3. User must select Dymo manually for labels

## Testing Instructions

### Setup
1. Connect both Dymo label printer and standard paper printer
2. Note the printer names in System Preferences

### Test 1: Normal Check-In
1. Navigate to Queue → Check In Customer
2. Complete check-in form
3. Click "Print & Continue"
4. **Verify Console Logs:**
   ```
   🏷️ Routing label to Dymo printer: DYMO LabelWriter 450
   📄 Routing document to standard printer: HP LaserJet Pro
   ```
5. **Verify Print Panels:**
   - First panel: Device tag with Dymo selected
   - Second panel: Agreement with paper printer selected
6. Let both print
7. **Verify Output:**
   - Device tag on 1.125" × 3.5" label
   - Agreement on 8.5" × 11" paper

### Test 2: Only Dymo Connected
1. Disconnect/disable standard printers
2. Complete check-in
3. **Expected Behavior:**
   - Label routes to Dymo correctly
   - Agreement falls back to system default
   - Print panel shows for manual correction

### Test 3: Only Standard Printer
1. Disconnect/disable Dymo
2. Complete check-in
3. **Expected Behavior:**
   - Label print panel allows manual selection
   - Agreement routes to paper printer
   - Warning in console about missing Dymo

### Test 4: Dymo as Default Printer
1. Set Dymo as system default printer
2. Complete check-in
3. **Expected Behavior:**
   - Label still goes to Dymo ✅
   - Agreement finds different standard printer ✅
   - No documents sent to label printer

## Console Log Examples

### Successful Routing
```
🏷️ Found Dymo printer: DYMO LabelWriter 450
🏷️ Routing label to Dymo printer: DYMO LabelWriter 450
🖨️ Found standard printer: HP LaserJet Pro MFP M428fdw
📄 Routing document 'Service Agreement' to standard printer: HP LaserJet Pro MFP M428fdw
```

### Missing Printers
```
⚠️ No Dymo printer found. Available printers: HP LaserJet Pro, Canon PIXMA
⚠️ No standard printer found, using default for document 'Service Agreement'
```

### Label Printer as Default
```
🏷️ Found Dymo printer: DYMO LabelWriter 450
🖨️ Found standard printer: Canon PIXMA TS6420
📄 Routing document 'Service Agreement' to standard printer: Canon PIXMA TS6420
```

## Configuration

### Adding More Label Printer Patterns

If you use other label printers, add patterns to `findStandardPrinter()`:

```swift
let excludePatterns = [
    "dymo", "labelwriter", "label writer", "lw",
    "brother ql",           // Brother label printers
    "zebra",                // Zebra label printers
    "rollo",                // Add Rollo
    "munbyn",               // Add MUNBYN
    "phomemo"               // Add PHOMEMO
]
```

### Forcing Specific Printers

To always use specific printer names:

```swift
// In findStandardPrinter(), add preferred printer check
if let preferredPrinter = NSPrinter(name: "Office HP Printer") {
    return preferredPrinter
}
```

## Files Modified

**Single File Changed:**
- `/ProTech/Services/DymoPrintService.swift`
  - Added `findStandardPrinter()` method (lines 682-710)
  - Modified `printDocument()` to use standard printer (lines 596-603)
  - Enhanced logging in `printLabel()` (lines 560-565)

## Related Files

These files call the print service but don't need changes:
- `/ProTech/Views/Queue/CheckInPrintDialog.swift` (calls print methods)
- `/ProTech/Views/Queue/CheckInCustomerView.swift` (shows print dialog)

## Known Limitations

1. **Print Panel Always Shows:** Users always see print panels to verify/change printers. This is by design for safety.

2. **Pattern-Based Detection:** Uses name patterns to identify printers. Custom/unusual printer names might not be detected correctly.

3. **First Match:** Uses first non-label printer found. If you have multiple paper printers, it may not choose your preferred one.

4. **No Printer Preferences:** No UI to set preferred printers. Detection is automatic based on naming.

## Future Enhancements

Possible improvements:
- [ ] Add printer preferences in Settings
- [ ] Remember last used printers per job type
- [ ] Option to disable print panel (auto-print)
- [ ] Printer configuration UI
- [ ] Support for network printer discovery
- [ ] Printer status checking before routing

---

**Fixed Date:** November 17, 2024  
**Status:** ✅ Complete - Ready for Testing  
**Priority:** Medium (Workflow improvement)  
**Impact:** Check-in printing workflow
