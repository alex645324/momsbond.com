@echo off
echo.
echo ================================================================================
echo                    ACTIVE USER MATCHING TEST RUNNER
echo ================================================================================
echo.

echo 🔧 Checking Flutter environment...
flutter --version
if errorlevel 1 (
    echo ❌ Flutter not found! Please install Flutter and add it to PATH
    pause
    exit /b 1
)

echo.
echo 🧪 Running Active User Matching Tests...
echo.

dart run test_active_matching.dart

echo.
echo 📊 Test execution completed.
echo.
pause 