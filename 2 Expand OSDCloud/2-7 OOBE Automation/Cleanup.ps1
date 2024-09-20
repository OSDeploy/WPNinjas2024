# Cleanup the OSDCloud environment after the deployment

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

$Title = "Cleanup Tasks"
$host.UI.RawUI.WindowTitle = $Title
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials

$env:APPDATA = "C:\Windows\System32\Config\SystemProfile\AppData\Roaming"
$env:LOCALAPPDATA = "C:\Windows\System32\Config\SystemProfile\AppData\Local"
$Env:PSModulePath = $env:PSModulePath+";C:\Program Files\WindowsPowerShell\Scripts"
$env:Path = $env:Path+";C:\Program Files\WindowsPowerShell\Scripts"

$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Cleanup-Task.log"
Start-Transcript -Path (Join-Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" $Global:Transcript) -ErrorAction Ignore | Out-Null

$Title = "OSD Cleanup"
$host.UI.RawUI.WindowTitle = $Title
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
$env:APPDATA = "C:\Windows\System32\Config\SystemProfile\AppData\Roaming"
$env:LOCALAPPDATA = "C:\Windows\System32\Config\SystemProfile\AppData\Local"
$Env:PSModulePath = $env:PSModulePath+";C:\Program Files\WindowsPowerShell\Scripts"
$env:Path = $env:Path+";C:\Program Files\WindowsPowerShell\Scripts"

Write-SectionHeader "Execute OSD Cloud Cleanup Script"

Write-SectionSuccess "Copying the OOBEDeploy and AutopilotOOBE Logs"
Get-ChildItem 'C:\Windows\Temp' -Filter *OOBE* | Copy-Item -Destination 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD' -Force

Write-SectionSuccess "Copying OSDCloud Logs"
If (Test-Path -Path 'C:\OSDCloud\Logs') {
    Move-Item 'C:\OSDCloud\Logs\*.*' -Destination 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD' -Force -ErrorAction SilentlyContinue
}
Move-Item 'C:\ProgramData\OSDeploy\*.*' -Destination 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD' -Force

If (Test-Path -Path 'C:\Temp') {
    Get-ChildItem 'C:\Temp' -Filter *OOBE* | Copy-Item -Destination 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD' -Force
    Get-ChildItem 'C:\Windows\Temp' -Filter *Events* | Copy-Item -Destination 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD' -Force
}

Write-SectionSuccess "Cleanup Directories"
If (Test-Path -Path 'C:\OSDCloud') { Remove-Item -Path 'C:\OSDCloud' -Recurse -Force }
If (Test-Path -Path 'C:\Drivers') { Remove-Item 'C:\Drivers' -Recurse -Force }
If (Test-Path -Path 'C:\Intel') { Remove-Item 'C:\Intel' -Recurse -Force }
If (Test-Path -Path 'C:\ProgramData\OSDeploy') { Remove-Item 'C:\ProgramData\OSDeploy' -Recurse -Force }

Write-SectionSuccess "Cleanup Scripts"
Remove-Item C:\Windows\Setup\Scripts\*.* -Exclude *.TAG -Force | Out-Null
Get-ChildItem 'C:\Windows\Temp' -Filter *membeer*  | Remove-Item -Force

Stop-Transcript | Out-Null