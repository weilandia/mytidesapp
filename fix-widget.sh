#!/bin/bash

echo "🔧 Fixing MyTides Widget Installation..."

# Kill any existing widget processes
echo "Stopping widget processes..."
killall MyTides 2>/dev/null || true
killall mytideswidgetExtension 2>/dev/null || true

# Clean build artifacts
echo "Cleaning build artifacts..."
rm -rf ~/Library/Developer/Xcode/DerivedData/mytidesapp-*
rm -rf build
rm -rf /Applications/MyTides.app

# Clean widget cache
echo "Clearing widget cache..."
defaults delete com.apple.notificationcenterui 2>/dev/null || true
killall NotificationCenter 2>/dev/null || true

# Build fresh
echo "Building release version..."
xcodebuild -scheme mytidesapp \
           -configuration Release \
           -derivedDataPath build \
           CODE_SIGN_IDENTITY="" \
           CODE_SIGNING_REQUIRED=NO \
           CODE_SIGNING_ALLOWED=NO \
           clean build

# Install to Applications
echo "Installing to Applications..."
cp -R "build/Build/Products/Release/mytidesapp.app" "/Applications/MyTides.app"

# Launch the app once to register widget
echo "Launching app to register widget..."
open -a MyTides
sleep 2

# Restart widget service
echo "Restarting widget service..."
killall WidgetKit-Simulator 2>/dev/null || true
killall chronod 2>/dev/null || true

echo ""
echo "✅ Done! To add the widget:"
echo "1. Right-click on your desktop"
echo "2. Select 'Edit Widgets'"
echo "3. Search for 'MyTides'"
echo "4. If still not visible, try logging out and back in"
echo ""
echo "Note: You may need to wait a few seconds for the widget to appear in the gallery."