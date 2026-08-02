#!/bin/bash
# scripts/release.sh — Create release packages
set -e

cd "$(dirname "$0")/.."

VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
RELEASE_DIR="release/$VERSION"
mkdir -p "$RELEASE_DIR"

if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "--- Creating macOS .app bundle ---"
    flutter build macos --release
    cp -R build/macos/Build/Products/Release/ai_design_studio.app "$RELEASE_DIR/"
    cd "$RELEASE_DIR"
    zip -r "AI-Design-Studio-macOS-$VERSION.zip" ai_design_studio.app
    echo "macOS package: $RELEASE_DIR/AI-Design-Studio-macOS-$VERSION.zip"

elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    echo "--- Creating Windows package ---"
    flutter build windows --release
    mkdir -p "$RELEASE_DIR/AI-Design-Studio"
    cp -R build/windows/x64/runner/Release/* "$RELEASE_DIR/AI-Design-Studio/"
    cd "$RELEASE_DIR"
    powershell Compress-Archive -Path "AI-Design-Studio" -DestinationPath "AI-Design-Studio-Windows-$VERSION.zip"
    echo "Windows package: $RELEASE_DIR/AI-Design-Studio-Windows-$VERSION.zip"
fi
