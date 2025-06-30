#!/usr/bin/env pwsh

Write-Host "Starting Mom's Platform Admin Terminal..." -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green

# Check if Flutter is available
if (-not (Get-Command "flutter" -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Flutter not found in PATH. Please ensure Flutter is installed and in your PATH." -ForegroundColor Red
    Write-Host "Visit: https://docs.flutter.dev/get-started/install" -ForegroundColor Yellow
    exit 1
}

# Change to the project directory (if script is run from elsewhere)
Set-Location -Path $PSScriptRoot

Write-Host "📦 Installing/updating dependencies..." -ForegroundColor Blue
flutter pub get

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
    exit 1
}

Write-Host "🚀 Launching Admin Terminal..." -ForegroundColor Green
Write-Host "Press Ctrl+C to exit the terminal when you're done" -ForegroundColor Yellow
Write-Host ""

# Run the admin terminal
dart run admin_launcher.dart

Write-Host ""
Write-Host "Admin terminal session ended." -ForegroundColor Green 