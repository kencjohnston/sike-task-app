# Logo Assets

This directory contains the app logo and related assets.

## Logo Requirements

For the splash screen to work properly, you need a `logo.png` file (512x512px recommended) with:
- Light blue (#87CEEB) background
- Pink (#E91E63) and purple (#9C27B0) accent colors
- A checkmark or "S" symbol in white

## Temporary Solution

For now, we'll use the default Flutter launcher icon. To create a custom logo:

1. Create a 512x512 PNG image with the color scheme above
2. Save it as `assets/images/logo.png`
3. Run: `flutter pub run flutter_native_splash:create`

Or use an online tool like:
- Canva (https://www.canva.com)
- Figma (https://www.figma.com)
- GIMP (https://www.gimp.org)