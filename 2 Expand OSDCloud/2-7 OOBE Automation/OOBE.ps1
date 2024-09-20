# OOBE Deploy Tasks

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
function Write-DarkGrayHost {
    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        [System.String]
        $Message = 'Success!'
    )
    Write-DarkGrayDate
    Write-Host -ForegroundColor Green $Message
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

$Title = "OOBE Deploy Tasks"
$host.UI.RawUI.WindowTitle = $Title
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials

$env:APPDATA = "C:\Windows\System32\Config\SystemProfile\AppData\Roaming"
$env:LOCALAPPDATA = "C:\Windows\System32\Config\SystemProfile\AppData\Local"
$Env:PSModulePath = $env:PSModulePath+";C:\Program Files\WindowsPowerShell\Scripts"
$env:Path = $env:Path+";C:\Program Files\WindowsPowerShell\Scripts"

$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Start-OOBEDeploy.log"
Start-Transcript -Path (Join-Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" $Global:Transcript) -ErrorAction Ignore | Out-Null

Write-DarkGrayHost "Installing and importing OSD PowerShell Module"
Install-Module OSD -Force
Import-Module OSD -Force

#region Trust PS Gallery
#=================================================
Write-SectionHeader "Trust WinOS PSGallery"
#=================================================
$PSGalleryIP = (Get-PSRepository -Name PSGallery).InstallationPolicy
if ($PSGalleryIP -eq 'Untrusted') {
    Write-DarkGrayHost "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted"
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
}
#endregion

#region NetFx3
#=================================================
Write-SectionHeader "Install NetFX3 - it can take up to 10 minutes"
#=================================================
$Title = 'Installing AddNetFX3'
$host.ui.RawUI.WindowTitle = "$Title"
$host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.size(2000,2000)

$AddWindowsCapability = Get-MyWindowsCapability -Match 'NetFX' -Detail
foreach ($Item in $AddWindowsCapability) {
    if ($Item.State -ne 'Install') {
        Write-DarkGrayHost "$($Item.DisplayName)"
        $Item | Add-WindowsCapability -Online -ErrorAction Ignore | Out-Null
    }
    else {
        Write-DarkGrayHost "$($Item.DisplayName)"
    }
}
#endregion

#region Product activation
#=================================================
Write-SectionHeader "Activate Embedded Product Key"
#=================================================
$Title = 'Activating Embedded Product Key'
$host.ui.RawUI.WindowTitle = "$Title"
$host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.size(2000,2000)

$Key = (Get-WmiObject SoftwareLicensingService).OA3xOriginalProductKey
If ($Key) {
    Write-DarkGrayHost "Reading embedded product key"
    Invoke-Command -ScriptBlock {& 'cscript.exe' "$env:windir\system32\slmgr.vbs" '/ipk' "$($Key)"}
    Start-Sleep -Seconds 5

    Write-DarkGrayHost "Activating embedded product key"
    Invoke-Command -ScriptBlock {& 'cscript.exe' "$env:windir\system32\slmgr.vbs" '/ato'}
    Start-Sleep -Seconds 5
}

Else {
    Write-Host -ForegroundColor Red 'No embedded product key found.'
}
#endregion

#region Remove-Appx
#=================================================
Write-SectionHeader "Remove-Appx"
#=================================================
$Title = 'Remove Appx'
$host.ui.RawUI.WindowTitle = "$Title"
$host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.size(2000,2000)

#Log Function
function Write-LogEntry {
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Value,
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$FileName = "AppXRemoval.log",
        [switch]$Stamp
    )

    #Build Log File appending System Date/Time to output
    $LogFile = Join-Path -Path $env:SystemRoot -ChildPath $("Temp\$FileName")
    $Time = -join @((Get-Date -Format "HH:mm:ss.fff"), " ", (Get-WmiObject -Class Win32_TimeZone | Select-Object -ExpandProperty Bias))
    $Date = (Get-Date -Format "MM-dd-yyyy")

    If ($Stamp) {
        $LogText = "<$($Value)> <time=""$($Time)"" date=""$($Date)"">"
    }
    else {
        $LogText = "$($Value)"   
    }
    
    Try {
        Out-File -InputObject $LogText -Append -NoClobber -Encoding Default -FilePath $LogFile -ErrorAction Stop
    }
    Catch [System.Exception] {
        Write-Warning -Message "Unable to add log entry to $LogFile.log file. Error message at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

#Function to Remove AppxProvisionedPackage
Function Remove-AppxProvisionedPackageCustom {

    # Attempt to remove AppxProvisioningPackage
    if (!([string]::IsNullOrEmpty($BlackListedApp))) {
        try {
        
            # Get Package Name
            $AppProvisioningPackageName = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $BlackListedApp } | Select-Object -ExpandProperty PackageName -First 1
            Write-Host "$($BlackListedApp) found. Attempting removal ... " -NoNewline
            Write-LogEntry -Value "$($BlackListedApp) found. Attempting removal ... "

            # Attempt removeal
            $RemoveAppx = Remove-AppxProvisionedPackage -PackageName $AppProvisioningPackageName -Online -AllUsers
            
            #Re-check existence
            $AppProvisioningPackageNameReCheck = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $BlackListedApp } | Select-Object -ExpandProperty PackageName -First 1

            If ([string]::IsNullOrEmpty($AppProvisioningPackageNameReCheck) -and ($RemoveAppx.Online -eq $true)) {
                Write-Host @CheckIcon
                Write-Host " (Removed)"
                Write-LogEntry -Value "$($BlackListedApp) removed"
            }
        }
        catch [System.Exception] {
            Write-Host " (Failed)"
            Write-LogEntry -Value "Failed to remove $($BlackListedApp)"
        }
    }
}

