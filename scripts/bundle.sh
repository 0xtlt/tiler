#!/bin/bash
set -euo pipefail

ARCH="${1:-$(uname -m)}"
APP_NAME="Tiler"
BUNDLE_DIR="dist/${APP_NAME}.app"

echo "Building for ${ARCH}..."
swift build -c release --arch "$ARCH"

echo "Creating app bundle..."
rm -rf "$BUNDLE_DIR"
mkdir -p "$BUNDLE_DIR/Contents/MacOS"
mkdir -p "$BUNDLE_DIR/Contents/Resources"

cp ".build/release/${APP_NAME}" "$BUNDLE_DIR/Contents/MacOS/${APP_NAME}"
cp Info.plist "$BUNDLE_DIR/Contents/Info.plist"

echo "Zipping..."
cd dist
zip -r "${APP_NAME}-${ARCH}.zip" "${APP_NAME}.app"
cd ..

echo "Done: dist/${APP_NAME}-${ARCH}.zip"
