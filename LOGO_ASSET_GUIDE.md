# Logo Asset Configuration & Instructions

## Overview

This document provides step-by-step instructions for adding the Arkhe Vault logo assets to the native macOS application and configuring them for production use.

**Project Location:** `/Users/purduelaw/Desktop/ArkheApps/StudentTracker/ArkheVaultClientManager/`

---

## Table of Contents

1. [Logo Asset Requirements](#logo-asset-requirements)
2. [Asset Preparation](#asset-preparation)
3. [Adding Assets to Xcode](#adding-assets-to-xcode)
4. [Configuration Updates](#configuration-updates)
5. [Testing Logo Display](#testing-logo-display)
6. [Production Deployment](#production-deployment)

---

## Logo Asset Requirements

### Required Logo Sizes

| Size | Dimensions | Usage | File Name |
|------|------------|-------|-----------|
| App Icon | 1024x1024 | App Store, Dock | `AppIcon-1024` |
| App Icon | 512x512 | Finder, Spotlight | `AppIcon-512` |
| App Icon | 256x256 | Sidebar, Settings | `AppIcon-256` |
| App Icon | 128x128 | Small list view | `AppIcon-128` |
| App Icon | 64x64 | Badge, notifications | `AppIcon-64` |
| App Icon | 32x32 | Very small icons | `AppIcon-32` |
| App Icon | 16x16 | Tiny icons | `AppIcon-16` |
| Logo Medium | 512x512 | Login screen, headers | `logo-medium` |
| Logo Compact | 256x256 | Sidebar, cards | `logo-compact` |
| Logo Small | 128x128 | Buttons, badges | `logo-small` |
| Logo Extra Small | 64x64 | Navigation | `logo-xs` |

### Format Specifications

- **File Format:** PNG (with transparency)
- **Color Mode:** RGB or RGBA
- **DPI:** 72 DPI for standard, 144 DPI for Retina
- **Background:** Transparent PNG recommended
- **Compression:** Lossless (no compression artifacts)

### Color Specifications

The logo should use the Arkhe Vault brand colors:
- **Primary:** Forge Teal (#1E6B73)
- **Secondary:** Bronze (#8B5E3C)
- **Accent:** Warm Ivory (#FAF7F2) for text on dark backgrounds

---

## Asset Preparation

### Step 1: Prepare Logo Files

1. **Obtain the Logo**
   - Get the Arkhe Vault logo in a high-resolution format (SVG, AI, or PNG)
   - Ensure you have permission to use the logo

2. **Export Required Sizes**
   Use your design tool (Figma, Sketch, Adobe Illustrator, etc.) to export:
   
   ```
   Required Sizes:
   - AppIcon-1024.png (1024x1024)
   - AppIcon-512.png (512x512)
   - AppIcon-256.png (256x256)
   - AppIcon-128.png (128x128)
   - AppIcon-64.png (64x64)
   - AppIcon-32.png (32x32)
   - AppIcon-16.png (16x16)
   - logo-medium.png (512x512)
   - logo-compact.png (256x256)
   - logo-small.png (128x128)
   - logo-xs.png (64x64)
   ```

3. **File Naming Convention**
   - Use lowercase letters
   - Use hyphens for multi-word names
   - Use descriptive names (e.g., `logo-medium`, `AppIcon-512`)

### Step 2: Create Asset Directory Structure

```
ArkheVaultClientManager/
├── Assets.xcassets/ (Xcode will create this)
│   ├── AppIcon.appiconset/
│   └── Logo.imageset/
└── Resources/ (optional manual folder)
    └── logos/
        ├── AppIcon-1024.png
        ├── AppIcon-512.png
        ├── ...
        └── logo-medium.png
```

---

## Adding Assets to Xcode

### Option A: Using Xcode Assets Catalog (Recommended)

1. **Open Project in Xcode**
   ```bash
   open /Users/purduelaw/Desktop/ArkheApps/StudentTracker/ArkheVaultClientManager/ArkheVaultClientManager.xcodeproj
   ```

2. **Navigate to Assets Catalog**
   - In Xcode Project Navigator
   - Click on `ArkheVaultClientManager` (blue project icon)
   - Select `ArkheVaultClientManager` target
   - Go to "General" tab
   - Scroll to "App Icons and Launch Images"
   - Click on the App Icon field

3. **Add App Icons**
   - Drag and drop your AppIcon files into the appropriate slots
   - Or use the "Import" button to select files
   - Ensure all sizes are populated

4. **Create Logo Imageset**
   - In Project Navigator, right-click on `Assets.xcassets`
   - Select "New Image Set"
   - Name it `Logo`
   - Drag and drop your logo files:
     - Drag `logo-medium.png` to the 1x slot
     - Drag `logo-compact.png` to the small slot
     - Drag `logo-small.png` to the tiny slot
   - Set "Devices" to "Universal" for macOS

5. **Configure Logo Imageset**
   - In Attributes Inspector (right panel)
   - Set "Scales" to "Single Scale" for now
   - Enable "Preserve Vector Data" if using vector formats

### Option B: Manual Asset Folder (For Custom Control)

1. **Create Resources Folder**
   ```bash
   cd /Users/purduelaw/Desktop/ArkheApps/StudentTracker/ArkheVaultClientManager
   mkdir -p Resources/logos
   ```

2. **Copy Logo Files**
   ```bash
   cp /path/to/your/logos/* Resources/logos/
   ```

3. **Add to Xcode Project**
   - In Xcode, go to File → Add Files to "ArkheVaultClientManager"
   - Select the `Resources/logos` folder
   - Check "Copy items if needed"
   - Check "Create folder references"
   - Select "Created groups"

---

## Configuration Updates

### Update Branding.swift

The `Branding.swift` file already has the logo configuration. Update it to reference your actual logo assets:

```swift
// MARK: - Arkhe Vault Brand System
struct BrandSystem {
    // Brand Identity
    static let appName = "Arkhe Vault"
    static let tagline = "Strength Through Support"
    static let version = "1.0.0"
    
    // Logo Configuration
    static let logoFileName = "Logo" // Matches the imageset name in Assets.xcassets
    static let logoFileNameDark = "Logo" // Use same name for now
    static let logoFileNameCompact = "Logo" // Use same name for now
    
    // Logo Asset Names (for manual loading if needed)
    static let logoAssetName = "logo-medium"
    static let logoCompactAssetName = "logo-compact"
    static let logoSmallAssetName = "logo-small"
    static let logoXSAssetName = "logo-xs"
}
```

### Update ArkheLogo.swift to Use Actual Assets

Update the `LogoIcon` struct in `ArkheLogo.swift` to load actual assets:

```swift
// MARK: - Logo Icon
struct LogoIcon: View {
    var size: CGFloat
    
    var body: some View {
        ZStack {
            // Try to load actual logo asset
            if let image = NSImage(named: BrandSystem.logoAssetName) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .shadow(color: Color.forgeTeal.opacity(0.3), radius: 4, x: 0, y: 2)
            } else {
                // Fallback to programmatic logo if asset not found
                RoundedRectangle(cornerRadius: size * 0.15)
                    .fill(
                        LinearGradient(
                            colors: [.forgeTeal, .forgeTealLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                
                Image(systemName: "flame.fill")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundColor(.warmIvory)
            }
        }
    }
}
```

---

## Testing Logo Display

### Test Logo in Different Contexts

1. **Test in LoginView**
   - The logo should appear large on the login screen
   - Tagline should be visible
   - Logo should be centered and properly sized

2. **Test in MainWindow (Sidebar)**
   - Logo should appear in the sidebar header
   - Should use compact size
   - Should be aligned properly

3. **Test in Dashboard**
   - Logo should appear in the dashboard header
   - Should be appropriately sized
   - Should maintain visual hierarchy

4. **Test in Settings**
   - Logo should appear in footer
   - Should be compact
   - Should be centered

### Verification Checklist

- [ ] Logo appears in LoginView
- [ ] Logo appears in MainWindow sidebar
- [ ] Logo appears in Dashboard header
- [ ] Logo appears in Settings footer
- [ ] Logo sizes are appropriate for each context
- [ ] Logo maintains aspect ratio
- [ ] Logo colors match brand colors
- [ ] Logo is crisp at all sizes
- [ ] Fallback programmatic logo works if assets missing

---

## Production Deployment

### App Icon Configuration

1. **Build for App Store**
   - Ensure App Icon is configured in Assets.xcassets
   - Test in different contexts (Dock, Finder, Launchpad)
   - Verify icon looks good on both light and dark backgrounds

2. **App Store Screenshots**
   - Include logo in screenshots for App Store listing
   - Ensure logo is visible but doesn't dominate screenshots
   - Follow Apple's screenshot guidelines

3. **Icon Validation**
   - Test icon on different macOS versions
   - Verify icon displays correctly in all contexts
   - Ensure icon meets Apple's design guidelines

### Asset Bundle Configuration

1. **Verify Assets in Build**
   - Build the app (Product → Build)
   - Check that assets are included in the build
   - Verify asset file sizes are reasonable

2. **Asset Compression**
   - Xcode automatically compresses assets during build
   - Verify compressed assets still look good
   - Consider using Asset Catalog for automatic optimization

3. **Asset Versioning**
   - Use version control for your logo source files
   - Document logo version in the app (in Settings → About)
   - Consider asset versioning for future updates

---

## Troubleshooting

### Logo Not Appearing

**Issue:** Logo doesn't appear in the app

**Solutions:**
1. Check that assets are added to the correct target
2. Verify asset names match the code
3. Clean build folder (Product → Clean Build Folder)
4. Rebuild the app

**Issue:** Logo appears blurry

**Solutions:**
1. Ensure you're using high-resolution source files
2. Check that you're exporting at the correct DPI
3. Verify the asset is being rendered at the correct size
4. Consider using vector (PDF) format for sharp rendering at all sizes

**Issue:** Logo colors don't match brand colors

**Solutions:**
1. Verify logo uses the correct hex codes
2. Check for color space conversion issues
3. Ensure logo is using RGB color mode
4. Test logo on both light and dark backgrounds

---

## Alternative: Using Vector Assets

For the sharpest logo at all sizes, consider using vector assets:

### Using SVG to PDF

1. Convert your SVG logo to PDF:
   ```bash
   # Using command line tools
   rsvg-convert -f pdf -o logo-medium.pdf logo.svg
   ```

2. Add PDF to Assets.xcassets
   - Drag the PDF into the Logo imageset
   - Xcode will automatically generate all required sizes
   - This ensures the logo is sharp at all resolutions

### Benefits of Vector Assets
- ✅ Crisp at all sizes
- ✅ Automatic size generation
- ✅ Smaller bundle size
- ✅ Easy to update

---

## Asset Management Best Practices

### File Organization

```
Assets.xcassets/
├── AppIcon.appiconset/     # App icons
├── Logo.imageset/           # Logo assets
├── AccentColor.colorset/    # Brand colors
└── BrandColors.colorset/     # Additional brand colors
```

### Version Control

1. **Commit Logo Assets**
   - Add logo assets to version control
   - Create a `resources/` branch if needed
   - Document logo version in commit message

2. **Document Changes**
   - Update this document when logo changes
   - Note the version number of the new logo
   - Document any color or design changes

### Backup Strategy

1. **Store Source Files**
   - Keep original logo files in a separate location
   - Use version control for source files
   - Maintain a backup of the original design files

2. **Asset Backup**
   - Export logos in multiple formats (SVG, PNG, PDF)
   - Store backups in cloud storage
   - Document the backup location

---

## Next Steps

After adding logo assets:

1. [ ] Test logo display in all contexts
2. [ ] Verify logo on different macOS versions
3. [ ] Update App Store screenshots with new logo
4. [ ] Test icon in Dock, Finder, and Launchpad
5. [ ] Update documentation with logo screenshots
6. [ ] Commit logo assets to version control

---

## Support

**For questions or issues with logo integration:**
- Review Apple's Human Interface Guidelines for app icons
- Check Xcode documentation for Assets Catalog
- Ensure logo meets Apple's App Store guidelines

---

**Document Version:** 1.0
**Last Updated:** 2024
**Status:** Ready for Logo Asset Integration