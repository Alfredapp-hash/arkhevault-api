# ⚡ EXECUTE RENAME NOW - Step-by-Step Commands

**Copy and paste these commands into your terminal one at a time:**

---

## Step 1: Rename Root Folder

```bash
cd /Users/purduelaw/Desktop/ArkheApps/StudentTracker
mv ForgedInFireClientManager ArkheVault
ls -la  # Verify rename worked
```

**Expected output:** You should see `ArkheVault` folder instead of `ForgedInFireClientManager`

---

## Step 2: Navigate and Execute Global Replacements

```bash
cd /Users/purduelaw/Desktop/ArkheApps/StudentTracker/ArkheVault
```

### Run these 8 commands one by one:

```bash
# Command 1: Replace "Forged In Fire" with "Arkhe Vault"
find . -type f \( -name "*.swift" -o -name "*.md" -o -name "*.json" -o -name "*.plist" \) -exec sed -i '' 's/Forged In Fire/Arkhe Vault/g' {} +
echo "✅ Command 1 complete"
```

```bash
# Command 2: Replace "ForgedInFire" with "ArkheVault"
find . -type f \( -name "*.swift" -o -name "*.md" -o -name "*.json" -o -name "*.plist" \) -exec sed -i '' 's/ForgedInFire/ArkheVault/g' {} +
echo "✅ Command 2 complete"
```

```bash
# Command 3: Replace "forgedinfire" with "arkhevault"
find . -type f \( -name "*.swift" -o -name "*.md" -o -name "*.json" -o -name "*.plist" \) -exec sed -i '' 's/forgedinfire/arkhevault/g' {} +
echo "✅ Command 3 complete"
```

```bash
# Command 4: Replace "com.forgedinfire" with "com.arkheholdings.vault"
find . -type f \( -name "*.swift" -o -name "*.json" -o -name "*.plist" \) -exec sed -i '' 's/com\.forgedinfire/com.arkheholdings.vault/g' {} +
echo "✅ Command 4 complete"
```

```bash
# Command 5: Replace "ForgeButton" with "ArkheButton"
find . -type f -name "*.swift" -exec sed -i '' 's/ForgeButton/ArkheButton/g' {} +
echo "✅ Command 5 complete"
```

```bash
# Command 6: Replace "ForgeCard" with "ArkheCard"
find . -type f -name "*.swift" -exec sed -i '' 's/ForgeCard/ArkheCard/g' {} +
echo "✅ Command 6 complete"
```

```bash
# Command 7: Replace "ForgeLogo" with "ArkheLogo"
find . -type f -name "*.swift" -exec sed -i '' 's/ForgeLogo/ArkheLogo/g' {} +
echo "✅ Command 7 complete"
```

```bash
# Command 8: Replace "ForgedInFireApp" with "ArkheVaultApp"
find . -type f -name "*.swift" -exec sed -i '' 's/ForgedInFireApp/ArkheVaultApp/g' {} +
echo "✅ Command 8 complete"
```

---

## Step 3: Rename Specific Files

```bash
# Rename main app entry point
mv App/ForgedInFireApp.swift App/ArkheVaultApp.swift 2>/dev/null || echo "Already renamed or file doesn't exist"

# Rename UI components
mv Shared/Components/ForgeButton.swift Shared/Components/ArkheButton.swift 2>/dev/null || echo "Already renamed"
mv Shared/Components/ForgeLogo.swift Shared/Components/ArkheLogo.swift 2>/dev/null || echo "Already renamed"

echo "✅ File renaming complete"
```

---

## Step 4: Verify Changes

```bash
echo "=== CHECKING FOR REMAINING 'Forged In Fire' ==="
grep -r "Forged In Fire" . --include="*.swift" --include="*.md" 2>/dev/null || echo "✅ None found - GOOD!"

echo ""
echo "=== CHECKING FOR REMAINING 'ForgedInFire' ==="
grep -r "ForgedInFire" . --include="*.swift" --include="*.md" 2>/dev/null || echo "✅ None found - GOOD!"

echo ""
echo "=== CHECKING FOR REMAINING 'ForgeButton' ==="
grep -r "ForgeButton" . --include="*.swift" 2>/dev/null || echo "✅ None found - GOOD!"

echo ""
echo "=== CHECKING FOR REMAINING 'ForgeCard' ==="
grep -r "ForgeCard" . --include="*.swift" 2>/dev/null || echo "✅ None found - GOOD!"

echo ""
echo "=== CHECKING FOR REMAINING 'ForgeLogo' ==="
grep -r "ForgeLogo" . --include="*.swift" 2>/dev/null || echo "✅ None found - GOOD!"

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
| 1 | "Forged In Fire" → "Arkhe Vault" | All text references |
| 2 | "ForgedInFire" → "ArkheVault" | Class names, variables |
| 3 | "forgedinfire" → "arkhevault" | URLs, identifiers |
| 4 | "com.forgedinfire" → "com.arkheholdings.vault" | Bundle IDs, services |
| 5 | "ForgeButton" → "ArkheButton" | UI component |
| 6 | "ForgeCard" → "ArkheCard" | UI component |
| 7 | "ForgeLogo" → "ArkheLogo" | Logo component |
| 8 | "ForgedInFireApp" → "ArkheVaultApp" | App entry point |

---

## Expected Results:

**After running all commands:**
- ✅ Folder named `ArkheVault`
- ✅ No "Forged In Fire" text anywhere in code
- ✅ No "ForgedInFire" class names
- ✅ No "forgedinfire" in URLs/identifiers
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
