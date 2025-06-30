#!/usr/bin/env pwsh

Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "                    ACTIVE USER MATCHING TEST RUNNER" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "🔧 Checking Flutter environment..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter command failed"
    }
    Write-Host $flutterVersion -ForegroundColor Green
} catch {
    Write-Host "❌ Flutter not found! Please install Flutter and add it to PATH" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "🧪 Running Active User Matching Tests..." -ForegroundColor Yellow
Write-Host ""

try {
    dart run test_active_matching.dart
    $testResult = $LASTEXITCODE
} catch {
    Write-Host "❌ Failed to run tests: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
if ($testResult -eq 0) {
    Write-Host "📊 Test execution completed successfully!" -ForegroundColor Green
} else {
    Write-Host "📊 Test execution completed with errors." -ForegroundColor Red
}
Write-Host ""

Read-Host "Press Enter to exit" 