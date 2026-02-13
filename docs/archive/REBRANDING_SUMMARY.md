# Sike App Rebranding Summary

This document summarizes all the changes made to rebrand the app from "Task Manager" to "Sike" with a light blue and purple/pink color scheme.

## ✅ Completed Changes

### 1. App Name Changes
- **pubspec.yaml**: Updated app name from `task_app` to `sike`
- **lib/utils/constants.dart**: Changed app name from "Task Manager" to "Sike"
- **Android**: Updated `AndroidManifest.xml` and `build.gradle` with new app name and package ID
- **iOS**: Updated `Info.plist` with new display name "Sike"
- **Package Structure**: Moved MainActivity from `com.taskmanager.task_app` to `com.sike.app`

### 2. Color Scheme Implementation
Updated [`lib/main.dart`](lib/main.dart:73) with the new color palette:

**Light Theme:**
- Primary: Light Blue (#87CEEB)
- Secondary: Pink (#E91E63)
- Tertiary: Purple (#9C27B0)
- AppBar: Light blue background with white text
- FAB: Pink background with white icon

**Dark Theme:**
- Primary: Darker Light Blue (#5FA8D3)
- Secondary: Darker Pink (#C2185B)
- Tertiary: Darker Purple (#7B1FA2)
- AppBar: Darker blue with white text
- FAB: Darker pink with white icon

### 3. Splash Screen
- Added `flutter_native_splash` package (v2.2.9)
- Configured splash screen with light blue background (#87CEEB) for light mode
- Configured splash screen with darker blue background (#5FA8D3) for dark mode
- Successfully generated native splash screens for Android and iOS

### 4. Logo Assets
- Created SVG logo template at [`assets/images/logo.svg`](assets/images/logo.svg:1)
- Added `flutter_launcher_icons` package for icon generation
- Created assets directory structure

## 📝 Next Steps (Manual)

### Create the Final Logo
The logo needs to be created as a PNG file. You have two options:

**Option 1: Use the provided SVG template**
1. Open [`assets/images/logo.svg`](assets/images/logo.svg:1) in a design tool (Figma, Inkscape, etc.)
2. Customize it as needed
3. Export as `assets/images/logo.png` (512x512px recommended)

**Option 2: Create a new logo**
1. Create a 512x512px image using your preferred tool (Canva, Photoshop, etc.)
2. Use the color scheme:
   - Light Blue: #87CEEB
   - Pink: #E91E63
   - Purple: #9C27B0
3. Save as `assets/images/logo.png`

### Generate App Icons
Once you have the `logo.png` file:
```bash
flutter pub run flutter_launcher_icons:main
```

This will generate all the required icon sizes for Android and iOS.

### Update Splash Screen with Logo (Optional)
If you want to add the logo to the splash screen:

1. Uncomment these lines in [`pubspec.yaml`](pubspec.yaml:52):
```yaml
flutter_native_splash:
  color: "#87CEEB"
  color_dark: "#5FA8D3"
  image: assets/images/logo.png  # Uncomment this line
  android: true
  ios: true
```

2. Run:
```bash
flutter pub run flutter_native_splash:create
```

## 🚀 Testing the Changes

Run the app to see the new branding:
```bash
flutter run
```

You should see:
- App name "Sike" in the app bar and device app list
- Light blue and pink/purple color scheme throughout
- Light blue splash screen on app launch

## 📦 Added Dependencies
- `flutter_native_splash: ^2.2.9` - For splash screen generation
- `flutter_launcher_icons: ^0.10.0` - For app icon generation

## 🎨 Design Files
- [`assets/images/logo.svg`](assets/images/logo.svg:1) - SVG logo template
- [`assets/images/README.md`](assets/images/README.md:1) - Asset documentation
- [`create_logo.py`](create_logo.py:1) - Python script for logo generation (requires Pillow)

## 💡 Tips
- The color scheme can be easily adjusted in [`lib/main.dart`](lib/main.dart:73)
- To change the app name, update [`lib/utils/constants.dart`](lib/utils/constants.dart:6)
- All platform-specific configurations are now updated with the new package ID: `com.sike.app`