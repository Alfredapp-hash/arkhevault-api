# Arkhe Vault - Rebrand Plan

## Rebrand Overview

**From:** Arkhe Vault Client Manager  
**To:** Arkhe Vault  
**Parent Company:** Arkhe Holdings

**New Brand Identity:**
- Shield/cross motif (from Arkhe Holdings logo)
- Cyan/teal color palette (#00D9C0 primary)
- Dark tech aesthetic with glowing accents
- Security-focused messaging ("Vault")

---

## Color Palette Update

### Primary Colors (Arkhe Holdings)

```swift
// Arkhe Cyan - Primary brand color
static let arkheCyan = Color(hex: "#00D9C0")

// Deep Space - Background
static let deepSpace = Color(hex: "#0A0F1C")

// Tech Blue - Secondary
static let techBlue = Color(hex: "#00A8E8")

// Shield Silver - Accents
static let shieldSilver = Color(hex: "#C0C5CE")

// Cyber Glow - Highlights
static let cyberGlow = Color(hex: "#00F5D4")
```

### Supporting Colors

```swift
// Security Red - Critical alerts
static let securityRed = Color(hex: "#FF3366")

// Safe Green - Success/resolved
static let safeGreen = Color(hex: "#00E676")

// Warning Amber - Caution
static let warningAmber = Color(hex: "#FFB74D")

// Data Blue - Information
static let dataBlue = Color(hex: "#448AFF")
```

---

## Complete Rebrand Checklist

### 1. Code Files to Update

#### Swift Source Files (34 files)

**Critical Path (Update First):**
- [ ] `Shared/Utilities/Branding.swift` - Complete color overhaul
- [ ] `Shared/Components/ArkheLogo.swift` - Rename to ArkheLogo, update design
- [ ] `ArkheVaultApp.swift` - Rename to ArkheVaultApp
- [ ] `App/ArkheVaultApp.swift` - Rename, update app name
- [ ] `Core/Services/Configuration.swift` - Update keychain service name

**High Priority:**
- [ ] All view files with "Arkhe Vault" text
- [ ] All view files with "Forge" component references
- [ ] `AuthenticationManager.swift` - Update salt prefix
- [ ] `SecurityEventLogger.swift` - Update service name
- [ ] `SessionManager.swift` - Update references
- [ ] `NetworkSecurityManager.swift` - Update service refs

**Medium Priority:**
- [ ] All "ArkheVault" in comments
- [ ] Keychain service identifiers
- [ ] App group identifiers
- [ ] Bundle identifiers

#### Documentation Files (11 files)

- [ ] `SECURITY_AUDIT_REPORT.md`
- [ ] `VALUATION_REPORT.md`
- [ ] `CLIENT_UPDATE.md`
- [ ] `IMPLEMENTATION_SUMMARY.md`
- [ ] `PROGRESS_AUDIT.md`
- [ ] `PRIORITY_IMPLEMENTATION_REPORT.md`
- [ ] `DEPLOYMENT_GUIDE.md`
- [ ] `INTEGRATION_GUIDE.md`
- [ ] `BUSINESS_MODEL_SAAS.md`
- [ ] `APPLICATION_FORM.md`
- [ ] All other .md files

#### Business Model Documents

- [ ] Pricing tier names (Forge → Arkhe)
- [ ] Company name in all agreements
- [ ] Contact emails
- [ ] Website references

### 2. Asset Updates Needed

#### Logo Assets
- [ ] Create new ArkheVault app icon (shield + vault imagery)
- [ ] Create new logo variations:
  - Horizontal (logo + wordmark)
  - Vertical (stacked)
  - Icon only
  - White version
  - Dark version

#### UI Components
- [ ] Update ArkheButton → ArkheButton
- [ ] Update ArkheCard → ArkheCard
- [ ] Update all gradient styles
- [ ] Update shadow effects to match tech aesthetic

### 3. Text Replacements

#### Global Find & Replace
```
Arkhe Vault → Arkhe Vault
ArkheVault → ArkheVault
arkhevault → arkhevault
Arkhe Vault Client Manager → Arkhe Vault
com.arkheholdings.vault → com.arkheholdings.vault
ArkheButton → ArkheButton
ArkheCard → ArkheCard
ArkheLogo → ArkheLogo
```

### 4. Security Updates

- [ ] Keychain service: `com.arkheholdings.vault.clientmanager` → `com.arkheholdings.vault`
- [ ] Salt prefix: `ArkheVault_` → `ArkheVault_`
- [ ] API key references
- [ ] Certificate pinning domain references

### 5. Project Structure

- [ ] Rename project directory (optional)
- [ ] Update Xcode project name
- [ ] Update scheme names
- [ ] Update test target names

### 6. External References

- [ ] App Store listing (when ready)
- [ ] Website domain
- [ ] Support email
- [ ] Documentation site
- [ ] Social media handles

---

## Brand Voice & Messaging

### New Tagline Options:
1. "Secure. Smart. Social Impact."
2. "Protecting Data. Empowering Missions."
3. "Your Mission. Our Vault."
4. "Enterprise Security for Social Good."

### Key Messaging Pillars:
1. **Security First** - Vault metaphor, encryption, protection
2. **Tech Forward** - AI, automation, modern architecture
3. **Mission Aligned** - Built by Arkhe Holdings for social impact
4. **Accessible** - 2-year free program continues

---

## Timeline Estimate

### Phase 1: Core Rebrand (Week 1)
- Update Branding.swift (colors)
- Update app entry points
- Update key service files
- Update documentation headers

### Phase 2: Code Sweep (Week 2)
- Global find/replace in all Swift files
- Update component names
- Update keychain/security identifiers
- Test build

### Phase 3: Assets & Polish (Week 3)
- Create new logo assets
- Update all UI components
- Update documentation content
- Final testing

### Phase 4: Launch Prep (Week 4)
- App Store assets
- Website updates
- Email setup (vault@arkheholdings.com)
- Go live

**Total Timeline:** 2-4 weeks

---

## Risks & Considerations

### Technical Risks:
- Keychain data migration (existing users)
- App group identifier changes
- URL scheme changes (if any)

### Mitigation:
- Maintain backward compatibility where possible
- Document migration path for existing installations
- Consider dual-brand transition period

### User Communication:
- Email existing users about rebrand
- Explain "same software, new name"
- Reassure data is unchanged
- Update all external links gradually

---

## Post-Rebrand Success Metrics

- [ ] All 34 Swift files updated
- [ ] All 11 documentation files updated
- [ ] Build succeeds with zero warnings
- [ ] All 85+ tests pass
- [ ] No "Arkhe Vault" references remain (except historical docs)
- [ ] New logo integrated
- [ ] New color scheme applied
- [ ] App launches successfully
- [ ] Keychain migration tested
- [ ] Documentation published

---

## Immediate Action Items

**Today:**
1. Approve rebrand plan
2. Create new logo assets
3. Update Branding.swift
4. Update app entry point

**This Week:**
1. Complete code file updates
2. Update documentation
3. Test build
4. Prepare user communication

**Next Week:**
1. Final testing
2. Deploy updates
3. Announce rebrand
4. Monitor feedback

---

**Status:** Ready to begin rebrand execution

---

*End of Rebrand Plan*
