@echo off
REM scripts/build_windows.bat — AI Design Windows build
echo === AI Design Windows Build ===

echo --- Building Rust plugins ---
cd /d "%~dp0\..\rust"
cargo build --release
cd ..

echo --- Building Rust core (FFI) ---
cd /d "%~dp0\..\rust"
cargo build --release -p ai_design_core
cd ..

echo --- Building Flutter app ---
flutter build windows --release

REM FFI 动态库拷入 runner 目录，RustLib.init() 从可执行目录 dlopen
copy /Y rust\target\release\ai_design_core.dll build\windows\x64\runner\Release\

echo === Build complete ===
echo Windows build: build\windows\x64\runner\Release\
