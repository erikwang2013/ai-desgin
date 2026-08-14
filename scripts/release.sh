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
    # 与 CI build.yml mac 分支一致：嵌入 FFI 动态库、修正 rpath、重新签名
    APP=build/macos/Build/Products/Release/ai_design_studio.app
    mkdir -p "$APP/Contents/Frameworks"
    cp rust/target/release/libai_design_core.dylib "$APP/Contents/Frameworks/"
    install_name_tool -id @rpath/libai_design_core.dylib "$APP/Contents/Frameworks/libai_design_core.dylib"
    codesign --force --deep --sign - "$APP"
    cp -R "$APP" "$RELEASE_DIR/Ai Desgin.app"
    cd "$RELEASE_DIR"
    zip -r "Ai Desgin-$VERSION-macos.zip" "Ai Desgin.app"
    echo "macOS package: $RELEASE_DIR/Ai Desgin-$VERSION-macos.zip"

elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    echo "--- Creating Windows package ---"
    flutter build windows --release
    # FFI 动态库拷入 runner 目录，RustLib.init() 从可执行目录 dlopen
    cp rust/target/release/ai_design_core.dll build/windows/x64/runner/Release/
    mkdir -p "$RELEASE_DIR/Ai Desgin"
    cp -R build/windows/x64/runner/Release/* "$RELEASE_DIR/Ai Desgin/"
    cd "$RELEASE_DIR"
    powershell Compress-Archive -Path "Ai Desgin" -DestinationPath "Ai Desgin-$VERSION-windows.zip"
    echo "Windows package: $RELEASE_DIR/Ai Desgin-$VERSION-windows.zip"

else
    echo "--- Creating Linux package ---"
    flutter build linux --release
    mkdir -p "$RELEASE_DIR/Ai Desgin"
    cp -R build/linux/x64/release/bundle/* "$RELEASE_DIR/Ai Desgin/"
    cd "$RELEASE_DIR"
    tar -czf "Ai Desgin-$VERSION-linux.tar.gz" "Ai Desgin"
    echo "Linux package: $RELEASE_DIR/Ai Desgin-$VERSION-linux.tar.gz"
fi
