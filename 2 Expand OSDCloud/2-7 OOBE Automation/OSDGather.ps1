<#
.SYNOPSIS
Gather information about the OSD environment.

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

#region Helper Functions
function Write-DarkGrayDate {
    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
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
        [Parameter(Mandatory=$true, Position=0)]
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
        [Parameter(Mandatory=$true, Position=0)]
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
        [Parameter(Position=0)]
        [System.String]
        $Message = 'Success!'
    )
    Write-DarkGrayDate
    Write-Host -ForegroundColor Green $Message
}
#endregion

$Title = "OSD Gathering"
$host.UI.RawUI.WindowTitle = $Title
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials

$env:APPDATA = "C:\Windows\System32\Config\SystemProfile\AppData\Roaming"
$env:LOCALAPPDATA = "C:\Windows\System32\Config\SystemProfile\AppData\Local"
$Env:PSModulePath = $env:PSModulePath+";C:\Program Files\WindowsPowerShell\Scripts"
$env:Path = $env:Path+";C:\Program Files\WindowsPowerShell\Scripts"

$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Gathering-Task.log"
Start-Transcript -Path (Join-Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" $Global:Transcript) -ErrorAction Ignore | Out-Null

Write-SectionHeader "Importing OSD Module"
$module = Import-Module OSD -PassThru -ErrorAction Ignore
if (-not $module) {
    Write-Host "Installing OSD module"
    Install-Module OSD -Force | Out-Null
}
Import-Module OSD -Force | Out-Null
$OSDGathering = Get-OSDGather -Full

$OSDGatheringJSON = Get-OSDGather -Full | ConvertTo-Json

$OSDGatheringJSON

#region measure WinPE & OSDCloud time completed
$JsonPath = "C:\OSDCloud\Logs\OSDCloud.json"
if (Test-Path $JsonPath){

    $JSON= Get-Content -Path $JsonPath -Raw | ConvertFrom-Json
    $WinPECompleted = "$($JSON.TimeSpan.Minutes) minutes $($JSON.TimeSpan.Seconds) seconds"
    $WinPECompleted

    $OSDEnd = Get-Date
    $OSDCouldTime = New-TimeSpan -Start $JSON.TimeStart.DateTime -End $OSDEnd
    $OSDCouldTime

    $OSDCouldTimeCompleted = "$($OSDCouldTime.Hours) hour(s) $($OSDCouldTime.Minutes) minutes $($OSDCouldTime.Seconds) seconds"
    $OSDCouldTimeCompleted
}
#endregion


#region SpeedTest
try {
#region Scrape the webpage to get the download link
function Get-SpeedTestDownloadLink {
    $url = "https://www.speedtest.net/apps/cli"
    $webContent = Invoke-WebRequest -Uri $url -UseBasicParsing
    if ($webContent.Content -match 'href="(https://install\.speedtest\.net/app/cli/ookla-speedtest-[\d\.]+-win64\.zip)"') {
        return $matches[1]
    } else {
        Write-Output "Unable to find the win64 zip download link."
        return $null
    }
}
#endregion

#region Download and extract the zip file
function Download-SpeedTestZip {
    param (
        [string]$downloadLink,
        [string]$destination
    )
    Invoke-WebRequest -Uri $downloadLink -OutFile $destination -UseBasicParsing
}

function Extract-Zip {
    param (
        [string]$zipPath,
        [string]$destination
    )
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $destination)
}
#endregion

#region Run the speedtest executable
function Run-SpeedTest {
    param (
        [string]$executablePath,
        [array]$arguments
    )

    # Check if '--accept-license' is already in arguments
    if (-not ($arguments -contains "--accept-license")) {
        $arguments += "--accept-license"
    }

    # Check if '--accept-gdpr' is already in arguments
    if (-not ($arguments -contains "--accept-gdpr")) {
        $arguments += "--accept-gdpr"
    }

    $Result = & $executablePath $arguments

    return $Result
}
#endregion

#region Cleanup
function Remove-File {
    param (
        [string]$Path
    )
    try {
        if (Test-Path -Path $Path) {
            Remove-Item -Path $Path -Recurse -ErrorAction Stop
        }
    } catch {
        Write-Debug "Unable to remove item: $_"
    }
}

function Remove-Files {
    param(
        [string]$zipPath,
        [string]$folderPath
    )
    Remove-File -Path $zipPath
    Remove-File -Path $folderPath
}
#endregion

$tempFolder = $env:TEMP
$zipFilePath = Join-Path $tempFolder "speedtest-win64.zip"
$extractFolderPath = Join-Path $tempFolder "speedtest-win64"

Remove-Files -zipPath $zipFilePath -folderPath $extractFolderPath

$downloadLink = Get-SpeedTestDownloadLink
Write-SectionHeader "Downloading SpeedTest CLI"
Download-SpeedTestZip -downloadLink $downloadLink -destination $zipFilePath

Write-SectionHeader "Extracting Zip File"
Extract-Zip -zipPath $zipFilePath -destination $extractFolderPath

$executablePath = Join-Path $extractFolderPath "speedtest.exe"
Write-SectionHeader "Running SpeedTest"
$Result = Run-SpeedTest -executablePath $executablePath -arguments $ScriptArgs

$DownloadSpeed = [regex]::match(($Result | where-object { $_ -like "*Download:*" }).trim(), '[0-9]+\.?[0-9]*').value
$UploadSpeed = [regex]::match(($Result | where-object { $_ -like "*Upload:*" }).trim(), '[0-9]+\.?[0-9]*').value
$SpeedTestURL = ($Result | where-object { $_ -like "*Result URL:*" }).trim().split(" ")[2].trim()

Write-DarkGrayLine
Write-Host -ForegroundColor Green "Download: $DownloadSpeed Mbps"
Write-Host -ForegroundColor Green "Upload: $UploadSpeed Mbps"
Write-Host -ForegroundColor Green "Result URL: $SpeedTestURL"

Write-SectionHeader "Cleaning up"
Remove-Files -zipPath $zipFilePath -folderPath $extractFolderPath

Write-SectionSuccess "Done"
} catch {
    Write-Error "An error occurred: $_"
}
#endregion

