#!/bin/bash
# Build Awake.app (universal: Apple Silicon and Intel). No Xcode project
# needed, just the Swift toolchain (`xcode-select --install`).
#
#   bash scripts/build.sh [version]
#   open build/Awake.app
#
# For DISTRIBUTION you must then sign and notarize: see scripts/package.sh.

set -euo pipefail

VERSION="${1:-1.0.0}"
APP="Awake"
BUNDLE_ID="io.github.pistachionet.awake"
SRC="Sources/Awake/AwakeApp.swift"
OUT="build"
BUNDLE="$OUT/$APP.app"
FRAMEWORKS=(-framework SwiftUI -framework AppKit -framework ServiceManagement)

rm -rf "$OUT"
mkdir -p "$BUNDLE/Contents/MacOS"

echo "Compiling universal Awake $VERSION..."
swiftc -O -parse-as-library "$SRC" "${FRAMEWORKS[@]}" -target arm64-apple-macos13.0  -o "$OUT/$APP-arm64"
swiftc -O -parse-as-library "$SRC" "${FRAMEWORKS[@]}" -target x86_64-apple-macos13.0 -o "$OUT/$APP-x86_64"
lipo -create -output "$BUNDLE/Contents/MacOS/$APP" "$OUT/$APP-arm64" "$OUT/$APP-x86_64"
rm -f "$OUT/$APP-arm64" "$OUT/$APP-x86_64"
# If cross-arch compile fails on your toolchain, drop one -target line.

cat > "$BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>$APP</string>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
  <key>CFBundleName</key><string>$APP</string>
  <key>CFBundleDisplayName</key><string>$APP</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHumanReadableCopyright</key><string>MIT License</string>
</dict>
</plist>
EOF

echo "Built $BUNDLE  (arches: $(lipo -archs "$BUNDLE/Contents/MacOS/$APP"))"
echo "Local run:  open $BUNDLE"
