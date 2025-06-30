Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    SIMPLE MATCHING TEST RUNNER" -ForegroundColor Cyan  
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "🚀 Starting matching functionality test..." -ForegroundColor Green
Write-Host ""

try {
    dart test_matching_simple.dart
    Write-Host ""
    Write-Host "✅ Test completed successfully!" -ForegroundColor Green
} catch {
    Write-Host ""
    Write-Host "❌ Test failed: $_" -ForegroundColor Red
}

Write-Host ""
Read-Host "Press Enter to exit" 