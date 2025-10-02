# Facebook API Setup Guide for ProTech

This guide will walk you through setting up Facebook API access for posting to Facebook Pages from ProTech.

## Prerequisites

- A Facebook account
- A Facebook Page (Business Page) where you want to post
- Admin access to that Facebook Page

---

## Step 1: Create a Facebook Developer Account

1. Go to **https://developers.facebook.com**
2. Click **"Get Started"** in the top right
3. Log in with your Facebook account
4. Complete the registration process
5. Verify your email if prompted

---

## Step 2: Create a New App

1. From the Facebook Developers dashboard, click **"My Apps"** in the top right
2. Click **"Create App"**
3. Select app type:
   - Choose **"Business"** or **"Consumer"** (recommended: Business)
4. Fill in app details:
   - **App Name**: `ProTech Social Media Manager` (or your preferred name)
   - **App Contact Email**: Your business email
   - **Business Account**: Select your business account (or create one)
5. Click **"Create App"**

---

## Step 3: Add Facebook Login Product

1. From your app dashboard, find **"Add Products"** in the left sidebar
2. Locate **"Facebook Login"** and click **"Set Up"**
3. Choose **"Web"** as the platform
4. You'll see a setup wizard - you can skip the quickstart for now

---

## Step 4: Configure OAuth Settings

1. In the left sidebar, go to **Facebook Login → Settings**
2. Under **"Valid OAuth Redirect URIs"**, add exactly:
   ```
   protech://oauth/facebook
   ```
   **Important**: 
   - No spaces before or after
   - Must be exactly as shown
   - Case sensitive
3. Under **"Client OAuth Settings"**, make sure these are enabled:
   - ✅ Client OAuth Login
   - ✅ Web OAuth Login
4. Set **"Login Redirect URIs"** to the same value:
   ```
   protech://oauth/facebook
   ```
5. Scroll down and click **"Save Changes"**

---

## Step 5: Get Your App ID and App Secret

1. In the left sidebar, click **Settings → Basic**
2. You'll see:
   - **App ID**: Copy this (e.g., `123456789012345`)
   - **App Secret**: Click **"Show"** and copy it (you'll need to enter your Facebook password)
3. **IMPORTANT**: Keep the App Secret private - never share it publicly

---

## Step 6: Add Required Permissions

1. In the left sidebar, go to **App Review → Permissions and Features**
2. Request these permissions:
   - **pages_manage_posts** - Required for posting to Pages
   - **pages_read_engagement** - Required for reading post analytics
   - **pages_show_list** - Required to get list of your Pages

### For Advanced Review (if needed):
- Some permissions require Facebook app review
- You may need to submit your app for review with:
  - App description
  - Privacy policy URL
  - Terms of service URL
  - Screen recordings showing how you use the permissions

---

## Step 7: Add Your Facebook Page

### Option A: During OAuth (Recommended)
When you connect your account in ProTech, you'll be prompted to select which Page(s) to manage.

### Option B: Get Page ID Manually
1. Go to your Facebook Page
2. Click **"About"** in the left sidebar
3. Scroll down to find **"Page ID"** or **"Page Transparency"**
4. Copy the numeric Page ID

---

## Step 8: Configure App Mode

### For Testing:
1. Your app starts in **"Development Mode"**
2. This is fine for testing - you can post to your own Pages
3. Only admins, developers, and testers can use the app

### For Production (Live):
1. Complete all required fields in **Settings → Basic**:
   - Privacy Policy URL
   - App Icon
   - Business Use case
2. Go to **Settings → Advanced**
3. Switch **"App Mode"** from Development to Live
4. Click **"Switch Mode"**

**Note**: For initial testing, Development Mode is sufficient!

---

## Step 9: Add Your Credentials to ProTech

1. Open **ProTech**
2. Go to **Settings → Social Media**
3. Select the **Facebook** tab
4. Enter:
   - **App ID**: Paste your App ID
   - **App Secret**: Paste your App Secret
   - **Page ID**: (Optional - will be auto-fetched during OAuth)
5. Click **"Save Credentials"**
6. Click **"Connect Account"**
7. Authorize the app to access your Facebook Page

---

## Troubleshooting

### "Invalid OAuth Redirect URI"
- Make sure `protech://oauth/facebook` is added in **Facebook Login → Settings → Valid OAuth Redirect URIs**
- Save changes and try again

### "App Not Set Up for Login"
- Ensure Facebook Login product is added to your app
- Check that OAuth settings are configured

### "Permission Denied"
- Make sure you're an admin of the Facebook Page
- Check that you've granted all requested permissions during OAuth
- Verify app is not restricted

### "This App is in Development Mode"
- This is normal for testing
- Add yourself as a developer/tester in **Roles → Roles**
- Or switch to Live mode (see Step 8)

### Cannot Post to Page
- Verify the Page ID is correct
- Ensure `pages_manage_posts` permission is granted
- Check that your access token hasn't expired (ProTech handles refresh)

---

## Testing Your Integration

1. In ProTech, go to **Marketing → Social Media Manager**
2. Create a test post
3. Select **Facebook** as the platform
4. Click **"Post to 1 Platform(s)"**
5. Check your Facebook Page to verify the post appears

---

## Important Notes

### Access Token Expiration
- User access tokens expire after 60 days
- Page access tokens can be long-lived
- ProTech stores refresh tokens to automatically renew access

### Rate Limits
- Facebook has rate limits on API calls
- Standard limit: 200 calls per hour per user
- Page posts count toward this limit

### Privacy & Security
- Your App Secret is stored securely in macOS Keychain
- Never share your App Secret publicly
- Never commit credentials to version control

### App Review (if needed)
Facebook may require app review for:
- `pages_manage_posts` (usually required)
- `pages_read_engagement` (usually required)

Submit your app for review with:
1. Clear use case description
2. Step-by-step instructions
3. Screen recording demo
4. Privacy policy

---

## Additional Resources

- **Facebook Developer Docs**: https://developers.facebook.com/docs
- **Graph API Explorer**: https://developers.facebook.com/tools/explorer
- **Page API Reference**: https://developers.facebook.com/docs/pages-api
- **Publishing Posts**: https://developers.facebook.com/docs/pages-api/posts

---

## Quick Reference

### What You Need:
- ✅ App ID
- ✅ App Secret
- ✅ Facebook Page (as admin)
- ✅ Redirect URI: `protech://oauth/facebook`

### Required Permissions:
- ✅ `pages_manage_posts`
- ✅ `pages_read_engagement`
- ✅ `pages_show_list`

### API Endpoint:
- **OAuth**: `https://www.facebook.com/v18.0/dialog/oauth`
- **Token**: `https://graph.facebook.com/v18.0/oauth/access_token`
- **Post**: `https://graph.facebook.com/v18.0/{page-id}/feed`

---

Need help? Feel free to ask!
