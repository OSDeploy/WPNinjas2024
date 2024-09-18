# Demo of the WinPE StartURL parameter
# Edit-OSDCloudWinPE -StartURL "https://raw.githubusercontent.com/OSDeploy/WPNinjas2024/main/Examples/Customization.ps1"

if (-NOT (Test-Path 'X:\OSDCloud\Logs')) {
    New-Item -Path 'X:\OSDCloud\Logs' -ItemType Directory -Force -ErrorAction Stop | Out-Null
}

#Transport Layer Security (TLS) 1.2
Write-Host -ForegroundColor Green "Transport Layer Security (TLS) 1.2"
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Start-OSDCloud.log"
Start-Transcript -Path (Join-Path "X:\OSDCloud\Logs" $Transcript) -ErrorAction Ignore | Out-Null

#================================================
Write-Host -ForegroundColor DarkGray "========================================================================="
Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) " -NoNewline
Write-Host -ForegroundColor Cyan "[PreOS] Update Module"
#================================================

Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) " -NoNewline
Write-Host -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force

Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) " -NoNewline
Write-Host -ForegroundColor Green "PSCloudScript at functions.osdcloud.com"
Invoke-Expression (Invoke-RestMethod -Uri functions.osdcloud.com)

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

#region PreOS Tasks
#=======================================================================
Write-SectionHeader "[PreOS] Define OSDCloud Global And Customer Parameters"
#=======================================================================
$Global:WPNS = $null
$Global:WPNS = [ordered]@{
    Development = $true 
    Pilot       = $false
}

$Global:OSDCloud = [ordered]@{
    DriverPackName = 'none'
    ApplyManufacturerDrivers = $false
    ApplyCatalogDrivers = $false
    ApplyCatalogFirmware = $false
    IsOnBattery = $false
}

if ($Global:OSDCloud.ApplyCatalogFirmware -eq $true) {
    #=======================================================================
    Write-SectionHeader "[PreOS] Prepare Firmware Tasks"
    #=======================================================================
    osdcloud-TrustPSGallery -Verbose

    osdcloud-InstallPowerShellModule -Name 'MSCatalog'
    #Install-Module -Name MSCatalog -Force -Verbose -SkipPublisherCheck -AllowClobber -Repository PSGallery    
}

