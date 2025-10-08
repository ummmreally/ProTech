# Kiosk Mode Implementation Guide

## Overview
Kiosk Mode transforms ProTech into a customer self-service station for walk-up customers. When enabled, the app locks to the Customer Portal, allowing customers to:
- Check in using email or phone
- Self-register if they're new customers
- View their repair status, invoices, and estimates
- Auto-logout after inactivity

## ✅ Implementation Complete

All kiosk mode features have been successfully implemented:

### Files Created
1. **KioskModeManager.swift** - Manages kiosk mode state and settings
2. **AdminUnlockView.swift** - Passcode-protected admin unlock screen
3. **CustomerSelfRegistrationView.swift** - 3-step customer registration flow
4. **KioskModeSettingsView.swift** - Configuration interface for kiosk mode

### Files Modified
1. **Extensions.swift** - Added kiosk mode notifications
2. **CustomerPortalLoginView.swift** - Added self-registration and kiosk support
3. **ContentView.swift** - Added kiosk mode enforcement
4. **SettingsView.swift** - Added Kiosk Mode settings tab

## Features

### 🔒 Kiosk Mode Lock
- Full-screen customer portal only
- No access to admin features
- Hides all navigation and sidebars

### 👤 Customer Self-Registration
- 3-step registration process:
  1. **Personal Info**: First name, last name
  2. **Contact Info**: Email, phone number
  3. **Confirmation**: Review details
- Success screen with "Please have a seat" message
- Notification sent to staff when customer registers

### 🔐 Admin Unlock
- Hidden unlock button in top-right corner
- Keyboard shortcut: **⌘⇧Q**
- Passcode-protected (default: `1234`)
- 3 attempt limit with 30-second lockout

### ⏱️ Auto-Logout Timer
- Configurable timeout (default: 5 minutes)
- Automatically logs out inactive customers
- Resets on any interaction
- Protects customer privacy

### ⚙️ Customization
- Custom welcome title
- Custom welcome message
- Configurable admin passcode
- Adjustable auto-logout duration

## Usage Guide

### Enabling Kiosk Mode

1. Open **Settings** → **Kiosk Mode**
2. Toggle **Enable Kiosk Mode**
3. Confirm the dialog
4. App will immediately lock to Customer Portal

### Customer Flow

#### Existing Customer
1. Customer walks up to kiosk
2. Selects **Email** or **Phone**
3. Enters their information
4. Accesses their portal
5. Auto-logout after 5 minutes of inactivity

#### New Customer (Self-Registration)
1. Customer walks up to kiosk
2. Enters email/phone (not found in system)
3. Sees "No account found" message
4. Clicks **Create New Profile**
5. Completes 3-step registration:
   - Name information
   - Contact details
   - Confirmation
6. Sees "Please have a seat" success screen
7. Staff receives notification
8. Customer accesses portal

### Admin Exit from Kiosk Mode

#### Method 1: Hidden Button
1. Tap the **top-right corner** of the screen
2. Enter admin passcode
3. Click **Unlock**

#### Method 2: Keyboard Shortcut
1. Press **⌘⇧Q**
2. Enter admin passcode
3. Click **Unlock**

### Configuration

Navigate to **Settings** → **Kiosk Mode** to configure:

#### Customization
- **Welcome Title**: Custom header text (default: "Welcome to ProTech")
- **Welcome Message**: Custom subtitle (default: "Please enter your phone number or email to check in")

#### Security
- **Admin Passcode**: Change the unlock code (default: `1234`)
- **Auto-logout**: Set timeout in minutes (default: 5 minutes, range: 1-30 minutes)

#### Features
- ✅ Customer self-registration enabled
- ✅ Auto-logout timer active
- ✅ Admin access via ⌘⇧Q or corner tap

## Technical Details

### Kiosk Mode Manager
`KioskModeManager.shared` manages the kiosk state using:
- **UserDefaults** for persistent settings
- **@Published** properties for reactive UI updates
- **NotificationCenter** for system-wide events

### State Persistence
All settings are saved to UserDefaults:
- `kioskModeEnabled` - Boolean
- `kioskTitle` - String
- `kioskWelcomeMessage` - String
- `kioskAdminPasscode` - String
- `kioskAutoLogoutSeconds` - Integer

### Notifications
Custom notification events:
- `.kioskModeEnabled` - Fired when kiosk mode activates
- `.kioskModeDisabled` - Fired when kiosk mode deactivates
- `.customerSelfRegistered` - Fired when new customer registers
- `.customerPortalLogout` - Fired when customer logs out

### Security Features
1. **Passcode Protection**: Admin unlock requires correct passcode
2. **Attempt Limiting**: 3 failed attempts trigger 30-second lockout
3. **Auto-Logout**: Inactive customers are automatically logged out
4. **Hidden UI**: Admin controls completely hidden in kiosk mode

## Best Practices

### Setup
1. **Set Strong Passcode**: Change from default `1234` immediately
2. **Test Workflow**: Complete full customer journey before deployment
3. **Train Staff**: Ensure team knows how to exit kiosk mode
4. **Position Tablet**: Mount at comfortable height for standing customers

### Deployment
1. **Dedicated Device**: Use a separate iPad/Mac for kiosk only
2. **Guided Access** (iOS): Enable for additional security
3. **Physical Security**: Mount or secure the device
4. **Clear Signage**: Add "Check In Here" signs

### Maintenance
1. **Monitor Registrations**: Check `.customerSelfRegistered` notifications
2. **Adjust Timeout**: Tune auto-logout based on customer behavior
3. **Update Welcome Message**: Seasonal or promotional messages
4. **Regular Testing**: Verify kiosk still functions properly

## Troubleshooting

### Can't Exit Kiosk Mode
- **Try keyboard shortcut**: ⌘⇧Q
- **Forgot passcode**: Check Settings → Kiosk Mode (if you can access it)
- **Emergency**: Restart app (kiosk mode persists, but allows brief admin access)

### Customer Can't Register
- **Check permissions**: Core Data must be accessible
- **Network**: Ensure device has connectivity
- **Validate fields**: All required fields must be filled

### Auto-Logout Not Working
- **Check settings**: Verify timeout is set correctly
- **Test inactivity**: Don't touch screen for timeout duration
- **Restart kiosk**: Toggle kiosk mode off/on

### Admin Unlock Button Not Responding
- **Location**: Top-right corner, 50x50 pixel area
- **Alternative**: Use ⌘⇧Q keyboard shortcut
- **Check state**: Ensure kiosk mode is actually enabled

## Future Enhancements

Potential additions for future versions:
- [ ] QR code check-in
- [ ] Photo ID verification
- [ ] Multiple language support
- [ ] Custom branding per location
- [ ] Analytics dashboard for kiosk usage
- [ ] Customer satisfaction survey after service
- [ ] SMS/Email verification code option
- [ ] Appointment check-in integration

## Support

For issues or questions:
1. Check this documentation
2. Review code comments in implementation files
3. Test in non-kiosk mode first
4. Contact development team

---

**Version**: 1.0  
**Last Updated**: 2025-10-07  
**Status**: ✅ Production Ready
