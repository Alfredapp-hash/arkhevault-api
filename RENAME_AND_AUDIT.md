# Arkhe Vault - Complete Rename & Branding Audit

**Date:** June 2, 2026  
**Status:** Ready for Execution  
**Goal:** Rename folder + Audit all branding

---

## Step 1: Rename Root Folder

### Command to Execute:

```bash
# Navigate to parent directory
cd /Users/purduelaw/Desktop/ArkheApps/StudentTracker

# Rename the folder
mv ForgedInFireClientManager ArkheVault

# Verify the rename
ls -la
```

**Result:** Folder renamed to `ArkheVault`

---

## Step 2: Global Find & Replace Commands

### Critical Branding Replacements (ALL FILES):

```bash
# Navigate to the renamed folder
cd /Users/purduelaw/Desktop/ArkheApps/StudentTracker/ArkheVault

# 1. Replace "Forged In Fire" with "Arkhe Vault" (text with spaces)
find . -type f \( -name "*.swift" -o -name "*.md" -o -name "*.json" -o -name "*.plist" \) -exec sed -i '' 's/Forged In Fire/Arkhe Vault/g' {} +

# 2. Replace "ForgedInFire" with "ArkheVault" (camelCase)
find . -type f \( -name "*.swift" -o -name "*.md" -o -name "*.json" -o -name "*.plist" \) -exec sed -i '' 's/ForgedInFire/ArkheVault/g' {} +

# 3. Replace "forgedinfire" with "arkhevault" (lowercase)
find . -type f \( -name "*.swift" -o -name "*.md" -o -name "*.json" -o -name "*.plist" \) -exec sed -i '' 's/forgedinfire/arkhevault/g' {} +

# 4. Replace "com.forgedinfire" with "com.arkheholdings.vault"
find . -type f \( -name "*.swift" -o -name "*.json" -o -name "*.plist" \) -exec sed -i '' 's/com\.forgedinfire/com.arkheholdings.vault/g' {} +

# 5. Replace "ForgeButton" with "ArkheButton"
find . -type f -name "*.swift" -exec sed -i '' 's/ForgeButton/ArkheButton/g' {} +

# 6. Replace "ForgeCard" with "ArkheCard"
find . -type f -name "*.swift" -exec sed -i '' 's/ForgeCard/ArkheCard/g' {} +

# 7. Replace "ForgeLogo" with "ArkheLogo"
find . -type f -name "*.swift" -exec sed -i '' 's/ForgeLogo/ArkheLogo/g' {} +

# 8. Replace "ForgedInFireApp" with "ArkheVaultApp"
find . -type f -name "*.swift" -exec sed -i '' 's/ForgedInFireApp/ArkheVaultApp/g' {} +
```

---

## Step 3: Rename Individual Files

### Files to Rename:

```bash
cd /Users/purduelaw/Desktop/ArkheApps/StudentTracker/ArkheVault

# Rename main app file
mv App/ForgedInFireApp.swift App/ArkheVaultApp.swift

# Rename UI components
mv Shared/Components/ForgeButton.swift Shared/Components/ArkheButton.swift
mv Shared/Components/ForgeLogo.swift Shared/Components/ArkheLogo.swift

# Rename test directories (if needed)
mv Tests/ForgedInFireClientManagerTests Tests/ArkheVaultTests
mv Tests/ForgedInFireClientManagerUITests Tests/ArkheVaultUITests

# Update test file names
mv Tests/ArkheVaultTests/ForgedInFireClientManagerTests.swift Tests/ArkheVaultTests/ArkheVaultTests.swift 2>/dev/null || true
```

---

## Step 4: Audit Remaining References

### Verify All Changes:

