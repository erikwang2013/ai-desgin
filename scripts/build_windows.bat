@echo off
REM scripts/build_windows.bat — AI Design Windows build
echo === AI Design Windows Build ===

echo --- Building Rust plugins ---
cd /d "%~dp0\..\rust"
cargo build --release
cd ..

echo --- Building Flutter app ---
flutter build windows --release

echo === Build complete ===
echo Windows build: build\windows\x64\runner\Release\
