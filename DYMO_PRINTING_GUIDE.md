# Dymo Label Printing - Complete Guide

## 🎯 Overview

ProTech now includes comprehensive Dymo label printing support for:
- ✅ **Product labels** (inventory items)
- ✅ **Device tags** (customer check-in/repair tickets)
- ✅ **Form printing** (completed submissions)

All printing is optimized for **Dymo LabelWriter printers** with automatic printer detection and fallback to standard printers.

---

## 📦 Supported Label Types

### 1. Product Labels (2.25" × 1.25")
**Used for**: Inventory items, retail products, parts

**Contents**:
```
━━━━━━━━━━━━━━━━━━━━━━━━
ProTech
━━━━━━━━━━━━━━━━━━━━━━━━

iPhone 14 Pro Screen

SKU: IP14-SCR-001
Price: $199.99
Stock: 15

███▌███▌███▌███
IP14-SCR-001
━━━━━━━━━━━━━━━━━━━━━━━━
```

### 2. Device Tags (2.25" × 1.25")
**Used for**: Customer devices during check-in/repair

**Contents**:
```
━━━━━━━━━━━━━━━━━━━━━━━━
ProTech
DEVICE TAG
━━━━━━━━━━━━━━━━━━━━━━━━

Ticket #00123

Customer: John Smith
Device: iPhone 14 Pro

Issue:
Cracked screen, not charging

Date In: Jan 15, 1:30 PM

⚠️ DO NOT REMOVE TAG ⚠️
━━━━━━━━━━━━━━━━━━━━━━━━
```

### 3. Form Documents (8.5" × 11")
**Used for**: Completed form submissions

**Contents**:
```
═══════════════════════════════════
ProTech
Repair Authorization Form
═══════════════════════════════════

Customer: Jane Doe
Submitted: January 15, 2025 2:45 PM

───────────────────────────────────

Device Type:
  iPhone 14 Pro

Issue Description:
  Screen cracked after drop

Estimated Cost:
  $199.99

Customer Signature:
  [Signature]

───────────────────────────────────
Signature: _____________________

Date: __________________________
═══════════════════════════════════
```

---

## 🖨️ Printer Setup

### Compatible Dymo Printers

**Tested Models**:
- Dymo LabelWriter 450
- Dymo LabelWriter 450 Turbo
- Dymo LabelWriter 4XL
- Dymo LabelWriter 550
- Dymo LabelWriter 550 Turbo

### macOS Setup

#### 1. Install Dymo Software
1. Download **Dymo Connect** from: https://www.dymo.com/support
2. Install the software
3. Connect your Dymo printer via USB
4. Open **Dymo Connect** to verify printer is recognized

#### 2. Add Printer to macOS
1. Open **System Settings** → **Printers & Scanners**
2. Click **"+"** to add printer
3. Select your Dymo LabelWriter
4. Click **"Add"**

#### 3. Verify in ProTech
1. Open **ProTech**
2. Go to **Inventory** → Click **"Print Labels"** menu
3. Click **"Print with Options..."**
4. Check if **"Dymo Printer Found"** appears (green)

---

## 📍 Where to Print

### Inventory / Product Labels

#### Method 1: From Inventory List
1. Go to **Inventory** tab
2. **Right-click** on any product
3. Select **"Print Label"** from context menu
4. ✅ Label prints immediately

#### Method 2: From Product Details
1. Go to **Inventory** tab
2. Click on a product to open details
3. Click **"Print Label"** button in toolbar
4. ✅ Label prints immediately

#### Method 3: Batch Print (Multiple Labels)
1. Go to **Inventory** tab
2. **Filter** products (optional - by category, low stock, search, etc.)
3. Click **"Print Labels"** menu in toolbar
4. Choose:
   - **"Print All Visible"** - Prints 1 label per visible item
   - **"Print with Options..."** - Opens batch dialog

**Batch Print Dialog**:
- Set **copies per product** (1-10)
- See **total labels** count
- Printer status indicator
- Click **"Print"** to start

**Example**:
```
Filtered products: 15 items
Copies per product: 2
Total labels printed: 30
```

---

### Device Tags (Check-In/Repair)

#### Method 1: From Ticket Details
1. Go to **Queue** tab
2. Click on any ticket to open details
3. Click **"Print"** menu in toolbar
4. Select **"Print Dymo Label"**
5. ✅ Device tag prints immediately

