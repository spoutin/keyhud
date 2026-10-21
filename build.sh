#!/bin/bash
set -e

# Output and directory configuration
OUTPUT_DIR="${OUTPUT_DIR:-/Applications/KeyHUD.app}"
CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_NAME="KeyHUD"
ENTITLEMENTS="$CONFIG_DIR/KeyHUD.entitlements"
VERSION="${VERSION:-1.0.0}"

echo "==> Compiling KeyHUD (v$VERSION)..."
SWIFT_SOURCES=$(find "$CONFIG_DIR/Sources/KeyHUD" -name "*.swift" | sort)
swiftc -sdk $(xcrun --show-sdk-path) -O -whole-module-optimization -target arm64-apple-macos14.0 $SWIFT_SOURCES -o "/tmp/$BIN_NAME"

echo "==> Creating App Bundle at $OUTPUT_DIR..."
# If deploying directly to /Applications, quit any running instance
if [ "$OUTPUT_DIR" = "/Applications/KeyHUD.app" ]; then
    killall KeyHUD 2>/dev/null || true
fi

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/Contents/MacOS"
mkdir -p "$OUTPUT_DIR/Contents/Resources"

# Copy Resources (AppIcon.icns, etc)
cp -r "$CONFIG_DIR/Sources/KeyHUD/Resources/"* "$OUTPUT_DIR/Contents/Resources/" 2>/dev/null || true

cp "/tmp/$BIN_NAME" "$OUTPUT_DIR/Contents/MacOS/$BIN_NAME"
chmod +x "$OUTPUT_DIR/Contents/MacOS/$BIN_NAME"

cat << EOF > "$OUTPUT_DIR/Contents/Info.plist"
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
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

if [ -n "$CODESIGN_IDENTITY" ]; then
    echo "==> Production code signing with identity '$CODESIGN_IDENTITY' (Hardened Runtime)..."
    codesign --force --deep --verify --verbose \
        --options runtime \
        --entitlements "$ENTITLEMENTS" \
        --sign "$CODESIGN_IDENTITY" \
        "$OUTPUT_DIR"
else
    echo "==> Ad-hoc signing KeyHUD with stable designated requirement..."
    codesign --force --deep -s - -r '=designated => identifier "com.ablack.KeyHUD"' "$OUTPUT_DIR"
fi

# Verification
echo "==> Verifying signature..."
codesign -vvv --deep --strict "$OUTPUT_DIR"

# Optional packaging
if [ "$PACKAGE_ZIP" = "true" ]; then
    ZIP_PATH="${ZIP_PATH:-$CONFIG_DIR/KeyHUD-$VERSION.zip}"
    echo "==> Creating ZIP archive at $ZIP_PATH..."
    ditto -c -k --keepParent "$OUTPUT_DIR" "$ZIP_PATH"
fi

if [ "$PACKAGE_DMG" = "true" ]; then
    DMG_PATH="${DMG_PATH:-$CONFIG_DIR/KeyHUD-$VERSION.dmg}"
    DMG_TMP="/tmp/keyhud_dmg_tmp"
    echo "==> Creating DMG at $DMG_PATH..."
    rm -rf "$DMG_TMP" "$DMG_PATH"
    mkdir -p "$DMG_TMP"
    cp -R "$OUTPUT_DIR" "$DMG_TMP/"
    ln -s /Applications "$DMG_TMP/Applications"
    hdiutil create -volname "KeyHUD" -srcfolder "$DMG_TMP" -ov -format UDZO "$DMG_PATH"
    rm -rf "$DMG_TMP"

    if [ -n "$CODESIGN_IDENTITY" ]; then
        echo "==> Signing DMG with identity '$CODESIGN_IDENTITY'..."
        codesign --force --verify --verbose --sign "$CODESIGN_IDENTITY" "$DMG_PATH"
    fi
fi

echo "==> Done! KeyHUD successfully built."
