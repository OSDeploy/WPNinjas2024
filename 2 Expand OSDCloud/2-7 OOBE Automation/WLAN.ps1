<#
.SYNOPSIS
This script is used to connect the computer to the Internet using WiFi.

.DESCRIPTION
This script is used to connect the computer to the Internet using WiFi.
The script checks the Internet connection by pinging www.google.com. If the connection is successful, the script will not connect the computer to the WiFi.
If the connection is not successful, the script will check for a WiFi profile in the OSDCloud\Scripts folder.
If the profile is found, the script will start the WLAN service, import the profile, and connect to the WiFi.
If the profile is not found, the script will try to connect the computer to the Internet using a cable.

.NOTES
   Version:			0.1
   Creation Date:	27.08.2024
   Author:			Akos Bakos
   Company:			SmartCon GmbH
   Contact:			akos.bakos@smartcon.ch

   Copyright (c) 2024 SmartCon GmbH

HISTORY:
Date			By			Comments
----------		---			----------------------------------------------------------
27.08.2024		Akos Bakos	Script created

#>

#region Helper Functions
function Write-DarkGrayDate {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [System.String]
        $Message
    )
    if ($Message) {
        Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) $Message"
    }
    else {
        Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) " -NoNewline
    }
}
function Write-DarkGrayHost {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $Message
    )
    Write-Host -ForegroundColor DarkGray $Message
}
function Write-DarkGrayLine {
    [CmdletBinding()]
    param ()
    Write-Host -ForegroundColor DarkGray "========================================================================="
}
function Write-SectionHeader {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $Message
    )
    Write-DarkGrayLine
    Write-DarkGrayDate
    Write-Host -ForegroundColor Cyan $Message
}
function Write-SectionSuccess {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [System.String]
        $Message = 'Success!'
    )
    Write-DarkGrayDate
    Write-Host -ForegroundColor Green $Message
}
#endregion

$Title = "WLAN Task"
$host.UI.RawUI.WindowTitle = $Title
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials

$env:APPDATA = "C:\Windows\System32\Config\SystemProfile\AppData\Roaming"
$env:LOCALAPPDATA = "C:\Windows\System32\Config\SystemProfile\AppData\Local"
$Env:PSModulePath = $env:PSModulePath + ";C:\Program Files\WindowsPowerShell\Scripts"
$env:Path = $env:Path + ";C:\Program Files\WindowsPowerShell\Scripts"

$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-WLAN-Task.log"
Start-Transcript -Path (Join-Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" $Global:Transcript) -ErrorAction Ignore | Out-Null

Write-SectionHeader "Checking Internet Connection after waiting 5 seconds"
Start-Sleep -Seconds 5

$Result = Test-Connection -ComputerName "www.google.com" -Count 1 -Quiet
if ($Result) {
    Write-SectionSuccess
    Write-DarkGrayHost "You are already connected to the Internet"
    Write-DarkGrayHost "No need to conenct the computer with WiFi"
    $StartWiFi = $false
}
else {
    Write-Host -ForegroundColor Red 'FAIL'
    $StartWiFi = $true
}

if ($StartWiFi) {
    Write-SectionHeader "Checking for WiFi Profile"
    $i = 120
    $XMLExist = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -eq 'C' } | ForEach-Object {
        Get-ChildItem "$($_.Root)\OSDCloud\Scripts" -Include 'WiFiProfile.xml' -File -Recurse -Force -ErrorAction Ignore
    }

    If (![String]::IsNullOrEmpty($XMLExist)) {
        Write-SectionHeader "XML file found: $($XMLExist.FullName)"
        Write-DarkGrayHost "Start WLAN Service"
        Start-Service -Name "WlanSvc" | Out-Null

        Write-DarkGrayHost "Importing WLAN profile: $XMLExist"
        netsh wlan add profile filename="$($XMLExist.FullName)" | Out-Null

        Write-DarkGrayHost "Connecting to WLAN"
        $SSID = ([xml](Get-Content -Path $XMLExist.FullName)).WLANProfile.SSIDConfig.SSID.name
        netsh wlan connect name=$SSID | Out-Null

        while ((((Get-CimInstance -ClassName Win32_NetworkAdapter | Where-Object { ($_.NetConnectionID -eq 'Wi-Fi') -or ($_.NetConnectionID -eq 'WiFi') -or ($_.NetConnectionID -eq 'WLAN') }).NetEnable_d) -eq $false) -and $i -gt 0) {
            --$i
            Write-DarkGrayHost "Waiting for Wi-Fi Connection ($i)"
            Start-Sleep -Seconds 1
        }
    }
    Else {
        Write-SectionHeader "No WiFi profiles found to import. Trying connect with cable"
        Start-Service -Name "WlanSvc" | Out-Null
    }
}

Stop-Transcript | Out-Null