Write-LogEntry -Value "##################################"
Write-LogEntry -Stamp -Value "Remove-Appx Started"
Write-LogEntry -Value "##################################"

#OS Check
$OS = (Get-CimInstance -ClassName Win32_OperatingSystem).BuildNumber
Switch -Wildcard ( $OS ) {
    '21*' {
        $OSVer = "Windows 10"
        Write-Warning "This script is intended for use on Windows 11 devices. $($OSVer) was detected..."
        Write-LogEntry -Value "This script is intended for use on Windows 11 devices. $($OSVer) was detected..."
        Exit 1
    }
}
# Black List of Appx Provisioned Packages to Remove for All Users
$BlackListedApps = $null
$BlackListedApps = New-Object -TypeName System.Collections.ArrayList
$BlackListedApps.AddRange(@(
    "Microsoft.OutlookForWindows",
    "MicrosoftCorporationII.QuickAssist",
    "Clipchamp.Clipchamp",
    "Microsoft.BingWeather",
    "Microsoft.BingNews",              
    "Microsoft.GamingApp",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",                 
    "Microsoft.Messaging",                   
    "Microsoft.MicrosoftOfficeHub",          
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.MicrosoftStickyNotes",       
    "Microsoft.MSPaint",                              
    "Microsoft.People",                      
    "Microsoft.PowerAutomateDesktop",
    "Microsoft.StorePurchaseApp", 
    "Microsoft.Todos",                                 
    "microsoft.windowscommunicationsapps",   
    "Microsoft.WindowsFeedbackHub",          
    "Microsoft.WindowsMaps",               
    "Microsoft.WindowsSoundRecorder",
    "Microsoft.Xbox.TCUI",                      
    "Microsoft.XboxGameOverlay",                     
    "Microsoft.XboxGamingOverlay",             
    "Microsoft.XboxIdentityProvider",        
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.YourPhone",   
    "Microsoft.ZuneMusic",                   
    "Microsoft.ZuneVideo"
    ))

#Define Icons
$CheckIcon = @{
    Object          = [Char]8730
    ForegroundColor = 'Green'
    NoNewLine       = $true
}

#Define App Count
[int]$AppCount = 0

