# Set the Execution Policy
if ((Get-ExecutionPolicy) -eq "Restricted") {Set-ExecutionPolicy RemoteSigned -Force -Verbose}

# Install the OSD PowerShell Module
Install-Module OSD –Force

# Install Windows 11 23H2 ADK
winget install --id Microsoft.WindowsADK --version 10.1.25398.1 --exact --accept-source-agreements --accept-package-agreements

# Install Windows 11 23H2 ADK WinPE Addons
winget install --id Microsoft.ADKPEAddon --version 10.1.25398.1 --exact --accept-source-agreements --accept-package-agreements
