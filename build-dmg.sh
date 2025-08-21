#!/bin/bash

# MyTides DMG Builder Script
# This script builds a release version of MyTides and creates a DMG installer

set -e

echo "🌊 Building MyTides for Release..."

# Clean previous builds
rm -rf build
rm -f MyTides.dmg

# Build the app for release
xcodebuild -scheme mytidesapp \
           -configuration Release \
           -derivedDataPath build \
           CODE_SIGN_IDENTITY="" \
           CODE_SIGNING_REQUIRED=NO \
           CODE_SIGNING_ALLOWED=NO

echo "📦 Creating DMG installer..."

# Create a temporary directory for DMG contents
mkdir -p build/dmg
cp -R "build/Build/Products/Release/mytidesapp.app" "build/dmg/MyTides.app"

# Create a symbolic link to Applications folder
ln -s /Applications build/dmg/Applications

# Create the DMG
hdiutil create -volname "MyTides" \
               -srcfolder build/dmg \
               -ov \
               -format UDZO \
               MyTides.dmg

# Clean up
rm -rf build

echo "✅ DMG created successfully: MyTides.dmg"
echo ""
echo "Installation instructions:"
echo "1. Open MyTides.dmg"
echo "2. Drag MyTides to the Applications folder"
echo "3. Launch MyTides from Applications"
echo "4. Right-click on your desktop and select 'Edit Widgets'"
echo "5. Find and add the MyTides widget"