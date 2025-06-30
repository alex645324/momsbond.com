@echo off
echo.
echo ===============================================
echo        Running Returning User Flow Test
echo ===============================================
echo.

cd /d "%~dp0"

echo Running: dart test_returning_user_flow.dart
echo.
dart test_returning_user_flow.dart

echo.
echo Test completed. Check output above for results.
pause 