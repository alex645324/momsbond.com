Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                    🚀 Enhanced Admin Terminal                    ║" -ForegroundColor Green  
Write-Host "║                     Connection Platform v2.0                     ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Starting enhanced admin terminal with live Firebase integration..." -ForegroundColor Cyan
Write-Host ""

dart run simple_admin.dart

Write-Host ""
Write-Host "Press any key to continue..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 