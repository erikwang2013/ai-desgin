#!/bin/bash
# scripts/release.sh — Create release packages
set -e

cd "$(dirname "$0")/.."

VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
RELEASE_DIR="release/$VERSION"
mkdir -p "$RELEASE_DIR"

# Rust FFI core 是 App 运行时权威插件源，发布前必须编译
echo "--- Building Rust core (FFI) ---"
cd rust
cargo build --release -p ai_design_core
cd ..

if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "--- Creating macOS .app bundle ---"
    flutter build macos --release
    # TODO(真机验证): 将 libai_design_core.dylib 拷入 .app/Contents/Frameworks 并 codesign；
    # 本机无 macOS 环境无法验证 rpath/签名。
    cp -R build/macos/Build/Products/Release/ai_design_studio.app "$RELEASE_DIR/"
    cd "$RELEASE_DIR"
    zip -r "AI-Design-Studio-macOS-$VERSION.zip" ai_design_studio.app
    echo "macOS package: $RELEASE_DIR/AI-Design-Studio-macOS-$VERSION.zip"

elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    echo "--- Creating Windows package ---"
    flutter build windows --release
    # FFI 动态库拷入 runner 目录，RustLib.init() 从可执行目录 dlopen
    cp rust/target/release/ai_design_core.dll build/windows/x64/runner/Release/
    mkdir -p "$RELEASE_DIR/AI-Design-Studio"
    cp -R build/windows/x64/runner/Release/* "$RELEASE_DIR/AI-Design-Studio/"
    cd "$RELEASE_DIR"
    powershell Compress-Archive -Path "AI-Design-Studio" -DestinationPath "AI-Design-Studio-Windows-$VERSION.zip"
    echo "Windows package: $RELEASE_DIR/AI-Design-Studio-Windows-$VERSION.zip"

else
    echo "--- Creating Linux package ---"
    flutter build linux --release
    mkdir -p "$RELEASE_DIR/AI-Design-Studio"
    cp -R build/linux/x64/release/bundle/* "$RELEASE_DIR/AI-Design-Studio/"
    cd "$RELEASE_DIR"
    tar -czf "AI-Design-Studio-Linux-$VERSION.tar.gz" AI-Design-Studio
    echo "Linux package: $RELEASE_DIR/AI-Design-Studio-Linux-$VERSION.tar.gz"
fi
