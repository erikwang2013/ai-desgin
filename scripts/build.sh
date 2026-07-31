#!/bin/bash
# scripts/build.sh — AI Design build script
set -e

echo "=== AI Design Build ==="

# Build Rust plugins
echo "--- Building Rust plugins ---"
cd "$(dirname "$0")/../rust"
cargo build --release
cd ..

# Build Flutter app
echo "--- Building Flutter app ---"
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Building for macOS..."
    flutter build macos --release
    echo "macOS build: build/macos/Build/Products/Release/ai_design_studio.app"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    echo "Building for Windows..."
    flutter build windows --release
    echo "Windows build: build/windows/x64/runner/Release/"
else
    echo "Building for Linux (test only)..."
    flutter build linux --release
fi

echo "=== Build complete ==="