#### Method 2: During Check-In
1. Start checking in a customer (**Queue** → **New Ticket**)
2. Fill in device information
3. After saving ticket, open ticket details
4. Print label (as above)

**Best Practice**: 
- Print tag immediately after check-in
- Attach to device before storing
- Prevents mix-ups and lost devices

---

### Form Printing

#### Print Completed Forms
1. Go to **Forms** tab (Pro subscription required)
2. Click **"View Submissions"**
3. Select a submission
4. Click **"Print"** menu in toolbar
5. Choose:
   - **"Print PDF"** - Standard PDF print dialog
   - **"Print Text Version"** - Quick text-based print

**Print Options**:
- **PDF Version**: Full formatted document with signatures
- **Text Version**: Quick reference print, faster printing

---

## ⚙️ Print Settings

### Automatic Printer Detection

ProTech automatically detects Dymo printers using these patterns:
- "dymo"
- "labelwriter"
- "label writer"

**If Dymo printer found**:
- Labels auto-print to Dymo (no dialog)
- Optimized for 2.25" × 1.25" labels
- Landscape orientation

**If no Dymo found**:
- Labels sent to default printer
- Print dialog may appear
- May need manual sizing adjustment

### Manual Printer Selection

If you have multiple printers:

1. **macOS System Settings** → **Printers & Scanners**
2. Set Dymo as **default printer** (drag to top)
3. OR: Select printer in each print dialog

---

## 📋 Label Best Practices

### Product Labels

**When to Print**:
- ✅ New inventory received
- ✅ Restocking products
- ✅ Retail display items
- ✅ Parts organization

**Placement**:
- Stick on product packaging
- Attach to storage bins
- Label shelf edges
- Tag individual items

**Recommended Workflow**:
1. Receive new inventory
2. Add to ProTech inventory
3. Batch print labels for new items
4. Apply labels before shelving

### Device Tags

**When to Print**:
- ✅ **ALWAYS** print during check-in
- ✅ Before device goes to repair area
- ✅ When device changes location

**Placement**:
- Attach directly to device (if safe)
- Attach to device case/bag
- Include with device in storage bin

**Critical Info on Tag**:
- Ticket number (for tracking)
- Customer name (for identification)
- Device type/model (to prevent mix-ups)
- Issue description (technician reference)
- Date received (for SLA tracking)

**⚠️ Important**: Never store device without tag!

### Form Printing

**When to Print**:
- Customer wants physical copy
- Legal documentation required
- Filing in physical records
- Signature verification needed

**Storage**:
- File with customer records
- Keep PDF in ProTech (searchable)
- Print only when necessary (eco-friendly)

---

## 🔧 Troubleshooting

### Printer Not Detected

**Problem**: "No Dymo Printer Detected" message

**Solutions**:
1. **Check USB connection**
   - Reconnect USB cable
   - Try different USB port
   - Restart printer

2. **Verify macOS recognizes printer**
   - System Settings → Printers & Scanners
   - Printer should appear in list
   - Try printing a test page

3. **Reinstall Dymo software**
   - Uninstall Dymo Connect
   - Restart Mac
   - Reinstall Dymo Connect
   - Restart Mac again

4. **Check printer name**
   - System Settings → Printers & Scanners
   - Right-click printer → Rename
   - Ensure name contains "Dymo" or "LabelWriter"

### Labels Not Printing

**Problem**: Click print but nothing happens

**Solutions**:
1. **Check printer status**
   - Is printer powered on?
   - Any error lights blinking?
   - Paper loaded correctly?

2. **Check print queue**
   - System Settings → Printers & Scanners
   - Select printer → Open Print Queue
   - Clear any stuck jobs

3. **Test with Dymo Connect**
   - Open Dymo Connect software
   - Print a test label
   - If works: ProTech will work too

### Wrong Label Size

**Problem**: Labels print too large/small

**Solutions**:
1. **Use correct label size**
   - ProTech expects: 2.25" × 1.25"
   - Dymo part #: 30252
   - Load correct labels in printer

2. **Adjust printer settings**
   - System Settings → Printers & Scanners
   - Select printer → Options & Supplies
   - Set paper size to match your labels

### Text Cut Off

**Problem**: Some text doesn't fit on label

**Solutions**:
1. **Shorten product names**
   - Edit product in inventory
   - Use abbreviations
   - Keep names under 30 characters

2. **Shorten descriptions**
   - Keep issue descriptions concise
   - Key information only

---

