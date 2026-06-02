# Code Signing & Provisioning Profiles Configuration Guide

## Overview

This document provides step-by-step instructions for configuring code signing and provisioning profiles for the Forged In Fire Client Manager macOS application for development, testing, and App Store distribution.

**Project Location:** `/Users/purduelaw/Desktop/ArkheApps/StudentTracker/ForgedInFireClientManager/`

---

## Table of Contents

1. [Apple Developer Account Setup](#apple-developer-account-setup)
2. [Bundle Identifier Configuration](#bundle-identifier-configuration)
3. [Certificate Creation](#certificate-creation)
4. [Provisioning Profile Creation](#provisioning-profile-creation)
5. [Xcode Project Configuration](#xcode-project-configuration)
6. [Code Signing in Xcode](#code-signing-in-xcode)
7. [Testing Configuration](#testing-configuration)
8. [App Store Distribution](#app-store-distribution)
9. [Troubleshooting](#troubleshooting)

---

## Apple Developer Account Setup

### Prerequisites

- **Apple Developer Account** (Individual or Organization)
- **Active Membership** ($99/year for individuals, $299/year for organizations)
- **Admin Access** to account

### Step 1: Sign In to Developer Portal

1. Go to [developer.apple.com](https://developer.apple.com)
2. Sign in with your Apple ID
3. Navigate to "Account" → "Membership"
4. Verify your membership is active

### Step 2: Add Team Members (if Organization)

1. Go to "People" → "Invite People"
2. Invite team members with their Apple ID
3. Assign appropriate roles (Admin, App Manager, etc.)
4. Wait for team members to accept invitation

---

## Bundle Identifier Configuration

### Bundle Identifier Format

The bundle identifier should follow reverse DNS notation:

```
com.forgedinfire.clientmanager
```

### Step 1: Configure in Xcode

1. **Open Project in Xcode**
   ```bash
   open /Users/purduelaw/Desktop/ArkheApps/StudentTracker/ForgedInFireClientManager/ForgedInFireClientManager.xcodeproj
   ```

2. **Select Target**
   - Click on `ForgedInFireClientManager` project (blue icon)
   - Select `ForgedInFireClientManager` target
   - Go to "General" tab

3. **Set Bundle Identifier**
   - Find "Bundle Identifier" field
   - Enter: `com.forgedinfire.clientmanager`
   - Click "Change Bundle Identifier" if needed

4. **Display Name**
   - Set "Display Name" to: `Forged In Fire Client Manager`

5. **Version Information**
   - Set "Version" to: `1.0.0`
   - Set "Build" to: `1`

---

## Certificate Creation

### Required Certificates

For macOS app distribution, you need:

1. **Mac Development Certificate** - For development and testing
2. **Mac App Distribution Certificate** - For App Store submission
3. **Mac Installer Distribution Certificate** - For installer packages (optional)

### Step 1: Create Development Certificate

1. Go to [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/certificates/list)
2. Click "+" to create a new certificate
3. Select "Mac App Development"
4. Choose your development team
5. Upload a Certificate Signing Request (CSR):
   - Open Keychain Access on your Mac
   - Keychain Access → Certificate Assistant → From a Certificate Authority
   - Choose "Apple Development" → Continue
   - Enter your email address and Common Name (CN)
   - Save CSR to disk
6. Upload the CSR and download the certificate
7. Double-click the certificate to install in Keychain Access

### Step 2: Create Distribution Certificate

1. Go to [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/certificates/list)
2. Click "+" to create a new certificate
3. Select "Mac App Distribution"
4. Choose your development team
5. Upload a CSR (same process as above)
6. Download and install the certificate

### Step 3: Create Installer Distribution Certificate (Optional)

1. Follow the same process as above
2. Select "Mac Installer Distribution"
3. Download and install the certificate

---

## Provisioning Profile Creation

### Required Provisioning Profiles

1. **Mac App Development Profile** - For development and testing
2. **Mac App Store Profile** - For App Store submission

### Step 1: Register App ID

1. Go to [Identifiers](https://developer.apple.com/account/resources/identifiers/list)
2. Click "+" to create a new App ID
3. Select "App IDs"
4. Select "Mac" platform
5. Choose "App ID" (not wildcard)
6. Enter Bundle ID: `com.forgedinfire.clientmanager`
7. Select capabilities (see below)
8. Register the App ID

### Step 2: Configure Capabilities

Enable the following capabilities for the App ID:

#### Required Capabilities
- **Keychain Services** - For secure credential storage
- **EventKit** - For calendar integration
- **Speech Recognition** - For voice-to-text

#### Optional Capabilities
- **iCloud** - For data synchronization (if needed)
- **In-App Purchase** - If you plan to monetize

### Step 3: Create Development Provisioning Profile

1. Go to [Profiles](https://developer.apple.com/account/resources/profiles/list)
2. Click "+" to create a new profile
3. Select "macOS App Development"
4. Choose your App ID: `com.forgedinfire.clientmanager`
5. Select your development certificate
6. Select your development team
7. Name it: `Forged In Fire Client Manager Development`
8. Generate and download the profile

### Step 4: Create App Store Provisioning Profile

1. Go to [Profiles](https://developer.apple.com/account/resources/profiles/list)
2. Click "+" to create a new profile
3. Select "Mac App Store"
4. Choose your App ID: `com.forgedinfire.clientmanager`
5. Select your distribution certificate
6. Select your development team
7. Name it: `Forged In Fire Client Manager App Store`
8. Generate and download the profile

---

## Xcode Project Configuration

### Step 1: Install Provisioning Profiles

1. **Download Profiles**
   - Download both development and App Store profiles
   - They will be `.mobileprovision` files

2. **Install in Xcode**
   - Double-click the `.mobileprovision` files
   - Or: Xcode → Preferences → Accounts → Download Manual Profiles
   - Select the profiles and install

### Step 2: Configure Signing in Xcode

1. **Select Target**
   - Click on `ForgedInFireClientManager` target
   - Go to "Signing & Capabilities" tab

2. **Enable Automatic Signing**
   - Check "Automatically manage signing"
   - Select your development team
   - Select "Forged In Fire Client Manager Development" profile

3. **Configure for Release Build**
   - For App Store builds, you may need manual signing
   - Uncheck "Automatically manage signing" for Release configuration
   - Select your distribution certificate
   - Select "Forged In Fire Client Manager App Store" profile

### Step 3: Enable Capabilities

1. **Go to "Signing & Capabilities" tab**
2. Click "+ Capability"
3. Add the following:
   - Keychain Services
   - EventKit
   - Speech Recognition
   - Hardened Runtime (recommended for App Store)

### Step 4: Configure Info.plist

Add the following keys to `Info.plist`:

```xml
<key>NSCalendarsUsageDescription</key>
<string>Calendar access is used to sync appointments with your system calendar.</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>Speech recognition is used for voice-to-text in case notes to improve documentation efficiency.</string>

<key>NSFaceIDUsageDescription</key>
<string>Use Face ID to securely sign in to your account.</string>

<key>NSKeychainUsageDescription</key>
<string>Securely store your credentials using the device keychain.</string>
```

---

## Code Signing in Xcode

### Step 1: Verify Code Signing

1. **Select Target**
   - Click on `ForgedInFireClientManager` target
   - Go to "Signing & Capabilities" tab

2. **Check Signing Status**
   - You should see a green checkmark next to your team and profile
   - If not, click on the profile and select the correct one

3. **Verify Provisioning Profile**
   - Go to Project Navigator
   - Expand your target
   - Check that provisioning profiles are listed under "Signing & Capabilities"

### Step 2: Test Build

1. **Clean Build Folder**
   - Product → Clean Build Folder
   - Cmd+Shift+K

2. **Build for Development**
   - Product → Build
   - Cmd+B
   - Verify build succeeds without signing errors

3. **Archive for Distribution**
   - Product → Archive
   - Verify archive is created successfully

---

## Testing Configuration

### Development Testing

1. **Run on Your Mac**
   - Click the Play button in Xcode
   - The app should launch with your development certificate
   - Verify all features work

2. **Test on Other Macs**
   - Copy the .app from DerivedData to another Mac
   - You may need to re-sign for the other Mac
   - Use codesign command if needed:
     ```bash
     codesign --force --deep --sign "Developer ID" ForgedInFireClientManager.app
     ```

### Distribution Testing

1. **Create TestFlight Build**
   - Product → Archive
   - Distribute App → TestFlight & App Store
   - Upload to TestFlight
   - Invite testers

2. **Internal Testing**
   - Share TestFlight link with team
   - Test on multiple macOS versions
   - Verify all features work

---

## App Store Distribution

### Step 1: Create App Store Connect Record

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click "My Apps" → "+"
3. Create a new app
4. Platform: macOS
5. Name: Forged In Fire Client Manager
6. Bundle ID: com.forgedinfire.clientmanager
7. SKU: FORGED-IN-FIRE-001
8. User Access: Complete the information

### Step 2: Upload Build

1. **Archive the App**
   - Product → Archive
   - Wait for archive to complete

2. **Distribute to App Store Connect**
   - Distribute App → App Store Connect
   - Select "Forged In Fire Client Manager App Store" profile
   - Upload

### Step 3: Configure App Store Information

1. **App Information**
   - Add screenshots (minimum 1, recommended 5-10)
   - Add app description
   - Add keywords
   - Add support URL
   - Add marketing URL
   - Add privacy policy URL

2. **Pricing and Availability**
   - Set price (Free or Paid)
   - Set availability regions
   - Set release date

3. **Review Information**
   - Add demo account credentials
   - Add review notes
   - Add contact information

### Step 4: Submit for Review

1. Go to "App Store" tab
2. Click "Prepare for Submission"
3. Complete all required fields
4. Click "Add for Review"
5. Wait for Apple's review (typically 2-5 business days)

---

## Troubleshooting

### Common Signing Issues

#### Issue: "No signing certificate found"

**Solution:**
1. Check that your certificate is installed in Keychain Access
2. Verify certificate is not expired
3. Check that you selected the correct profile in Xcode
4. Try manually selecting the certificate

#### Issue: "Provisioning profile doesn't include signing certificate"

**Solution:**
1. Download the provisioning profile again from Developer Portal
2. Reinstall the profile in Xcode
3. Verify the certificate matches the one in the profile
4. Clean build folder and rebuild

#### Issue: "Bundle identifier doesn't match"

**Solution:**
1. Verify bundle identifier matches exactly between:
   - Xcode project configuration
   - App ID in Developer Portal
   - Provisioning profile
2. Make sure there are no extra characters or typos
3. Check for trailing spaces

### Common Build Issues

#### Issue: "Code signing error"

**Solution:**
1. Clean build folder (Cmd+Shift+K)
2. Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`
3. Restart Xcode
4. Rebuild

#### Issue: "Archive fails"

**Solution:**
1. Verify code signing configuration
2. Check that all required certificates are installed
3. Verify provisioning profile is valid
4. Check for certificate expiration

### Common Certificate Issues

#### Issue: Certificate expired

**Solution:**
1. Go to Developer Portal
2. Revoke the expired certificate
3. Create a new certificate
4. Update provisioning profiles
5. Reinstall profiles in Xcode

#### Issue: Certificate revoked

**Solution:**
1. Check why certificate was revoked
2. Create a new certificate
3. Update all provisioning profiles
4. Reinstall profiles in Xcode

---

## Best Practices

### Certificate Management

1. **Certificate Expiration**
   - Monitor certificate expiration dates
   - Set reminders 30 days before expiration
   - Create new certificates before expiration
   - Update provisioning profiles before old certificates expire

2. **Team Management**
   - Regularly review team member access
   - Remove team members who leave the organization
   - Limit admin access to trusted individuals
   - Use strong passwords for Developer Portal

3. **Profile Management**
   - Use descriptive profile names
   - Keep development and production profiles separate
   - Don't share production profiles
   - Regularly clean up old profiles

### Security Best Practices

1. **Protect Private Keys**
   - Never share private keys
   - Store them securely in Keychain Access
   - Use unique certificates for each app
   - Rotate certificates periodically

2. **Use App Store Connect Features**
   - Enable two-factor authentication
   - Use strong passwords
   - Monitor for unauthorized access
   - Review access logs regularly

3. **Testing in Production**
   - Use TestFlight for beta testing
   - Test with different macOS versions
   - Test with different hardware configurations
   - Get feedback from users before full release

---

## Environment-Specific Configuration

### Development Environment

**Configuration:**
- Team: Your development team
- Profile: Mac App Development
- Certificate: Mac Development Certificate
- Signing: Automatic

**Purpose:** Development and internal testing

### Production Environment

**Configuration:**
- Team: Your organization team
- Profile: Mac App Store
- Certificate: Mac App Distribution Certificate
- Signing: Manual (for App Store builds)

**Purpose:** App Store distribution

---

## Automated Build Configuration

### Using Xcode Build Settings

For automated builds, you can use environment variables:

```bash
# Development build
xcodebuild -scheme ForgedInFireClientManager \
  -configuration Debug \
  -CODE_SIGN_IDENTITY="Apple Development: Your Name (TEAM_ID)" \
  -PROVISIONING_PROFILE_SPEC=~/Library/MobileDevice/Provisioning\ Profiles/Development.mobileprovision

# Production build
xcodebuild -scheme ForgedInFireClientManager \
  -configuration Release \
  -CODE_SIGN_IDENTITY="Apple Distribution: Your Name (TEAM_ID)" \
  -PROVISIONING_PROFILE_SPEC=~/Library/MobileDevice/Provisioning\ Profiles/AppStore.mobileprovision
```

---

## Verification Checklist

### Pre-Distribution Checklist

- [ ] Bundle identifier configured correctly
- [ ] Development certificate installed
- [ ] Distribution certificate installed
- [ ] Development provisioning profile installed
- [ ] App Store provisioning profile installed
- [ ] Capabilities enabled in Xcode
- [ ] Info.plist permissions added
- [ ] Code signing configured in Xcode
- [ ] Development build succeeds
- [ ] Archive creation succeeds
- [ ] App runs without signing errors

### Pre-App Store Checklist

- [ ] App Store Connect record created
- [ ] Bundle ID matches Xcode configuration
- [ ] Screenshots prepared
- [ ] App description written
- [ Keywords configured
- [ ] Support URL configured
- [] Privacy policy URL configured
- [ ] Demo account credentials added
- [ ] Review notes added
- [ ] Contact information added
- [ ] Testing completed
- [ ] Archive uploaded to App Store Connect
- [ ] All required fields completed
- [ ] Ready for submission

---

## Support

**For issues with code signing or provisioning:**
- Apple Developer Support: https://developer.apple.com/contact/
- Xcode Help: https://developer.apple.com/xcode/
- App Store Connect Help: https://developer.apple.com/app-store-connect/

---

## Quick Reference

### Important URLs

- [Apple Developer](https://developer.apple.com)
- [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/certificates/list)
- [Identifiers](https://developer.apple.com/account/resources/identifiers/list)
- [Profiles](https://developer.apple.com/account/resources/profiles/list)
- [App Store Connect](https://appstoreconnect.apple.com)

### Bundle Identifier

```
com.forgedinfire.clientmanager
```

### Team ID

Find your Team ID in Developer Portal:
- Account → Membership → Team ID

### Common Commands

```bash
# Check code signing
codesign -dv -v ForgedInFireClientManager.app

# Re-sign app
codesign --force --deep --sign "Developer ID" ForgedInFireClientManager.app

# Verify provisioning profile
security cms -D -i ~/Library/MobileDevice/Provisioning\ Profiles/Profile.mobileprovision
```

---

**Document Version:** 1.0
**Last Updated:** 2024
**Status:** Ready for Code Signing Configuration