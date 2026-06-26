#!/bin/bash
# Sign (Developer ID and hardened runtime), notarize, staple, and zip
# Awake.app into a distributable artifact, then print the sha256 for the cask.
#
#   bash scripts/build.sh   1.0.0
#   bash scripts/package.sh 1.0.0
#
# One time prerequisites (Apple Developer account, 99 USD per year):
#   1. A "Developer ID Application" certificate installed in your keychain.
#   2. A stored notarytool profile holding an app specific password:
#        xcrun notarytool store-credentials NOTARY_PROFILE \
#          --apple-id you@example.com --team-id TEAMID --password APP_SPECIFIC_PW
#
# Then export:
#   export DEV_ID_APP="Developer ID Application: Your Name (TEAMID)"
#   export NOTARY_PROFILE="NOTARY_PROFILE"

set -euo pipefail

VERSION="${1:-1.0.0}"
APP="Awake"
BUNDLE="build/$APP.app"
DIST="dist"
ZIP="$DIST/$APP-$VERSION.zip"

: "${DEV_ID_APP:?set DEV_ID_APP to your 'Developer ID Application: ...' identity}"
: "${NOTARY_PROFILE:?set NOTARY_PROFILE to your stored notarytool profile name}"
[ -d "$BUNDLE" ] || { echo "Missing $BUNDLE. Run scripts/build.sh first."; exit 1; }

mkdir -p "$DIST"

echo "==> Codesigning with hardened runtime..."
codesign --force --options runtime --timestamp --sign "$DEV_ID_APP" "$BUNDLE"
codesign --verify --strict --verbose=2 "$BUNDLE"

echo "==> Zipping for notarization..."
/usr/bin/ditto -c -k --keepParent "$BUNDLE" "$ZIP"

echo "==> Submitting to Apple notary service (a few minutes)..."
xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARY_PROFILE" --wait

echo "==> Stapling the ticket..."
xcrun stapler staple "$BUNDLE"

echo "==> Re-zipping the stapled app for release..."
rm -f "$ZIP"
/usr/bin/ditto -c -k --keepParent "$BUNDLE" "$ZIP"

echo "==> Gatekeeper assessment:"
spctl --assess --type execute --verbose=2 "$BUNDLE" || true

SHA=$(shasum -a 256 "$ZIP" | awk '{print $1}')
cat <<EOF

Done: $ZIP
   version: $VERSION
   sha256:  $SHA

Next:
  1. Upload $ZIP to a GitHub release tagged v$VERSION.
  2. Set version "$VERSION" and sha256 "$SHA" in the tap's Casks/awake.rb, push.
EOF