Write-SectionHeader "Collecting OSD Information"
$ComputerName = $OSDGathering.OperatingSystem.CSName
$ComputerModel = $OSDGathering.ComputerSystemProduct.Name
$ComputerVersion = $OSDGathering.ComputerSystemProduct.Version

$OS = $OSDGathering.OperatingSystem.Caption
$OSVersion = $OSDGathering.OperatingSystem.Version

$BiosSerialNumber = $OSDGathering.BIOS.SerialNumber
$BiosVersion = $OSDGathering.BIOS.SMBIOSBIOSVersion
$BiosReleaseDate = $OSDGathering.BIOS.ReleaseDate

$OSDCloudVersion = (Get-Module -Name OSD -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version.ToString()

$IPAddress = (Get-WmiObject win32_Networkadapterconfiguration | Where-Object{ $_.ipaddress -notlike $null }).IPaddress | Select-Object -First 1
$Connection = Get-NetAdapter -physical | Where-Object status -eq 'up'
$ConnectionName = $connection.Name
$ConnectionDescription = $connection.InterfaceDescription
$LinkSpeed = $connection.LinkSpeed
$SSIDset = (Get-NetConnectionProfile).Name
$WiFiSignal = (netsh wlan show interfaces) -Match '^\s+Signal' -Replace '^\s+Signal\s+:\s+',''
if ($WiFiSignal) {
    Write-Host -ForegroundColor Green "WiFi Signal: $WiFiSignal"
} else {
    Write-Host -ForegroundColor Green "Wired installation"
}

#Speedtest
$DownloadSpeed = [regex]::match(($Result | where-object { $_ -like "*Download:*" }).trim(), '[0-9]+\.?[0-9]*').value
$UploadSpeed = [regex]::match(($Result | where-object { $_ -like "*Upload:*" }).trim(), '[0-9]+\.?[0-9]*').value
$SpeedTestURL = ($Result | where-object { $_ -like "*Result URL:*" }).trim().split(" ")[2].trim()

Write-SectionHeader "Sending OSD Information to Teams"
$JSON = @{
    "@type"    = "MessageCard"
    "@context" = "<http://schema.org/extensions>"
    "title"    = 'OSD Information'
    "text"     = "The following client has been successfully deployed:<br>
                  Computer Name: **$($ComputerName)**<br>
                  Model: **$($ComputerModel)**<br>
                  Version: **$($ComputerVersion)**<br>
                  <br>
                  OS Version: **$($OS) $($OSVersion)**<br>
                  <br>
                  BIOS Serial Number: **$($BiosSerialNumber)**<br>
                  BIOS Version: **$($BiosVersion)**<br>
                  BIOS Release Date: **$($BiosReleaseDate)**<br>
                  <br>
                  Connection Type: **$($ConnectionName)**<br>
                  SSID: **$($SSIDset)**<br>
                  IP Address: **$($IPAddress)**<br>
                  Connection Description: **$($ConnectionDescription)**<br>
                  Transmit rate (Mbps): **$($LinkSpeed)**<br>
                  Download Speed: **$($DownloadSpeed) Mbps**<br>
                  Upload Speed: **$($UploadSpeed) Mbps**<br>
                  SpeedTest URL: **$($SpeedTestURL)**<br>
                  WiFi Signal: $($WiFiSignal)<br>
                  <br>
                  OSDCloud Version: **$($OSDCloudVersion)**<br>
                  WinPE Time Completed: **$($WinPECompleted)**<br>
                  OSDCloud Time Completed: **$($OSDCouldTimeCompleted)**<br>
                  <br>
                  "
    } | ConvertTo-JSON

$URISmartCon = 'https://xxxxxxxxxxxxxxxxxxxxxx'   
$ParamsSmartCon = @{
"URI"         = $URISmartCon
"Method"      = 'POST'
"Body"        = $JSON
"ContentType" = 'application/json'
}
Invoke-RestMethod @ParamsSmartCon | Out-Null

Stop-Transcript | Out-Null