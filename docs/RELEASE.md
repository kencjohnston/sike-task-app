# Release & Build Guide

## Build Instructions

### Prerequisites
*   Flutter SDK (Latest Stable)
*   Android Studio / Xcode

### Commands
```bash
# Clean
flutter clean
flutter pub get

# Build APK (Debug)
flutter build apk --debug

# Build App Bundle (Release)
flutter build appbundle --release

# Build iOS
flutter build ios --release
```

## Release Process (Play Store)

### 1. Versioning
*   Update `version` in `pubspec.yaml` (e.g., `1.2.0+2`).
*   Increment build number (+1) for every release.

### 2. Signing
*   Ensure `android/key.properties` exists and is correct.
*   **NEVER** commit keystore files.

### 3. Testing
*   Run `flutter analyze`.
*   Run `flutter test`.
*   Install release build on physical device.

### 4. Deployment
*   Upload `.aab` to Google Play Console.
*   Update release notes.
*   Submit for review.

## Verification Checklist

- [ ] App Name is "Sike".
- [ ] Package ID is `com.sike.app`.
- [ ] Splash screen works (Light/Dark).
- [ ] App Icon is correct.
- [ ] No debug logs in release.
