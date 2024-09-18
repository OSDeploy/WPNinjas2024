# Demo of the WinPE StartURL parameter
# Edit-OSDCloudWinPE -StartURL "https://raw.githubusercontent.com/OSDeploy/WPNinjas2024/main/Examples/WinPEStartURL.ps1"

Write-Host "Pre OSDCloud" -ForegroundColor Cyan
# Add something to do here

Write-Host 'OSDCloud' -ForegroundColor Cyan
Start-OSDCloud -OSName 'Windows 11 23H2 x64' -OSEdition Enterprise -OSLanguage en-us

Write-Host 'Post OSDCloud' -ForegroundColor Cyan
Restart-Computer