If ($($BlackListedApps.Count) -ne 0) {

    Write-Output `n"The following $($BlackListedApps.Count) apps were targeted for removal from the device:-"
    Write-LogEntry -Value "The following $($BlackListedApps.Count) apps were targeted for removal from the device:-"
    Write-LogEntry -Value "Apps marked for removal:$($BlackListedApps)"
    Write-Output ""
    $BlackListedApps

    #Initialize list for apps not targeted
    $AppNotTargetedList = New-Object -TypeName System.Collections.ArrayList

    # Get Appx Provisioned Packages
    Write-Output `n"Gathering installed Appx Provisioned Packages..."
    Write-LogEntry -Value "Gathering installed Appx Provisioned Packages..."
    Write-Output ""
    $AppArray = Get-AppxProvisionedPackage -Online | Select-Object -ExpandProperty DisplayName

    # Loop through each Provisioned Package
    foreach ($BlackListedApp in $BlackListedApps) {

        # Function call to Remove Appx Provisioned Packages defined in the Black List
        if (($BlackListedApp -in $AppArray)) {
            $AppCount ++
            Try {
                Remove-AppxProvisionedPackageCustom -BlackListedApp $BlackListedApp
            }
            Catch {
                Write-Warning `n"There was an error while attempting to remove $($BlakListedApp)"
                Write-LogEntry -Value "There was an error when attempting to remove $($BlakListedApp)"
            }
        }
        else {
            $AppNotTargetedList.AddRange(@($BlackListedApp))
        }
    }

    #Update Output Information
    If (!([string]::IsNullOrEmpty($AppNotTargetedList))) { 
        Write-Output `n"The following apps were not removed. Either they were already removed or the Package Name is invalid:-"
        Write-LogEntry -Value "The following apps were not removed. Either they were already removed or the Package Name is invalid:-"
        Write-LogEntry -Value "$($AppNotTargetedList)"
        Write-Output ""
        $AppNotTargetedList
    }
    If ($AppCount -eq 0) {
        Write-Output `n"No apps were removed. Most likely reason is they had been removed previously."
        Write-LogEntry -Value "No apps were removed. Most likely reason is they had been removed previously."
    }
}
else {
    Write-Output "No Black List Apps defined in array"
    Write-LogEntry -Value "No Black List Apps defined in array"
}
#endregion

#region Update Drivers
#=================================================
Write-SectionHeader "Update Drivers"
#=================================================
$Title = 'Update Drivers'
$host.ui.RawUI.WindowTitle = "$Title"
$host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.size(2000,2000)

if (!(Get-Module PSWindowsUpdate -ListAvailable -ErrorAction Ignore)) {
    try {
        Write-DarkGrayHost "Installing PSWindowsUpdate module"
        Install-Module PSWindowsUpdate -Force
        Import-Module PSWindowsUpdate -Force
    }
    catch {
        Write-Warning 'Unable to install PSWindowsUpdate Driver Updates'
    }
}

if (Get-Module PSWindowsUpdate -ListAvailable -ErrorAction Ignore) {
    Write-DarkGrayHost "Executing 'Install-WindowsUpdate -UpdateType Driver -AcceptAll -IgnoreReboot'"
    Install-WindowsUpdate -UpdateType Driver -AcceptAll -IgnoreReboot
}
#endregion

#region Update Windows
#=================================================
Write-DarkGrayHost "Update Windows"
#=================================================
$Title = 'Update Windows'
$host.ui.RawUI.WindowTitle = "$Title"
$host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.size(2000,2000)

if (!(Get-Module PSWindowsUpdate -ListAvailable)) {
    try {
        Write-DarkGrayHost "Installing PSWindowsUpdate module"
        Install-Module PSWindowsUpdate -Force
        Import-Module PSWindowsUpdate -Force
    }
    catch {
        Write-Warning 'Unable to install PSWindowsUpdate Windows Updates'
    }
}
if (Get-Module PSWindowsUpdate -ListAvailable -ErrorAction Ignore) {
    Write-DarkGrayHost "Executing 'Add-WUServiceManager -MicrosoftUpdate -Confirm:$false'"
    Add-WUServiceManager -MicrosoftUpdate -Confirm:$false
    #Write-Host -ForegroundColor DarkCyan 'Install-WindowsUpdate -UpdateType Software -AcceptAll -IgnoreReboot'
    #Install-WindowsUpdate -UpdateType Software -AcceptAll -IgnoreReboot -NotTitle 'Malicious'
    Write-DarkGrayHost "Executing 'Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot'"
    Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -NotTitle 'Preview' -NotKBArticleID 'KB890830','KB5005463','KB4481252'
}
#endregion

#region Remove DevHome & Outlook NEW
#=================================================
Write-DarkGrayHost "Remove DevHome & Outlook NEW"
#=================================================
$Title = 'Remove DevHome & Outlook NEW'
$host.ui.RawUI.WindowTitle = "$Title"
$host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.size(2000,2000)

$DevHome = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate"
$OutlookNew = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate"
if (Test-Path -Path $DevHome) {
    Write-Host "Found --> Removing DevHome"
    Remove-Item -Path $DevHome -Force
}
if (Test-Path -Path $OutlookNew) {
    Write-Host "Found --> Removing Outlook NEW"
    Remove-Item -Path $OutlookNew -Force
}
#endregion

#region Disable PowerShell 2.0
#=================================================
Write-DarkGrayHost "Disable PowerShell 2.0"
#=================================================
$Title = 'Disable PowerShell 2.0'
$host.ui.RawUI.WindowTitle = "$Title"
$host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.size(2000,2000)

#If PowerShell version 2 is installed, it’s possible to bypass the constrained language mode, which normally is being enforced by application control solutions like AppLocker and similar.
try {
    $PoShv2Enabled = Get-WindowsOptionalFeature -FeatureName "MicrosoftWindowsPowerShellV2Root" -Online | Select-Object -ExpandProperty State
} catch {
    Write-Error "Failed to get the state of the PowerShell v2.0 feature: $_"
}
# If the feature is enabled, try to disable it
if ($PoShv2Enabled -eq "Enabled") {
    try {
        Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2Root -ErrorAction Continue -NoRestart
    } catch {
        Write-Error "Failed to disable the PowerShell v2.0 feature: $_"
    }
}
#endregion

#region Stop Start menu from opening on first logon
#=================================================
Write-SectionHeader "Stop Start menu from opening on first logon"
#=================================================
$Title = 'Stop Start menu from opening on first logon'
$host.ui.RawUI.WindowTitle = "$Title"
$host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.size(2000,2000)

try {
    reg.exe load HKLM\TempUser "C:\Users\Default\NTUSER.DAT" | Out-Host
    reg.exe add "HKLM\TempUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v StartShownOnUpgrade /t REG_DWORD /d 1 /f | Out-Host
    reg.exe unload HKLM\TempUser | Out-Host
}
catch {
    Write-Warning 'Unable to stop Start menu from opening on first logon'
}
#endregion

#region OEM Branding
#=================================================
Write-SectionHeader "OEM Branding"
#=================================================
$Title = 'OEM Branding'
$host.ui.RawUI.WindowTitle = "$Title"
$host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.size(2000,2000)

try {
	reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" /v Manufacturer /t REG_SZ /d "Workplace Ninja Summit 2024" /f /reg:64 | Out-Host
	reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" /v SupportPhone /t REG_SZ /d "+41 00 111 22 33" /f /reg:64 | Out-Host
	reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" /v SupportHours /t REG_SZ /d "Mo - Fr: 8-12 & 13-17" /f /reg:64 | Out-Host
	reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" /v SupportURL /t REG_SZ /d "https://www.wpninjas.ch/events/workplace-ninja-summit-2024/" /f /reg:64 | Out-Host
	reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v RegisteredOwner /t REG_SZ /d "Workplace Ninja Summit 2024" /f /reg:64 | Out-Host
    reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v RegisteredOrganization /t REG_SZ /d "Workplace Ninja Summit 2024" /f /reg:64 | Out-Host
}
catch {
    Write-Warning 'Unable to set the OEM Branding'
}
#endregion

#region Removes Microsoft Quick Assist
#=================================================
Write-SectionHeader "Removes Microsoft Quick Assist"
#=================================================
$Title = 'Removes Microsoft Quick Assist'
$host.ui.RawUI.WindowTitle = "$Title"
$host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.size(2000,2000)

# Define the app package name
$appPackageName = "MicrosoftCorporationII.QuickAssist"
 
# Function to remove the app for the current user
function Remove-AppxPackageByName {
    param (
        [string]$PackageName
    )
 
    $app = Get-AppxPackage -Name $PackageName -ErrorAction SilentlyContinue
    if ($app) {
        Remove-AppxPackage -Package $app.PackageFullName -ErrorAction SilentlyContinue
        Write-Output "Removed app package $PackageName for current user."
    } else {
        Write-Output "App package $PackageName not found for current user."
    }
}
 
# Function to remove the provisioned app
function Remove-AppxProvisionedPackageByName {
    param (
        [string]$PackageName
    )
 
    $app = Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq $PackageName}
    if ($app) {
        Remove-AppxProvisionedPackage -Online -PackageName $app.PackageName -ErrorAction SilentlyContinue
        Write-Output "Removed provisioned app package $PackageName."
    } else {
        Write-Output "Provisioned app package $PackageName not found."
    }
}
 
try {
    # Remove Quick Assist for the current user
    Remove-AppxPackageByName -PackageName $appPackageName
    
    # Remove the provisioned package so it does not get installed for new users
    Remove-AppxProvisionedPackageByName -PackageName $appPackageName
    
    Write-Output "Microsoft Quick Assist removal process completed."
}
catch {
    Write-Warning 'Unable to remove Microsoft Quick Assist'
}
#endregion

Stop-Transcript | out-null