## 💡 Tips & Tricks

### Inventory Management

**Tip 1: Pre-print Common Items**
- Filter by **category** (e.g., "Screens")
- Print **2 copies** of each
- Keep extras for quick restocking

**Tip 2: Low Stock Labels**
- Filter **"Low Stock Only"**
- Batch print for reorder
- Attach to reorder request

**Tip 3: New Arrivals**
- Filter by recent additions
- Print immediately after adding
- Prevents backlog

### Workflow Optimization

**Check-In Station Setup**:
1. Keep Dymo printer at check-in desk
2. Print tag immediately after creating ticket
3. Hand device + tag to technician together
4. No devices lost!

**Receiving Area**:
1. Dymo printer at receiving dock
2. Add to inventory on delivery
3. Print labels on the spot
4. Stock with labels already attached

**Retail Display**:
1. Print labels for display items
2. Include price prominently
3. Update prices → reprint labels
4. Keep professional appearance

### Label Organization

**Color-Code by Category** (using colored labels):
- Blue: Screens & Displays
- Green: Batteries
- Yellow: Cameras
- Red: Repair Tools
- White: General parts

**Create Location Labels**:
- Print blank labels with location codes
- "Shelf A1", "Bin B3", etc.
- Helps locate inventory faster

---

## 📊 Cost Analysis

### Label Costs

**Dymo Labels (30252 - 2.25" × 1.25")**:
- Roll of 500: ~$20
- Per label: $0.04

**Monthly Usage Example**:
- 50 products labeled: $2.00
- 100 device tags: $4.00
- **Total/month**: ~$6.00

**Benefits**:
- Reduced errors
- Faster workflows
- Professional appearance
- Time saved > cost

---

## 🎓 Training Staff

### Quick Training Guide

**New Employee Checklist**:
- [ ] Show how to print product labels
- [ ] Demonstrate device tag printing
- [ ] Practice batch printing
- [ ] Explain tag placement
- [ ] Review troubleshooting steps

**Training Script**:
```
1. "When you check in a device, always print a tag"
2. "Right-click any inventory item to print its label"
3. "For multiple labels, use Print Labels → Print with Options"
4. "If printer is offline, let manager know immediately"
5. "Never skip the device tag - it prevents mix-ups"
```

---

## 📱 Integration Points

### Automatic Print Triggers (Future Enhancement)

**Potential automations**:
- Auto-print on inventory receive
- Auto-print device tag on check-in save
- Auto-print form after signature
- Batch print at end of day

**Not currently implemented** - manual printing only.

---

## 🔍 Advanced Features

### Barcode Generation

Product labels include **text-based barcodes**:
```
███▌███▌███▌███
SKU-123-456
```

**For scanning barcodes**:
- Upgrade to Dymo LabelWriter 4XL
- Use proper barcode labels
- Integrate barcode scanner
- See: BARCODE_INTEGRATION_GUIDE.md

### Custom Label Templates

**Current templates are fixed**. For custom layouts:
1. Modify `DymoPrintService.swift`
2. Edit `generateProductLabelContent()`
3. Adjust text formatting
4. Test print

---

## ✅ Quick Reference

### Print Product Label
```
Inventory → Right-click item → Print Label
OR
Inventory → Open item → Toolbar → Print Label
```

### Batch Print Labels
```
Inventory → Print Labels menu → Print with Options
Set copies → Click Print
```

### Print Device Tag
```
Queue → Open ticket → Print menu → Print Dymo Label
```

### Print Form
```
Forms → View Submissions → Select form → Print menu
```

---

## 🆘 Support

### Common Questions

**Q: Can I use other label printers?**
A: Yes, labels will print to any printer, but optimized for Dymo.

**Q: What if I don't have a Dymo printer?**
A: Labels still print - just select your printer and adjust paper size.

**Q: Can I print to regular paper?**
A: Yes, but use PDF forms instead for standard 8.5×11" paper.

**Q: Do I need special labels?**
A: Dymo 30252 (Address labels) recommended for best results.

**Q: Can I change what's on the label?**
A: Currently no - requires code changes in DymoPrintService.

---

## 🎉 You're Ready!

Your ProTech system now has complete label printing:

✅ Product labels for inventory
✅ Device tags for check-in
✅ Form printing for submissions
✅ Batch printing capabilities
✅ Automatic printer detection

**Start printing professional labels today!**

---

**Questions or need help?** Check troubleshooting section above or contact support.