#=======================================================================
Write-SectionHeader "[PreOS] Updating Driver Catalogs"
#=======================================================================
if ((Get-MyComputerManufacturer -Brief) -eq "Acer") {
    Write-DarkGrayHost "Updating Acer Driver Catalog"
    $OSDModuleBase = (Get-Module -Name OSD -ListAvailable | Sort-Object -Property Version -Descending | Select-Object -First 1).ModuleBase

    Save-WebFile `
        -SourceUrl 'http://acercatalog.osdcloud.ch/' `
        -DestinationName 'CloudDriverPacks.json' `
        -DestinationDirectory (Join-Path $OSDModuleBase 'Catalogs') -Overwrite
}

if ((Get-MyComputerManufacturer -Brief) -eq "Microsoft") {
    Write-DarkGrayHost "Updating Microsoft Driver Catalog"
    Invoke-RestMethod "http://surfacecatalog.osdcloud.ch/" | Invoke-Expression
    Update-OSDCloudSurfaceDriverCatalogJustInTime -UpdateDriverPacksJson -Verbose
}
#endregion

#region OS Tasks
#=======================================================================
Write-SectionHeader "[OS] Params and Start-OSDCloud"
#=======================================================================
$Params = @{
    OSVersion   = "Windows 11"
    OSBuild     = "23H2"
    OSEdition   = "Pro"
    OSLanguage  = "en-us"
    OSLicense   = "Retail"
    ZTI         = $true
    Firmware    = $true
}
Start-OSDCloud @Params
#endregion

#region Autopilot Tasks
#================================================
Write-SectionHeader "[PostOS] Define Autopilot Attributes"
#================================================
Write-DarkGrayHost "Define Computername"
$ChassisType = (Get-WmiObject -Query "SELECT * FROM Win32_SystemEnclosure").ChassisTypes
$HyperV = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem WHERE Manufacturer LIKE '%Microsoft Corporation%' AND Model LIKE '%Virtual Machine%'"
$VMware = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem WHERE Manufacturer LIKE '%VMware%' AND Model LIKE '%VMware%'"
#$RandomNumber = Get-Random -Minimum 0001 -Maximum 9999
#$formattedNumber = "{0:D4}" -f $RandomNumber

$Serial = Get-WmiObject Win32_Bios | Select-Object -ExpandProperty SerialNumber

If ($HyperV -or $VMware) {
    $HW         = "VM"
}

If ($ChassisType -eq "8" -or`
    $ChassisType -eq "9" -or`
    $ChassisType -eq "10" -or`
    $ChassisType -eq "11" -or`
    $ChassisType -eq "12" -or`
    $ChassisType -eq "14" -or`
    $ChassisType -eq "18" -or`
    $ChassisType -eq "21" -or`
    $ChassisType -eq "31") {
    $HW = "NB"
}

elseif ($ChassisType -eq "3" -or`
    $ChassisType -eq "4" -or`
    $ChassisType -eq "5" -or`
    $ChassisType -eq "6" -or`
    $ChassisType -eq "7" -or`
    $ChassisType -eq "15" -or`
    $ChassisType -eq "16") {
    $HW = "WS"
}

If (!($HW)) {
    $AssignedComputerName = "RENAME_ME$Serial"
}
else {
    $AssignedComputerName = $Serial           
}

If ($HyperV -or $VMware) {
    $GroupTag   = "AutopilotVM"
}
else {
    $GroupTag   = "AutopilotHW"
}

# Device assignment
if ($Global:WPNS.Pilot -eq $true){
    Write-DarkGrayHost "Adding device to CGRP_COM_PilotDevices Group"
    $AddToGroup = "CGRP_COM_PilotDevices"
}
else {
    Write-DarkGrayHost "Adding device to CGRP_COM_AutopilotDevices Group"
    $AddToGroup = "CGRP_COM_AutopilotDevices"
}

Write-Host -ForegroundColor Yellow "Computername: $AssignedComputerName"
Write-Host -ForegroundColor Yellow "AddToGroup: $AddToGroup"
Write-Host -ForegroundColor Yellow "GroupTag: $GroupTag"

#================================================
Write-SectionHeader "[PostOS] AutopilotOOBE Configuration"
#================================================
Write-DarkGrayHost "Create C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json file"
$AutopilotOOBEJson = @"
{
        "AssignedComputerName" : "$AssignedComputerName",
        "AddToGroup":  "$AddToGroup",
        "Assign":  {
                    "IsPresent":  true
                },
        "GroupTag":  "$GroupTag",
        "Hidden":  [
                    "AssignedUser",
                    "PostAction",
                    "GroupTag",
                    "Assign"
                ],
        "PostAction":  "Quit",
        "Run":  "NetworkingWireless",
        "Docs":  "https://google.com/",
        "Title":  "Autopilot Workplace Ninja Summit Manual Register"
    }
"@

If (!(Test-Path "C:\ProgramData\OSDeploy")) {
    New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
}
$AutopilotOOBEJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json" -Encoding ascii -Force
#endregion

#region Specialize Tasks
#================================================
Write-SectionHeader "[PostOS] SetupComplete CMD Command Line"
#================================================
Write-DarkGrayHost "Cleanup SetupComplete Files from OSDCloud Module"
Get-ChildItem -Path 'C:\Windows\Setup\Scripts\SetupComplete*' -Recurse | Remove-Item -Force

Write-DarkGrayHost "Create C:\Windows\Setup\Scripts\SetupComplete.cmd"
$SetupCompleteCMD = @'
ECHO "Hello Workplace Ninjas!"
'@
$SetupCompleteCMD | Out-File -FilePath 'C:\Windows\Setup\Scripts\setupcomplete.cmd' -Encoding ascii -Force

#=================================================
Write-SectionHeader "[PostOS] Define Specialize Phase"
#=================================================
$UnattendXml = @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="specialize">
        <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <RunSynchronous>
                <RunSynchronousCommand wcm:action="add">
                    <Order>1</Order>
                    <Description>Import WLAN profile</Description>
                    <Path>PowerShell -ExecutionPolicy Bypass C:\Windows\Setup\scripts\wlan.ps1</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>2</Order>
                    <Description>Start Autopilot Import & Assignment Process</Description>
                    <Path>PowerShell -ExecutionPolicy Bypass C:\Windows\Setup\scripts\autopilot.ps1</Path>
                </RunSynchronousCommand>
            </RunSynchronous>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <InputLocale>de-CH</InputLocale>
            <SystemLocale>de-DE</SystemLocale>
            <UILanguage>de-DE</UILanguage>
            <UserLocale>de-CH</UserLocale>
        </component>
    </settings>
</unattend>
'@ 
# Get-OSDGather -Property IsWinPE
Block-WinOS

if (-NOT (Test-Path 'C:\Windows\Panther')) {
    New-Item -Path 'C:\Windows\Panther'-ItemType Directory -Force -ErrorAction Stop | Out-Null
}

$Panther = 'C:\Windows\Panther'
$UnattendPath = "$Panther\Unattend.xml"
$UnattendXml | Out-File -FilePath $UnattendPath -Encoding utf8 -Width 2000 -Force

Write-DarkGrayHost "Use-WindowsUnattend -Path 'C:\' -UnattendPath $UnattendPath"
Use-WindowsUnattend -Path 'C:\' -UnattendPath $UnattendPath | Out-Null
#endregion

#region OOBE Tasks
#================================================
Write-SectionHeader "[PostOS] OOBE CMD Command Line"
#================================================
Write-DarkGrayHost "Downloading Scripts for OOBE and specialize phase"

Invoke-RestMethod https://raw.githubusercontent.com/OSDeploy/WPNinjas2024/main/2%20Expand%20OSDCloud/2-7%20OOBE%20Automation/WLAN.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\wlan.ps1' -Encoding ascii -Force
Invoke-RestMethod https://raw.githubusercontent.com/OSDeploy/WPNinjas2024/main/2%20Expand%20OSDCloud/2-8%20Autopilot/Autopilot.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\autopilot.ps1' -Encoding ascii -Force
Invoke-RestMethod https://raw.githubusercontent.com/OSDeploy/WPNinjas2024/main/2%20Expand%20OSDCloud/2-7%20OOBE%20Automation/OOBE.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\oobe.ps1' -Encoding ascii -Force
Invoke-RestMethod https://raw.githubusercontent.com/OSDeploy/WPNinjas2024/main/2%20Expand%20OSDCloud/2-7%20OOBE%20Automation/Cleanup.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\cleanup.ps1' -Encoding ascii -Force
Invoke-RestMethod https://raw.githubusercontent.com/OSDeploy/WPNinjas2024/main/2%20Expand%20OSDCloud/2-7%20OOBE%20Automation/OSDGather.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\osdgather.ps1' -Encoding ascii -Force

$OOBEcmdTasks = @'
@echo off
# Execute OOBE Tasks
start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\wlan.ps1

# Execute OOBE Tasks
start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\oobe.ps1

# Execute OSD Gather Script
start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\osdgather.ps1

# Execute Cleanup Script
start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\cleanup.ps1

# Below a PS session for debug and testing in system context, # when not needed 
# start /wait powershell.exe -NoL -ExecutionPolicy Bypass

exit 
'@
$OOBEcmdTasks | Out-File -FilePath 'C:\Windows\Setup\scripts\oobe.cmd' -Encoding ascii -Force
#endregion

Write-DarkGrayHost "Disabling Shift F10 in OOBE for security Reasons"
$Tagpath = "C:\Windows\Setup\Scripts\DisableCMDRequest.TAG"
New-Item -ItemType file -Force -Path $Tagpath | Out-Null
Write-DarkGrayHost "Shift F10 disabled now!"

#region Development
if ($Global:WPNS.Development -eq $true){
    #================================================
    Write-SectionHeader "[WINPE] DEVELOPMENT - Activate some debugging features"
    #================================================
    Write-DarkGrayHost "Enabling Shift F10 in OOBE for security Reasons"
    $Tagpath = "C:\Windows\Setup\Scripts\DisableCMDRequest.TAG"
    Remove-Item -Force -Path $Tagpath | Out-Null
    Write-DarkGrayHost "Shift F10 enabled now!"

    Write-DarkGrayHost "Disable Cursor Suppression"
    #cmd.exe /c reg load HKLM\Offline c:\windows\system32\config\software & cmd.exe /c REG ADD "HKLM\Offline\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableCursorSuppression /t REG_DWORD /d 0 /f & cmd.exe /c reg unload HKLM\Offline
    Invoke-Exe cmd.exe -Arguments "/c reg load HKLM\Offline c:\windows\system32\config\software" | Out-Null
    New-ItemProperty -Path HKLM:\Offline\Microsoft\Windows\CurrentVersion\Policies\System -Name EnableCursorSuppression -Value 0 -Force | Out-Null
    #Invoke-Exe cmd.exe -Arguments "/c REG ADD 'HKLM\Offline\Microsoft\Windows\CurrentVersion\Policies\System' /v EnableCursorSuppression /t REG_DWORD /d 0 /f "
    Invoke-Exe cmd.exe -Arguments "/c reg unload HKLM\Offline" | Out-Null
}
#endregion

#=======================================================================	
Write-SectionHeader "Moving OSDCloud Logs to IntuneManagementExtension\Logs\OSD"	
#=======================================================================	
if (-NOT (Test-Path 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD')) {	
    New-Item -Path 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD' -ItemType Directory -Force -ErrorAction Stop | Out-Null	
}	
Get-ChildItem -Path X:\OSDCloud\Logs\ | Copy-Item -Destination 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD' -Force

if ($Global:WPNS.Development -eq $false){
    Write-DarkGrayHost "Restarting in 20 seconds!"
    Start-Sleep -Seconds 20

    wpeutil reboot

    Stop-Transcript | Out-Null
}

Write-DarkGrayHost "Restarting in 20 seconds!"
Start-Sleep -Seconds 20
wpeutil reboot

Stop-Transcript | Out-Null