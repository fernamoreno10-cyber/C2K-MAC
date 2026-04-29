#!/bin/bash
set -e
set -o pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="C2K"
BINARY_NAME="KeyboardCleaner"
APP_BUNDLE="$PROJECT_DIR/$APP_NAME.app"

command -v swift >/dev/null 2>&1 || { echo "Error: swift not found in PATH"; exit 1; }

echo "→ Building release binary..."
cd "$PROJECT_DIR"
swift build -c release

BINARY="$PROJECT_DIR/.build/release/$BINARY_NAME"
[[ -f "$BINARY" ]] || { echo "Error: binary not found at $BINARY"; exit 1; }

echo "→ Assembling .app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BINARY" "$APP_BUNDLE/Contents/MacOS/$BINARY_NAME"

cat > "$APP_BUNDLE/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>C2K</string>
    <key>CFBundleDisplayName</key>
    <string>C2K</string>
    <key>CFBundleIdentifier</key>
    <string>com.c2k.app</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>KeyboardCleaner</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSAccessibilityUsageDescription</key>
    <string>C2K necesita acceso de Accesibilidad para bloquear el teclado mientras lo limpias.</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "→ Ad-hoc signing..."
codesign --sign - --force --deep "$APP_BUNDLE"

echo ""
echo "✓ Built: $APP_BUNDLE"
echo "→ Launch: open \"$APP_BUNDLE\""
