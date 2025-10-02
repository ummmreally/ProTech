# Forms System - Quick Reference Guide

## 🎯 Quick Start

### Load Default Templates
```swift
FormService.shared.loadDefaultTemplates()
```

### Create New Custom Form
1. Navigate to Forms
2. Click "New Form"
3. Add fields via "Add Field" button
4. Configure field properties
5. Save

### Fill Intake Form
1. From customer view → "Create Intake Form"
2. Fill required fields (*)
3. Capture signature
4. Submit or Submit & Print

### Fill Pickup Form
1. From ticket view → "Device Pickup"
2. Document work performed
3. Capture signature
4. Complete or Complete & Print

### View Submissions
1. Forms → "View Submissions"
2. Click submission to view
3. Print or Export PDF

---

## 🔧 Print Functionality

### Print from Submission View
```swift
FormSubmissionView(submission: submission, template: template)
// Built-in Print button in toolbar
```

### Print Directly
```swift
FormService.shared.printFormDirectly(
    submission: submission,
    template: template
)
```

### Generate PDF Only
```swift
let pdf = FormService.shared.generatePDF(
    submission: submission,
    template: template
)
```

### Save PDF to File
```swift
FormService.shared.savePDF(
    pdfDocument: pdf,
    to: url
)
```

---

## 📝 Field Types

| Type | Icon | Description |
|------|------|-------------|
| text | textformat | Single line text |
| textarea | text.alignleft | Multi-line text |
| number | number | Numeric input |
| date | calendar | Date picker |
| checkbox | checkmark.square | Single checkbox |
| dropdown | chevron.down.circle | Select from list |
| radio | circle.circle | Single selection |
| signature | signature | Digital signature |
| header | textformat.size | Section title |
| divider | minus | Horizontal line |

---

## 🎨 Customization

### Company Branding
Set in form template:
- `companyName` - Appears at top
- `headerText` - Form subtitle
- `footerText` - Appears at bottom

### Field Properties
- `label` - Field label (required)
- `placeholder` - Hint text
- `required` - Is field mandatory?
- `defaultValue` - Pre-filled value
- `options` - List for dropdown/radio
- `rows` - Height for textarea

---

## 💾 Data Structure

### FormTemplate
```swift
{
    "id": "uuid",
    "name": "Form Name",
    "type": "intake|pickup|custom",
    "companyName": "Your Company",
    "headerText": "Form Title",
    "footerText": "Thank you",
    "fields": [FormField]
}
```

### FormField
```swift
{
    "id": "field_id",
    "type": "text",
    "label": "Field Label",
    "required": true,
    "placeholder": "Enter text",
    "options": ["Option 1", "Option 2"]
}
```

### FormSubmission
```swift
{
    "id": UUID,
    "formID": UUID,
    "dataJSON": "{...}",
    "signatureData": Data,
    "submittedAt": Date
}
```

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘N | New form template |
| ⌘S | Save form |
| ⌘P | Print form |
| ⌘W | Close window |
| Esc | Cancel/Close |

---

## 🔍 Common Tasks

### Duplicate Template
```swift
// Right-click template → "Duplicate"
// Or programmatically:
let duplicate = FormTemplate(context: context)
duplicate.id = UUID()
duplicate.name = "\(original.name) (Copy)"
duplicate.templateJSON = original.templateJSON
CoreDataManager.shared.save()
```

### Delete Template
```swift
// Right-click template → "Delete"
// Or programmatically:
context.delete(template)
CoreDataManager.shared.save()
```

### Find Template by Type
```swift
let request = FormTemplate.fetchRequest()
request.predicate = NSPredicate(
    format: "type == %@ AND isDefault == true",
    "intake"
)
let template = try? context.fetch(request).first
```

---

## 🐛 Troubleshooting

### PDF Not Generating
- Check template has valid JSON
- Verify submission has data
- Ensure signature data exists if required

### Print Not Working
- Verify macOS printing entitlement
- Check printer is available
- Ensure PDF document exists

### Signature Not Displaying
- Signature must be captured before submit
- Check signatureData is not nil
- Verify image data is valid

### Form Not Saving
- All required fields must be filled
- Customer signature required
- Terms must be agreed to

---

## 📊 Default Templates

### Intake Form Fields
1. Customer Name *
2. Phone Number *
3. Email Address
4. Device Type *
5. Device Model
6. Serial Number
7. Issue Description *
8. Terms Agreement *
9. Customer Signature *

### Pickup Form Fields
1. Customer Name *
2. Work Performed *
3. Parts Used
4. Total Cost *
5. Warranty Period
6. Customer Signature *

(\* = Required field)

---

## 🎓 Best Practices

### Form Design
- ✅ Use clear, concise labels
- ✅ Group related fields with headers
- ✅ Mark required fields clearly
- ✅ Add dividers for visual separation
- ✅ Keep forms as short as possible
- ✅ Use appropriate field types

### Printing
- ✅ Preview before printing
- ✅ Check printer settings
- ✅ Use high-quality paper for signatures
- ✅ Keep printed forms organized
- ✅ Store PDFs as backup

### Signatures
- ✅ Use tablet/stylus for best quality
- ✅ Ask customer to sign clearly
- ✅ Verify signature before submit
- ✅ Re-capture if unclear
- ✅ Explain legal implications

---

## 🔐 Security & Privacy

- ✅ Signatures stored locally in Core Data
- ✅ No cloud uploads unless enabled
- ✅ PDF data encrypted at rest
- ✅ Access controlled by macOS permissions
- ✅ Data can be exported/backed up

---

## 📱 Integration Points

### With Tickets
- Intake form creates/updates ticket
- Pickup form closes ticket
- Form data stored in ticket notes
- Form ID linked to ticket

### With Customers
- Forms pre-filled with customer data
- Form submissions linked to customer
- Customer signature captured
- Contact info validated

### With Notifications
- Email PDF after completion
- SMS pickup notification
- Signature confirmation
- Review request after pickup

---

## 🚀 Performance Tips

- Use lazy loading for large form lists
- Cache PDF generation
- Optimize signature image size
- Batch print multiple forms
- Index Core Data properly

---

## 📞 Support

For issues or questions:
- Check FORMS_SYSTEM_GUIDE.md
- See FORMS_IMPLEMENTATION_COMPLETE.md
- Review code comments
- Test with sample data

---

**Quick Reference v1.0**  
**Last Updated:** October 1, 2025
