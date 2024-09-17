<#
.SYNOPSIS
Import PFX certificate to the local machine.

.NOTES
   Version:			0.1
   Creation Date:	27.08.2024
   Author:			Ákos Bakos
   Company:			SmartCon GmbH
   Contact:			akos.bakos@smartcon.ch

   Copyright (c) 2024 SmartCon GmbH

HISTORY:
Date			By			Comments
----------		---			----------------------------------------------------------
27.08.2024		Ákos Bakos	Script created

#>

$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Import-Certificate.log"
Start-Transcript -Path (Join-Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" $Global:Transcript) -ErrorAction Ignore

Write-Host -ForegroundColor Cyan "Importing PFX certificate"
$subjectName = "AutopilotRegistration"
$certPassword = ConvertTo-SecureString -String "@High-Secure+Password!" -Force -AsPlainText

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