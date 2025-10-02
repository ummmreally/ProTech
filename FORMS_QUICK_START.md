# Forms System - Quick Start Guide

**⚡ Get started with ProTech's customizable forms in 5 minutes!**

---

## 🚀 Quick Start (3 Steps)

### Step 1: Create Your First Template (2 min)

1. **Open Forms Manager**
2. **Click "New Template"** button
3. **Fill in basic info:**
   ```
   Name: "Device Intake Form"
   Type: "Intake"
   Description: "Customer device drop-off form"
   ```
4. **Add fields** - Click "Add Field" for each:

   **Field 1:**
   - Label: "Customer Name"
   - Type: Text
   - Required: ✓

   **Field 2:**
   - Label: "Phone Number"
   - Type: Phone
   - Required: ✓

   **Field 3:**
   - Label: "Device Type"
   - Type: Dropdown
   - Required: ✓
   - Options: "iPhone", "iPad", "Mac", "Android"

   **Field 4:**
   - Label: "Issue Description"
   - Type: Multi-line Text
   - Required: ✓

   **Field 5:**
   - Label: "Customer Signature"
   - Type: Signature
   - Required: ✓

5. **Click "Save"** ✅

### Step 2: Fill Out the Form (1 min)

1. **Right-click your template** → "Fill Form"
2. **Enter submitter info** (your name/email)
3. **Fill all fields:**
   - Customer Name: "John Doe"
   - Phone: "555-1234"
   - Device: Select "iPhone"
   - Issue: "Screen cracked, needs replacement"
   - Signature: Click "Add Signature" → Draw → "Done"
4. **Click "Save Submission"** ✅

### Step 3: Print the Form (30 sec)

**Option A: Print filled form**
- After saving → Alert appears → **Click "Print"**

**Option B: Print blank form**
- Right-click template → **"Print Blank"**

**Option C: Export as PDF**
- When filling form → **Click "Export PDF"**
- Choose location → Save

**Done! You've created, filled, and printed your first form! 🎉**

---

## 🎯 Common Use Cases

### Use Case 1: Device Intake
**When:** Customer drops off device  
**Template:** Intake Form  
**Fields:**
- Customer info (name, phone, email)
- Device details (type, model, serial)
- Issue description
- Authorization signature

**Action:** Print 2 copies (one for customer, one for file)

---

### Use Case 2: Service Completion
**When:** Device ready for pickup  
**Template:** Completion Form  
**Fields:**
- Work performed
- Parts used
- Labor hours
- Total cost
- Warranty info
- Customer signature

**Action:** Print receipt for customer

---

### Use Case 3: Service Agreement
**When:** Expensive repair, need authorization  
**Template:** Agreement Form  
**Fields:**
- Service description
- Estimated cost
- Time estimate
- Terms and conditions
- Customer authorization
- Signature

**Action:** Print for legal records

---

### Use Case 4: Quality Checklist
**When:** Pre-repair inspection  
**Template:** Inspection Checklist  
**Fields:**
- Device condition (checkboxes)
- Functionality tests (yes/no)
- Cosmetic issues (checkboxes)
- Photos attached (yes/no)
- Inspector signature

**Action:** Attach to ticket

---

## ⌨️ Keyboard Shortcuts

### Forms Manager:
- **Cmd+N** - New template (coming soon)
- **Cmd+F** - Focus search
- **Delete** - Delete selected
- **Cmd+D** - Duplicate template

### Form Builder:
- **Cmd+S** - Save template
- **Cmd+W** - Cancel/Close
- **Drag** - Reorder fields

### Form Fill:
- **Tab** - Next field
- **Shift+Tab** - Previous field
- **Cmd+P** - Print (coming soon)
- **Cmd+E** - Export PDF

---

## 🎨 Field Type Cheat Sheet

| Need to capture... | Use this field type |
|--------------------|---------------------|
| Name, short text | **Text** |
| Long description | **Multi-line Text** |
| Price, quantity | **Number** |
| Email address | **Email** |
| Phone number | **Phone** |
| Date, deadline | **Date** |
| Pick one option | **Dropdown** or **Radio** |
| Pick multiple | **Checkbox** |
| Yes or No | **Yes/No** |
| Legal signature | **Signature** |

---

## 🖨️ Printing Options

### Print Blank Form
**Use when:** Need paper form for manual completion

**How:**
1. Right-click template
2. Click "Print Blank"
3. Choose printer
4. Print

**Result:** Empty form ready to fill by hand

---

### Print Filled Form
**Use when:** Need printed record of submission

**How:**
1. Fill out form completely
2. Click "Print" button
3. Choose printer
4. Print

**Result:** Form with all answers and signature

---

### Export as PDF
**Use when:** Need to email or archive

**How:**
1. Fill out form
2. Click "Export PDF"
3. Choose location
4. Save

**Result:** PDF file you can email/store

---

## 💡 Pro Tips

### Tip 1: Template Organization
📁 **Use clear naming:**
- ✅ "Device Intake - iPhone"
- ✅ "Service Agreement - $500+"
- ✅ "Pickup Receipt"
- ❌ "Form 1"
- ❌ "Template"

### Tip 2: Required Fields
✓ **Mark as required:**
- Customer identification
- Authorization signatures
- Essential information
- Legal requirements

