# CloudKit Sync - Quick Reference Card

## 🚀 One-Time Setup (5 minutes)

### In Xcode:
1. Select ProTech target → **Signing & Capabilities**
2. Click **+ Capability** → Add **iCloud**
3. Check **CloudKit** box
4. Add container: `iCloud.com.protech.app`
5. Build & Run

### On Each Device:
- Sign into iCloud in System Settings
- Install & launch ProTech app
- Wait 30-60 seconds for initial sync
- Log in with employee PIN

---

## ✅ What Syncs Automatically
- ✅ Customers, Tickets, Repairs
- ✅ Inventory, Orders, Suppliers
- ✅ Invoices, Estimates, Payments
- ✅ Employees (including PINs)
- ✅ Appointments, Time Entries
- ✅ Forms, Campaigns, Everything!

---

## 👥 How Employee PINs Work

### Adding New Employee
1. Add employee on **any device**
2. Set their PIN code
3. **Wait 30 seconds** for sync
4. Employee can now log in on **all devices** with same PIN

### Login Behavior
- Each employee logs in separately on each device
- Login stays active until logout
- No changes to existing PIN login flow

---

## 🔄 Sync Speed

| Action | Sync Time |
|--------|-----------|
| Add customer | 5-15 seconds |
| Update ticket | 5-15 seconds |
| Large data batch | 30-60 seconds |
| Initial sync (new device) | 1-3 minutes |

---

## 🛠️ Quick Troubleshooting

### Sync Not Working?
```
1. Check: System Settings → iCloud (signed in?)
2. Check: Internet connection active?
3. Check: Same iCloud account on all devices?
4. Try: Quit and relaunch app
```

### How to Force Sync
```
1. Quit ProTech completely (Cmd+Q)
2. Wait 10 seconds
3. Relaunch app
4. Wait 30-60 seconds
```

### Check Sync Status (in Xcode Console)
```
Look for messages like:
✅ "CloudKit sync event: export"
✅ "CloudKit sync event: import"
❌ "CloudKit sync error: [message]"
```

---

## 💾 Storage

**Free:** 1GB iCloud storage (plenty for years of data)  
**Upgrade:** $0.99/month for 50GB if needed

---

## 🔒 Security

- ✅ End-to-end encrypted
- ✅ Apple's secure iCloud infrastructure
- ✅ Only accessible by devices with same iCloud account
- ✅ Employee PINs sync securely

---

## 📱 Adding New Device

**Simple 3-Step Process:**

1. **Sign in** to iCloud on new Mac
2. **Install** ProTech app
3. **Launch** → data syncs automatically (wait 1-2 min)

Done! Employees can log in with existing PINs.

---

## ⚠️ Important Notes

- **Same iCloud account required** on all devices
- **Internet required** for sync (app works offline, syncs later)
- **Deletions sync** - be careful when deleting records
- **First sync longest** - subsequent syncs are instant

---

## 🎯 Best Practices

✅ **DO:**
- Keep all devices on same iCloud account
- Ensure internet connectivity
- Wait for initial sync to complete before heavy use
- Test on 2 devices before deploying to more

❌ **DON'T:**
- Use different iCloud accounts
- Delete app data without backing up
- Make large changes while offline (sync later)

---

## 📞 Need Help?

1. **Check Console logs** in Xcode for sync errors
2. **Review** CLOUDKIT_SYNC_SETUP.md for detailed guide
3. **Verify** all devices signed into same iCloud account

---

## ✨ That's It!

Your multi-device sync is ready. Employees use their PINs as normal, and all data stays perfectly synchronized across all Macs.
