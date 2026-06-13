# ⚡ EXECUTE RENAME NOW - Step-by-Step Commands

**Copy and paste these commands into your terminal one at a time:**

---

## Step 1: Rename Root Folder

```bash
cd /Users/purduelaw/Desktop/ArkheApps/StudentTracker
mv ArkheVaultClientManager ArkheVault
ls -la  # Verify rename worked
```

**Expected output:** You should see `ArkheVault` folder instead of `ArkheVaultClientManager`

---

## Step 2: Navigate and Execute Global Replacements

```bash
cd /Users/purduelaw/Desktop/ArkheApps/StudentTracker/ArkheVault
```

### Run these 8 commands one by one:

```bash
# Command 1: Replace "Arkhe Vault" with "Arkhe Vault"
find . -type f \( -name "*.swift" -o -name "*.md" -o -name "*.json" -o -name "*.plist" \) -exec sed -i '' 's/Arkhe Vault/Arkhe Vault/g' {} +
echo "✅ Command 1 complete"
```

```bash
# Command 2: Replace "ArkheVault" with "ArkheVault"
find . -type f \( -name "*.swift" -o -name "*.md" -o -name "*.json" -o -name "*.plist" \) -exec sed -i '' 's/ArkheVault/ArkheVault/g' {} +
echo "✅ Command 2 complete"
```

```bash
# Command 3: Replace "arkhevault" with "arkhevault"
find . -type f \( -name "*.swift" -o -name "*.md" -o -name "*.json" -o -name "*.plist" \) -exec sed -i '' 's/arkhevault/arkhevault/g' {} +
echo "✅ Command 3 complete"
```

```bash
# Command 4: Replace "com.arkheholdings.vault" with "com.arkheholdings.vault"
find . -type f \( -name "*.swift" -o -name "*.json" -o -name "*.plist" \) -exec sed -i '' 's/com\.arkhevault/com.arkheholdings.vault/g' {} +
echo "✅ Command 4 complete"
```

```bash
# Command 5: Replace "ArkheButton" with "ArkheButton"
find . -type f -name "*.swift" -exec sed -i '' 's/ArkheButton/ArkheButton/g' {} +
echo "✅ Command 5 complete"
```

```bash
# Command 6: Replace "ArkheCard" with "ArkheCard"
find . -type f -name "*.swift" -exec sed -i '' 's/ArkheCard/ArkheCard/g' {} +
echo "✅ Command 6 complete"
```

```bash
# Command 7: Replace "ArkheLogo" with "ArkheLogo"
find . -type f -name "*.swift" -exec sed -i '' 's/ArkheLogo/ArkheLogo/g' {} +
echo "✅ Command 7 complete"
```

```bash
# Command 8: Replace "ArkheVaultApp" with "ArkheVaultApp"
find . -type f -name "*.swift" -exec sed -i '' 's/ArkheVaultApp/ArkheVaultApp/g' {} +
echo "✅ Command 8 complete"
```

---

## Step 3: Rename Specific Files

```bash
# Rename main app entry point
mv App/ArkheVaultApp.swift App/ArkheVaultApp.swift 2>/dev/null || echo "Already renamed or file doesn't exist"

# Rename UI components
mv Shared/Components/ArkheButton.swift Shared/Components/ArkheButton.swift 2>/dev/null || echo "Already renamed"
mv Shared/Components/ArkheLogo.swift Shared/Components/ArkheLogo.swift 2>/dev/null || echo "Already renamed"

echo "✅ File renaming complete"
```

---

## Step 4: Verify Changes

```bash
echo "=== CHECKING FOR REMAINING 'Arkhe Vault' ==="
grep -r "Arkhe Vault" . --include="*.swift" --include="*.md" 2>/dev/null || echo "✅ None found - GOOD!"

echo ""
echo "=== CHECKING FOR REMAINING 'ArkheVault' ==="
grep -r "ArkheVault" . --include="*.swift" --include="*.md" 2>/dev/null || echo "✅ None found - GOOD!"

echo ""
echo "=== CHECKING FOR REMAINING 'ArkheButton' ==="
grep -r "ArkheButton" . --include="*.swift" 2>/dev/null || echo "✅ None found - GOOD!"

echo ""
echo "=== CHECKING FOR REMAINING 'ArkheCard' ==="
grep -r "ArkheCard" . --include="*.swift" 2>/dev/null || echo "✅ None found - GOOD!"

echo ""
echo "=== CHECKING FOR REMAINING 'ArkheLogo' ==="
grep -r "ArkheLogo" . --include="*.swift" 2>/dev/null || echo "✅ None found - GOOD!"

echo ""
echo "✅✅✅ ALL CHECKS COMPLETE ✅✅✅"
```

---

## Step 5: Open in IDE

```bash
# Open in VS Code
code /Users/purduelaw/Desktop/ArkheApps/StudentTracker/ArkheVault

# OR open Xcode project
# open /Users/purduelaw/Desktop/ArkheApps/StudentTracker/ArkheVault/ArkheVault.xcodeproj
```

---

## What These Commands Do:

| Command | Changes Made | Files Affected |
|---------|--------------|----------------|
| 1 | "Arkhe Vault" → "Arkhe Vault" | All text references |
| 2 | "ArkheVault" → "ArkheVault" | Class names, variables |
| 3 | "arkhevault" → "arkhevault" | URLs, identifiers |
| 4 | "com.arkheholdings.vault" → "com.arkheholdings.vault" | Bundle IDs, services |
| 5 | "ArkheButton" → "ArkheButton" | UI component |
| 6 | "ArkheCard" → "ArkheCard" | UI component |
| 7 | "ArkheLogo" → "ArkheLogo" | Logo component |
| 8 | "ArkheVaultApp" → "ArkheVaultApp" | App entry point |

---

## Expected Results:

**After running all commands:**
- ✅ Folder named `ArkheVault`
- ✅ No "Arkhe Vault" text anywhere in code
- ✅ No "ArkheVault" class names
- ✅ No "arkhevault" in URLs/identifiers
- ✅ All components use "Arkhe" prefix
- ✅ App entry point is `ArkheVaultApp.swift`

---

## If You See Errors:

### "No such file or directory":
The file was already renamed or doesn't exist. Continue to next command.

### "Permission denied":
Add `sudo` before the command:
```bash
sudo find . -type f ...
```

### macOS sed issues:
The commands above use macOS-compatible `sed -i ''`. If you get errors, you may need GNU sed:
```bash
brew install gnu-sed
# Then use gsed instead of sed
```

---

## Quick Test After Renaming:

```bash
# Check Branding.swift has new names
grep "appName" Shared/Utilities/Branding.swift

# Should output:
# static let appName = "Arkhe Vault"
```

---

**Total Time:** 2-3 minutes to execute all commands  
**Files Modified:** 50+ files automatically  
**Manual Work Required:** None - all automated

---

**Ready? Copy Step 1 command and paste into terminal now!**

---

*End of Execute Now Guide*
