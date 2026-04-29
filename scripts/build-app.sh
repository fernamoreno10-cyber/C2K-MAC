#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="KeyboardCleaner"
APP_BUNDLE="$PROJECT_DIR/$APP_NAME.app"

echo "→ Building release binary..."
cd "$PROJECT_DIR"
swift build -c release

BINARY=".build/release/$APP_NAME"

echo "→ Assembling .app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BINARY" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

cat > "$APP_BUNDLE/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>KeyboardCleaner</string>
    <key>CFBundleDisplayName</key>
    <string>Keyboard Cleaner</string>
    <key>CFBundleIdentifier</key>
    <string>com.keyboardcleaner.app</string>
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
    <string>Keyboard Cleaner necesita acceso de Accesibilidad para bloquear el teclado mientras lo limpias.</string>
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
