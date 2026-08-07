#!/bin/bash
# scripts/build.sh — AI Design build script
set -e

echo "=== AI Design Build ==="

# Build Rust plugins
echo "--- Building Rust plugins ---"
cd "$(dirname "$0")/../rust"
cargo build --release
cd ..

# Build Rust FFI core (flutter_rust_bridge dlopen 目标)
echo "--- Building Rust core (FFI) ---"
cd "$(dirname "$0")/../rust"
cargo build --release -p ai_design_core
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
    # FFI 动态库拷入 bundle，RustLib.init() 从可执行目录 dlopen
    mkdir -p build/linux/x64/release/bundle/lib
    cp rust/target/release/libai_design_core.so build/linux/x64/release/bundle/lib/
fi

echo "=== Build complete ==="
