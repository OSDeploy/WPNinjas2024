# Import PFX certificate to the local machine

$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Import-Certificate.log"
Start-Transcript -Path (Join-Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" $Global:Transcript) -ErrorAction Ignore

Write-Host -ForegroundColor Cyan "Importing PFX certificate"
$subjectName = "AutopilotRegistration"
$certPassword = ConvertTo-SecureString -String "WPNinjaS2024!" -Force -AsPlainText

$Params = @()
$Params = @{
    FilePath          = "$env:SystemDrive\OSDCloud\Scripts\$($subjectName).pfx"
    CertStoreLocation = "Cert:\LocalMachine\My"
    Password          = $certPassword
}
Import-PfxCertificate @Params | Out-Null

Write-Host -ForegroundColor Cyan "Remove cert"
Remove-Item $env:SystemDrive\OSDCloud\Scripts\$($subjectName).pfx -Force

Stop-Transcript