```bash
# Check for any remaining "Forged In Fire" references
echo "=== Checking for 'Forged In Fire' ==="
grep -r "Forged In Fire" . --include="*.swift" --include="*.md" --include="*.json" --include="*.plist" || echo "✅ None found"

# Check for any remaining "ForgedInFire" references
echo "=== Checking for 'ForgedInFire' ==="
grep -r "ForgedInFire" . --include="*.swift" --include="*.md" --include="*.json" --include="*.plist" || echo "✅ None found"

# Check for any remaining "forgedinfire" references
echo "=== Checking for 'forgedinfire' ==="
grep -r "forgedinfire" . --include="*.swift" --include="*.md" --include="*.json" --include="*.plist" || echo "✅ None found"

# Check for any remaining "com.forgedinfire" references
echo "=== Checking for 'com.forgedinfire' ==="
grep -r "com\.forgedinfire" . --include="*.swift" --include="*.json" --include="*.plist" || echo "✅ None found"

# Check for any remaining "ForgeButton" references
echo "=== Checking for 'ForgeButton' ==="
grep -r "ForgeButton" . --include="*.swift" || echo "✅ None found"

# Check for any remaining "ForgeCard" references
echo "=== Checking for 'ForgeCard' ==="
grep -r "ForgeCard" . --include="*.swift" || echo "✅ None found"

# Check for any remaining "ForgeLogo" references
echo "=== Checking for 'ForgeLogo' ==="
grep -r "ForgeLogo" . --include="*.swift" || echo "✅ None found"

# Check for any remaining "ForgedInFireApp" references
echo "=== Checking for 'ForgedInFireApp' ==="
grep -r "ForgedInFireApp" . --include="*.swift" || echo "✅ None found"
```

---

## Step 5: Xcode Project Updates

### Update Project.pbxproj:

```bash
# The global sed commands above should handle this, but verify:
grep -r "ForgedInFireClientManager" . --include="*.pbxproj" || echo "✅ Project file updated"

# If still present, manually update:
# - PRODUCT_NAME
# - TARGET_NAME
# - Bundle identifier references
```

---

## Step 6: Documentation Audit

### Check All Markdown Files:

```bash
# List all markdown files and check for old branding
echo "=== Markdown Files Audit ==="
find . -name "*.md" -type f | while read file; do
    count=$(grep -c "Forged In Fire\|ForgedInFire\|forgedinfire" "$file" 2>/dev/null || echo 0)
    if [ "$count" -gt 0 ]; then
        echo "⚠️  $file: $count references remaining"
    fi
done
```

---

## Step 7: Swift File Audit

### Check All Swift Files:

```bash
# List all swift files and check for old branding
echo "=== Swift Files Audit ==="
find . -name "*.swift" -type f | while read file; do
    count=$(grep -c "Forged In Fire\|ForgedInFire\|forgedinfire\|ForgeButton\|ForgeCard\|ForgeLogo\|ForgedInFireApp" "$file" 2>/dev/null || echo 0)
    if [ "$count" -gt 0 ]; then
        echo "⚠️  $file: $count references remaining"
    fi
done
```

---

## Step 8: Logo Asset Verification

### Verify Logo Files Exist:

```bash
echo "=== Logo Assets ==="
ls -la *.png *.jpg *.svg 2>/dev/null || echo "Check logo files in root"

# Verify logo references in Branding.swift
grep "logoFileName" Shared/Utilities/Branding.swift
```

**Should show:**
- `arkhe_vault_logo`
- `arkhe_vault_logo_dark`
- `arkhe_vault_logo_compact`
- `arkhe_holdings_logo`

---

## Step 9: Build Verification

### Test the Build:

```bash
# Open the project
cd /Users/purduelaw/Desktop/ArkheApps/StudentTracker/ArkheVault

# Build for testing
xcodebuild build-for-testing \
    -project ArkheVault.xcodeproj \
    -scheme ArkheVault \
    -destination 'platform=macOS' \
    2>&1 | grep -E '(error|warning|Build succeeded|Build failed)'
```

---

## Step 10: Final Branding Checklist

### Visual Identity:
- [ ] App name displays as "Arkhe Vault" in menu bar
- [ ] App name displays as "Arkhe Vault" in dock
- [ ] Login window shows "Arkhe Vault"
- [ ] About dialog shows "Arkhe Vault by Arkhe Holdings"
- [ ] All windows have "Arkhe Vault" in title bar

