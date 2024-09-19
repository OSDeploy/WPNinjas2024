# Demo of the WinPE StartURL parameter
# Edit-OSDCloudWinPE -StartURL "https://raw.githubusercontent.com/OSDeploy/WPNinjas2024/main/Examples/WinPEStartURL.ps1"

Write-Host "Pre OSDCloud" -ForegroundColor Cyan
Set-DisRes 1440

# Set the MyOSDCloud Global Variable
$Global:MyOSDCloud = @{
    ClearDiskConfirm = $true
    Debug = $true
    MSCatalogFirmware = $false
    MSCatalogDiskDrivers = $true
    MSCatalogNetDrivers = $true
    MSCatalogScsiDrivers = $false
    Restart = $false
    WindowsDefenderUpdate = $true
}
$Global:MyOSDCloud | Out-Host

Write-Host 'OSDCloud' -ForegroundColor Cyan
Start-OSDCloud -OSName 'Windows 11 23H2 x64' -OSEdition Enterprise -OSLanguage en-us

Write-Host 'Post OSDCloud' -ForegroundColor Cyan
Start-EjectCD
Start-Sleep -Seconds 30
Restart-Computer