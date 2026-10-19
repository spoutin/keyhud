#!/bin/bash
set -e

APP_DIR="/Applications/KeyHUD.app"
BIN_NAME="KeyHUD"
CONFIG_DIR="$HOME/.config/keyhud"

echo "==> Compiling KeyHUD..."
swiftc -sdk $(xcrun --show-sdk-path) -O -target arm64-apple-macos14.0 "$CONFIG_DIR/KeyHUD.swift" -o "/tmp/$BIN_NAME"

echo "==> Creating App Bundle at $APP_DIR..."
# Kill any running instance first
killall KeyHUD 2>/dev/null || true

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "/tmp/$BIN_NAME" "$APP_DIR/Contents/MacOS/$BIN_NAME"
chmod +x "$APP_DIR/Contents/MacOS/$BIN_NAME"

cat << 'EOF' > "$APP_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>KeyHUD</string>
    <key>CFBundleIdentifier</key>
    <string>com.ablack.KeyHUD</string>
    <key>CFBundleName</key>
    <string>KeyHUD</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "==> Ad-hoc signing KeyHUD..."
codesign --force --deep --sign - "$APP_DIR"

echo "==> Done! KeyHUD installed to $APP_DIR."