### Color Scheme:
- [ ] Primary buttons use `arkheCyan` (#00D9C0)
- [ ] Background uses `deepSpace` (#0A0F1C)
- [ ] Text uses light colors on dark background
- [ ] Accent glows use `cyberGlow` (#00F5D4)

### Documentation:
- [ ] All README files reference "Arkhe Vault"
- [ ] All guides reference "Arkhe Holdings"
- [ ] Business model uses new branding
- [ ] Application forms use new branding
- [ ] Security audit uses new branding

### Code:
- [ ] No "Forged In Fire" text remains
- [ ] No "ForgedInFire" references remain
- [ ] No "forgedinfire" references remain
- [ ] Keychain uses `com.arkheholdings.vault`
- [ ] Salt prefix uses `ArkheVault_`
- [ ] All component names updated (ArkheButton, ArkheCard, ArkheLogo)

### Assets:
- [ ] App icon uses new Arkhe Vault logo
- [ ] Logo file is in Assets.xcassets
- [ ] Dark mode logo variant available
- [ ] Parent company logo (Arkhe Holdings) included

### Project:
- [ ] Folder renamed to `ArkheVault`
- [ ] Xcode project file renamed
- [ ] Scheme names updated
- [ ] Test target names updated
- [ ] Bundle identifier updated

---

## Quick Reference: All Files Checked

### Swift Files (34 total):
- App/ (4 files) - Entry points, main window, login
- Core/ (6 files) - Data, services, authentication
- Features/ (24 files) - All feature views
- Shared/ (4 files) - Components, utilities, branding

### Documentation (15 files):
- SECURITY_AUDIT_REPORT.md
- VALUATION_REPORT.md
- CLIENT_UPDATE.md
- IMPLEMENTATION_SUMMARY.md
- PROGRESS_AUDIT.md
- PRIORITY_IMPLEMENTATION_REPORT.md
- DEPLOYMENT_GUIDE.md
- INTEGRATION_GUIDE.md
- BUSINESS_MODEL_SAAS.md
- APPLICATION_FORM.md
- KEY_TERMS_SUMMARY.md
- PRICING_TABLE.md
- REBRAND_PLAN.md
- REBRAND_COMPLETE.md
- RENAME_AND_AUDIT.md (this file)

### Tests (3 files):
- SecurityTests.swift
- CriticalComponentTests.swift
- SecurityUITests.swift

---

## Post-Rename Commands

### After renaming, update your IDE workspace:

```bash
# If using VS Code:
cd /Users/purduelaw/Desktop/ArkheApps/StudentTracker/ArkheVault
code .

# If using Xcode:
open /Users/purduelaw/Desktop/ArkheApps/StudentTracker/ArkheVault/ArkheVault.xcodeproj
```

---

## Success Criteria

✅ **Rename Complete When:**
1. Folder is named `ArkheVault`
2. Zero grep results for "Forged In Fire"
3. Zero grep results for "ForgedInFire"
4. Zero grep results for "forgedinfire"
5. Zero grep results for "ForgeButton/ForgeCard/ForgeLogo"
6. Build succeeds with no warnings
7. App launches showing "Arkhe Vault"
8. All 85+ tests pass

---

## Troubleshooting

### If sed commands fail on macOS:
```bash
# Use gsed (GNU sed) instead:
brew install gnu-sed
# Then replace 'sed -i ''' with 'gsed -i'
```

### If Xcode project won't open:
```bash
# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Reset project
rm -rf ArkheVault.xcodeproj/project.xcworkspace
rm -rf ArkheVault.xcodeproj/xcuserdata
```

### If tests fail:
```bash
# Clean build folder
xcodebuild clean -project ArkheVault.xcodeproj -scheme ArkheVault

# Rebuild
xcodebuild build -project ArkheVault.xcodeproj -scheme ArkheVault
```

---

**Ready to Execute:** Run commands in Step 1-4 sequentially, then verify with Steps 5-10.

---

*End of Rename & Audit Guide*
