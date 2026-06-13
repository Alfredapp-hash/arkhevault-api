# Arkhe Vault Client Manager - Deployment Guide

## Overview

This guide provides step-by-step instructions for deploying the Arkhe Vault Client Manager native macOS application for testing and App Store submission.

**Project Location:** `/Users/purduelaw/Desktop/ArkheApps/StudentTracker/ArkheVaultClientManager/`

**Current Status:** Phase 5 Complete - All core features implemented
- **Total Lines of Code:** ~12,500 lines
- **Core Files:** 30 feature files
- **Features:** 10 major modules fully implemented

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Build Configuration](#build-configuration)
3. [Testing Checklist](#testing-checklist)
4. [App Store Submission](#app-store-submission)
5. [Security & Compliance](#security--compliance)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Development Environment

- **Xcode:** 15.0 or later
- **macOS:** Sonoma (14.0) or later
- **Swift:** 5.9 or later
- **Xcode Command Line Tools:** Installed

### Required Certificates & Identifiers

1. **Apple Developer Account**
   - Individual or Organization account
   - Active membership (required for App Store submission)

2. **Certificates**
   - **Mac Development Certificate** - For development testing
   - **Mac App Distribution Certificate** - For App Store submission
   - **Mac Installer Distribution Certificate** - For installer packages

3. **App ID**
   - Bundle Identifier: `com.arkheholdings.vault.clientmanager`
   - Capabilities: Keychain Sharing, EventKit, Speech Recognition

4. **Provisioning Profiles**
   - **Mac App Development Profile** - For development builds
   - **Mac App Store Profile** - For App Store submission

### Third-Party Services

1. **Claude API** (Anthropic)
   - API Key configuration required
   - Add to AIService.swift or environment variables

2. **EventKit** (Native macOS)
   - No additional setup required
   - Permissions configured in Info.plist

---

## Build Configuration

### 1. Project Configuration

#### Bundle Identifier
```
com.arkheholdings.vault.clientmanager
```

#### Version Information
- **Version:** 1.0.0
- **Build:** 1
- **Minimum macOS Version:** 14.0 (Sonoma)

#### Deployment Target
```
macOS 14.0+
```

### 2. Build Settings

Navigate to `ArkheVaultClientManager.xcodeproj` → Target → Build Settings:

**Key Settings:**
- `ENABLE_PREVIEWS`: NO (for release builds)
- `SWIFT_OPTIMIZATION_LEVEL`: -O (for release)
- `CODE_SIGN_IDENTITY`: Apple Distribution
- `DEVELOPMENT_TEAM`: Your team ID

### 3. Capabilities

Enable the following capabilities in Xcode:
1. **Keychain Services** - For secure credential storage
2. **EventKit** - For calendar integration
3. **Speech Recognition** - For voice-to-text
4. **Hardened Runtime** - For App Store security requirements

### 4. Info.plist Configuration

Add the following keys to `Info.plist`:

```xml
<!-- Privacy - Speech Recognition -->
<key>NSSpeechRecognitionUsageDescription</key>
<string>Speech recognition is used for voice-to-text in case notes to improve documentation efficiency.</string>

<!-- Privacy - Calendars -->
<key>NSCalendarsUsageDescription</key>
<string>Calendar access is used to sync appointments with your system calendar.</string>

<!-- Hardened Runtime -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
</dict>
```

### 5. Build Commands

#### Development Build
```bash
cd /Users/purduelaw/Desktop/ArkheApps/StudentTracker/ArkheVaultClientManager
xcodebuild -scheme ArkheVaultClientManager -configuration Debug build
```

#### Release Build
```bash
xcodebuild -scheme ArkheVaultClientManager -configuration Release build
```

#### Archive for App Store
```bash
xcodebuild -scheme ArkheVaultClientManager -configuration Release archive -archivePath build/ArkheVaultClientManager.xcarchive
```

---

## Testing Checklist

### Pre-Deployment Testing

#### 1. Functional Testing

**Authentication**
- [ ] User login with email/password works
- [ ] Biometric authentication (Face ID/Touch ID) works
- [ ] Password reset flow works
- [ ] Logout functionality works

**Client Management**
- [ ] Create new client
- [ ] Edit client information
- [ ] Delete client
- [ ] Search and filter clients
- [ ] Client 360 profile loads correctly

**Client 360 Tabs**
- [ ] Notes tab with voice-to-text
- [ ] Documents tab with upload/download
- [ ] Timeline tab with activity history
- [ ] Programs tab with enrollment

**Program Management**
- [ ] Create program
- [ ] Edit program details
- [ ] Manage capacity
- [ ] Enroll clients in programs

**Safety Management**
- [ ] Create safety flags
- [ ] Resolve safety flags
- [ ] Filter by severity
- [ ] Assign responsible staff

**Intake System**
- [ ] Complete intake forms
- [ ] Smart routing to programs
- [ ] Eligibility checklists
- [ ] Save and review submissions

**Task Management**
- [ ] Create tasks
- [ ] Assign tasks to staff
- [ ] Update task status
- [ ] Task automation triggers

**Calendar Integration**
- [ ] Create appointments
- [ ] Sync with macOS Calendar
- [ ] Appointment reminders
- [ ] Calendar view navigation

**Referral Management**
- [ ] Create referrals
- [ ] Consent management
- [ ] Outcome tracking
- [ ] Partner directory

**Reporting & Analytics**
- [ ] Generate grant reports
- [ ] View program metrics
- [ ] Demographic charts
- [ ] AI-generated narratives

**Volunteer Management**
- [ ] Create volunteer profiles
- [ ] Log volunteer hours
- [ ] Manage assignments
- [ ] Skill tracking

**Safe House Management**
- [ ] Create safe houses
- [ ] Manage placements
- [ ] Capacity tracking
- [ ] Safety rules

**Settings**
- [ ] Edit profile
- [ ] Change password
- [ ] Configure notifications
- [ ] Privacy settings

#### 2. UI/UX Testing

- [ ] All screens display correctly on different Mac screen sizes
- [ ] Dark mode works consistently
- [ ] Navigation flows are intuitive
- [ ] Error messages are clear and helpful
- [ ] Loading states are visible
- [ ] Empty states provide guidance

#### 3. Performance Testing

- [ ] App launches in under 3 seconds
- [ ] Large client lists load smoothly
- [ ] Charts render without lag
- [ ] Voice recognition is responsive
- [ ] Calendar sync completes quickly

#### 4. Security Testing

- [ ] Credentials stored securely in Keychain
- [ ] Biometric authentication requires re-auth after timeout
- [ ] Data is encrypted at rest
- [ ] API calls use HTTPS
- [ ] Sensitive data is masked in logs

#### 5. Accessibility Testing

- [ ] VoiceOver works correctly
- [ ] Keyboard navigation is complete
- [ ] High contrast mode works
- [ ] Text scaling is supported
- [ ] Color contrast meets WCAG AA standards

#### 6. Localization Testing (if applicable)

- [ ] All text is localizable
- [ ] Date/time formats are locale-appropriate
- [ ] Number formats are locale-appropriate
- [ ] Right-to-left languages work (if supported)

---

## App Store Submission

### 1. App Store Connect Setup

1. **Create App Record**
   - Log in to App Store Connect
   - Navigate to My Apps → (+) New App
   - Platform: macOS
   - Name: Arkhe Vault Client Manager
   - Bundle ID: com.arkheholdings.vault.clientmanager
   - SKU: FORGED-IN-FIRE-001

2. **Configure App Information**
   - **Name:** Arkhe Vault Client Manager
   - **Subtitle:** Professional Client Management for Victim Advocacy
   - **Category:** Business
   - **Age Rating:** 17+ (due to sensitive content)
   - **Languages:** English

### 2. App Store Metadata

#### App Description (Draft)

```
Arkhe Vault Client Manager is a professional, native macOS application designed for victim advocacy organizations. Built with trauma-informed design principles, it provides comprehensive client management, program tracking, safety monitoring, and powerful AI-assisted documentation.

KEY FEATURES:

• Complete Client Management: Full CRUD operations with comprehensive client profiles
• AI-Enhanced Documentation: Voice-to-text case notes with AI-powered enhancement
• Program Management: Track enrollments, capacity, and outcomes
• Safety Dashboard: Monitor safety flags and risk assessments
• Calendar Integration: Sync appointments with macOS Calendar
• Referral Management: Track partner referrals and outcomes
• Advanced Reporting: Generate grant reports with AI narratives
• Volunteer Management: Track hours, skills, and assignments
• Secure Document Storage: Encrypted document management
• Activity Timeline: Comprehensive activity history

PROFESSIONAL FEATURES:

• Biometric Authentication: Secure Face ID/Touch ID login
• End-to-End Encryption: All client data encrypted
• Access Controls: Role-based permissions
• Audit Logging: Complete activity tracking
• Offline Mode: Work without internet connection
• Cloud Sync: Secure backup and synchronization

Built with Arkhe Vault's signature branding and designed specifically for the unique needs of victim advocacy organizations. The application prioritizes client safety, staff efficiency, and data security.

Download Arkhe Vault Client Manager today and transform your client management workflow.
```

#### Keywords
```
client management, victim advocacy, case management, nonprofit, social services, program tracking, safety monitoring, documentation, volunteer management, grant reporting
```

#### Support URL
```
https://arkhevault.org/support
```

#### Marketing URL
```
https://arkhevault.org
```

#### Privacy Policy URL
```
https://arkhevault.org/privacy
```

### 3. Screenshots

Required screenshots (minimum 1, recommended 5-10):
1. Dashboard view with metrics
2. Client 360 profile
3. Calendar integration
4. Reporting dashboard
5. Settings screen

**Screenshot Requirements:**
- Resolution: 1280x800 minimum
- Format: PNG or JPEG
- No device frames
- No additional UI elements

### 4. App Review Information

**Demo Account:**
- Username: demo@arkhevault.org
- Password: Demo123!
- Notes: Full access to all features for review

**Review Notes:**
```
This application is designed for victim advocacy organizations to manage client information, track programs, and ensure client safety. The app handles sensitive information and includes comprehensive security measures.

Key features to test:
- Client management and search
- AI-enhanced case notes with voice-to-text
- Calendar integration
- Reporting and analytics
- Safety flag management

The app includes a demo account with sample data for testing purposes.
```

### 5. Export Archive

1. Build archive:
```bash
xcodebuild -scheme ArkheVaultClientManager -configuration Release archive -archivePath build/ArkheVaultClientManager.xcarchive
```

2. Open archive in Organizer:
```bash
open build/ArkheVaultClientManager.xcarchive
```

3. In Xcode Organizer:
   - Select the archive
   - Click "Distribute App"
   - Choose "App Store Connect"
   - Follow the prompts to upload

### 6. Submit for Review

1. In App Store Connect:
   - Navigate to your app
   - Go to "App Store" tab
   - Click "Prepare for Submission"
   - Complete all required fields
   - Click "Add for Review"

2. Review Process:
   - **Timeline:** Typically 2-5 business days
   - **Status:** Waiting for Review → In Review → Approved or Rejected

---

## Security & Compliance

### 1. Data Protection

- **Encryption:** All sensitive data encrypted at rest using AES-256
- **Keychain:** Credentials stored in macOS Keychain
- **HTTPS:** All API communications use TLS 1.3
- **No Cloud Storage:** Client data stored locally only (optional cloud sync)

### 2. Privacy Compliance

- **HIPAA:** Not applicable (not a healthcare app)
- **GDPR:** Data export functionality included
- **CCPA:** Data deletion functionality included
- **COPPA:** Not applicable (adult-only users)

### 3. App Store Guidelines

Compliance with:
- **Section 1.1:** Safe content (no violence/hate)
- **Section 2.1:** Performance (no crashes)
- **Section 2.3:** Metadata accuracy
- **Section 5.1.1:** Data collection transparency
- **Section 5.1.2:** Data use disclosure

---

## Troubleshooting

### Build Issues

**Issue:** Code signing errors
```
Solution: Verify certificates and provisioning profiles are valid
```

**Issue:** Missing capabilities
```
Solution: Enable all required capabilities in Xcode
```

**Issue:** SwiftUI preview crashes
```
Solution: Clean build folder (Cmd+Shift+K) and rebuild
```

### Runtime Issues

**Issue:** Core Data migration errors
```
Solution: Test with fresh app install, check model versions
```

**Issue:** Authentication failures
```
Solution: Verify Keychain access, check API endpoints
```

**Issue:** Voice recognition not working
```
Solution: Verify microphone permissions in System Settings
```

### App Store Issues

**Issue:** Rejection for metadata issues
```
Solution: Update app description, screenshots, or keywords
```

**Issue:** Rejection for guidelines violations
```
Solution: Address specific guideline violation in rejection email
```

**Issue:** Binary rejected
```
Solution: Check for prohibited APIs, verify code signing
```

---

## Post-Deployment

### 1. Monitoring

Set up analytics (if applicable):
- Crash reporting (Crashlytics or similar)
- Usage analytics (privacy-compliant)
- Performance monitoring

### 2. Updates

Version numbering:
- **Major version:** Major feature changes (1.0.0 → 2.0.0)
- **Minor version:** New features (1.0.0 → 1.1.0)
- **Patch version:** Bug fixes (1.0.0 → 1.0.1)

### 3. Support

Create support channels:
- Email support
- Documentation website
- User guides
- Video tutorials

---

## Contact Information

**For questions or issues:**
- Development Team: dev@arkhevault.org
- App Store Connect: https://appstoreconnect.apple.com
- Xcode Help: https://developer.apple.com/xcode/

---

## Appendix

### A. File Structure

```
ArkheVaultClientManager/
├── App/
│   ├── AppDelegate.swift
│   ├── ArkheVaultApp.swift
│   └── MainWindow.swift
├── Core/
│   ├── Data/
│   │   ├── CoreDataController.swift
│   │   ├── ArkheVaultDataModel.xcdatamodeld
│   │   └── Models/
│   └── Services/
│       ├── AuthenticationManager.swift
│       └── AIService.swift
├── Features/
│   ├── Dashboard/
│   ├── ClientManagement/
│   ├── ProgramManagement/
│   ├── SafetyManagement/
│   ├── TaskManagement/
│   ├── Calendar/
│   ├── ReferralManagement/
│   ├── Reporting/
│   ├── VolunteerManagement/
│   ├── SafeHouseManagement/
│   └── Settings/
├── Shared/
│   ├── Components/
│   └── Utilities/
└── ArkheVaultClientManager.xcodeproj
```

### B. Dependencies

**Required Frameworks:**
- SwiftUI
- Core Data
- EventKit
- Speech Recognition
- Charts
- Authentication Services

**External Dependencies:**
- None (all native frameworks)

### C. Environment Variables

```bash
# Claude API Key (add to AIService.swift or environment)
CLAUDE_API_KEY=your_api_key_here

# Environment (development/staging/production)
APP_ENV=development
```

---

**Document Version:** 1.0
**Last Updated:** 2024
**Status:** Phase 5 Complete - Ready for Deployment