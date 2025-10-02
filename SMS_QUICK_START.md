# SMS Quick Start Guide

## 🚀 Getting Started with SMS Notifications

### Prerequisites
✅ Twilio account configured in Settings → SMS  
✅ Customer has phone number in their profile  
✅ Active internet connection

---

## 📱 Sending SMS Messages

### Automatic SMS on Repair Completion

**When you mark a repair as complete, the app automatically:**

1. **Shows SMS Confirmation Modal**
   - Pre-filled with professional message
   - Includes customer name and ticket details
   
2. **You can:**
   - ✏️ Edit the message if needed
   - 📊 See character count
   - ✅ Click "Send SMS" to confirm
   - ❌ Click "Cancel" to skip

3. **After sending:**
   - Ticket status updates to "completed"
   - SMS saved to customer record
   - Modal closes automatically

---

## 💡 Where to Send SMS

### From Ticket Detail View

**When ticket is Waiting:**
- 🟡 "Notify Work Started" - Tell customer you've begun

**When ticket is In Progress:**
- 🟢 "Mark as Completed" - **Auto-shows SMS modal**

**When ticket is Completed:**
- 📧 "Send Pickup Reminder" - Resend notification
- ✉️ "Send Custom SMS" - Send any message

### From Repair Progress View

**Quick Action Button:**
- 🟢 "Mark Complete" - **Auto-shows SMS modal**

---

## 📝 Message Templates

### Ready for Pickup (Automatic)
```
Hi [Name], your iPhone repair is complete and ready 
for pickup! Ticket #1234.

Please bring this text or your ticket number when 
picking up. Thank you for choosing our service!
```

### Work Started
```
Hi [Name], we've started working on your iPhone. 
We'll notify you once it's ready for pickup. 
Thank you!
```

### Custom Message
```
Hi [Name], [your message here]
```

**💡 Tip:** You can edit any message before sending!

---

## ⚠️ Character Limits

- **Up to 160 characters** = 1 SMS segment
- **161-320 characters** = 2 SMS segments  
- **321-480 characters** = 3 SMS segments

*The modal shows segment count for long messages*

---

## 🎯 Best Practices

### ✅ DO
- Review the message before sending
- Include ticket number in pickup notifications
- Be professional and friendly
- Send pickup notifications promptly
- Use custom messages for special situations

### ❌ DON'T
- Send multiple duplicate messages
- Include sensitive payment information
- Use informal/unprofessional language
- Send messages outside business hours (if possible)

---

## 🔧 Troubleshooting

### SMS Button Not Showing?

**Check:**
1. Is Twilio configured? (Settings → SMS)
2. Does customer have phone number?
3. Is phone number valid format? (+1234567890)

### SMS Failed to Send?

**Common Causes:**
- ❌ Twilio credentials incorrect
- ❌ Phone number invalid format
- ❌ No internet connection
- ❌ Twilio account out of credit

**Fix:** Go to Settings → SMS and test connection

### Customer Didn't Receive SMS?

**Try:**
1. Check SMS logs for delivery status
2. Verify phone number is correct
3. Use "Send Pickup Reminder" to resend
4. Call customer as backup

---

## 🎓 Training Scenarios

### Scenario 1: Basic Repair Completion
1. Complete repair work
2. Click "Mark as Completed"
3. Review auto-generated message
4. Click "Send SMS"
5. ✅ Done! Customer notified.

### Scenario 2: Custom Notification
1. Open ticket detail
2. Click "Send Custom SMS"
3. Type your message
4. Click "Send SMS"
5. ✅ Done! Custom message sent.

### Scenario 3: Work Started Notification
1. Start working on repair
2. Click "Notify Work Started"
3. Review message
4. Click "Send SMS"
5. ✅ Done! Customer knows you've begun.

---

## 📊 Viewing SMS History

All sent messages are saved and linked to:
- Customer profile
- Ticket record
- SMS logs (coming soon)

---

## 🆘 Need Help?

**Contact Support:**
- Check the full SMS Integration Summary document
- Review Twilio Integration Guide
- Test Twilio connection in Settings

---

## ⌨️ Keyboard Shortcuts

- **ESC** - Close modal without sending
- **ENTER** - Send SMS (when modal is open)

---

## 🎉 Quick Win!

**Your first SMS in 3 steps:**

1. Mark any repair complete
2. Review the message
3. Click "Send SMS"

**That's it!** Your customer is now notified. 🎊

---

*For complete documentation, see SMS_INTEGRATION_SUMMARY.md*
