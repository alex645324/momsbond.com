#!/usr/bin/env pwsh

Write-Host ""
Write-Host "===============================================" -ForegroundColor Green
Write-Host "       Running Returning User Flow Test" -ForegroundColor Green  
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""

# Navigate to script directory
Set-Location $PSScriptRoot

Write-Host "Running: dart test_returning_user_flow.dart" -ForegroundColor Yellow
Write-Host ""

# Run the test
dart test_returning_user_flow.dart

Write-Host ""
Write-Host "Test completed. Check output above for results." -ForegroundColor Green 