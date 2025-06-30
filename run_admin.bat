@echo off
echo Starting Mom's Platform Admin Terminal...
echo =======================================

:: Check if Flutter is available
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter not found in PATH. Please ensure Flutter is installed and in your PATH.
    echo Visit: https://docs.flutter.dev/get-started/install
    pause
    exit /b 1
)

:: Change to the project directory
cd /d "%~dp0"

echo 📦 Installing/updating dependencies...
call flutter pub get

if %errorlevel% neq 0 (
    echo ❌ Failed to install dependencies
    pause
    exit /b 1
)

echo 🚀 Launching Admin Terminal...
echo Press Ctrl+C to exit the terminal when you're done
echo.

:: Run the admin terminal
dart run admin_launcher.dart

echo.
echo Admin terminal session ended.
pause 