❌ **Keep optional:**
- Secondary contact info
- Notes/comments
- Optional preferences

### Tip 3: Field Order
📝 **Logical flow:**
1. Customer info first
2. Device info next
3. Issue details
4. Additional notes
5. Signature last

### Tip 4: Dropdown Options
📋 **Keep it simple:**
- ✅ Short list (3-7 options)
- ✅ Common choices
- ✅ Include "Other"
- ❌ Too many options
- ❌ Duplicate options

### Tip 5: Signature Placement
✍️ **Always at the end:**
- Put signature field last
- Only one signature per form
- Clear label ("Customer Signature")

---

## 🔧 Troubleshooting

### Problem: Can't save template
**Solution:**
- ✓ Check name is not empty
- ✓ Add at least one field
- ✓ Ensure valid field types

### Problem: Can't submit form
**Solution:**
- ✓ Fill all required fields (marked with *)
- ✓ Add signature if required
- ✓ Enter submitter name

### Problem: Print not working
**Solution:**
- ✓ Check printer is connected
- ✓ Verify printer permissions
- ✓ Try "Export PDF" first

### Problem: Signature won't save
**Solution:**
- ✓ Draw complete signature
- ✓ Click "Done" (not "Cancel")
- ✓ Check field is marked as Signature type

---

## 📊 Field Type Examples

### Text Field
```
Label: "Device Serial Number"
Type: Text
Required: Yes
Placeholder: "C02ABC123XYZ"
```

### Multi-line Text
```
Label: "Detailed Issue Description"
Type: Multi-line Text
Required: Yes
Placeholder: "Describe the problem in detail..."
```

### Dropdown
```
Label: "Device Condition"
Type: Dropdown
Required: Yes
Options:
  - Excellent
  - Good
  - Fair
  - Poor
```

### Checkbox
```
Label: "Additional Services"
Type: Checkbox
Options:
  - Screen Protector
  - Case
  - Data Transfer
  - Software Update
```

### Signature
```
Label: "Customer Authorization"
Type: Signature
Required: Yes
```

---

## 🎯 Best Practices

### DO ✅
- Keep forms focused (one purpose)
- Use clear, simple language
- Test before deploying
- Include date/time stamps
- Save all submissions
- Print copies for customers
- Archive PDFs regularly

### DON'T ❌
- Create overly long forms
- Use technical jargon
- Skip required fields
- Forget signatures
- Delete submissions
- Use unclear labels

---

## 📁 Form Template Ideas

### Customer Forms:
- Device Intake Form
- Pickup Receipt
- Service Agreement
- Warranty Registration
- Customer Feedback

### Internal Forms:
- Quality Inspection Checklist
- Technician Report
- Inventory Check
- Daily Closing Sheet
- Safety Checklist

### Business Forms:
- Vendor Agreement
- Employee Onboarding
- Equipment Loan Form
- Donation Receipt
- Event Sign-in Sheet

---

## 🚀 Quick Actions Reference

### Create New Template
1. Forms Manager
2. "New Template" button
3. Add fields
4. Save

### Duplicate Template
1. Right-click template
2. "Duplicate"
3. Edit name
4. Modify as needed

### Fill Out Form
1. Right-click template
2. "Fill Form"
3. Complete fields
4. Save or Print

### Print Blank
1. Right-click template
2. "Print Blank"
3. Select printer

### Export PDF
1. Fill form
2. "Export PDF" button
3. Choose location

---

## ⚡ Speed Tips

### Faster Template Creation:
1. **Duplicate** existing template instead of starting from scratch
2. **Reorder** fields by dragging (no need to delete/recreate)
3. **Test** with preview before deploying

### Faster Form Filling:
1. **Tab** between fields
2. **Pre-fill** submitter info
3. **Save** frequently

### Faster Printing:
1. **Save submission** first
2. Print from success dialog
3. **Export PDF** for batch printing

---

## 📞 Need Help?

### Documentation:
- **Full Guide:** `FORMS_SYSTEM_COMPLETE.md`
- **Technical:** `FORMS_BUILD_STATUS.md`
- **This Guide:** `FORMS_QUICK_START.md`

### Common Questions:
**Q: How many templates can I create?**  
A: Unlimited! Create as many as you need.

**Q: Can I edit a template after creating it?**  
A: Yes! Right-click → "Edit"

**Q: What happens to old submissions if I change a template?**  
A: They remain unchanged. Template changes only affect new submissions.

**Q: Can I delete a template?**  
A: Yes, but submissions remain in database.

**Q: Where are PDFs saved?**  
A: You choose the location when exporting.

---

## ✅ Checklist: Your First Form

- [ ] Open Forms Manager
- [ ] Create new template
- [ ] Add 3-5 fields
- [ ] Include signature field
- [ ] Save template
- [ ] Test by filling out
- [ ] Print test copy
- [ ] Review output
- [ ] Make adjustments
- [ ] Deploy for real use

---

## 🎉 You're Ready!

**You now know how to:**
✅ Create form templates  
✅ Add all field types  
✅ Fill out forms  
✅ Capture signatures  
✅ Print forms  
✅ Export PDFs  
✅ Manage templates  

**Start creating your first form now!** 🚀

---

*ProTech Forms System - Simplifying Paperwork Since 2025* 📝
