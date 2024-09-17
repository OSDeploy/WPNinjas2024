# Set the Execution Policy
if ((Get-ExecutionPolicy) -eq "Restricted") {Set-ExecutionPolicy RemoteSigned -Force -Verbose}

# Install the OSD PowerShell Module
Install-Module OSD –Force

# Install Windows 11 22H2 ADK
winget install --id Microsoft.WindowsADK --version 10.1.22621.1 --exact --accept-source-agreements --accept-package-agreements

# Install Windows 11 22H2 ADK WinPE Addons
winget install --id Microsoft.ADKPEAddon --version 10.1.22621.1 --exact --accept-source-agreements --accept-package-agreements

# Install Microsoft Deployment Toolkit
winget install --id Microsoft.DeploymentToolkit --version 6.3.8456.1000 --exact --accept-source-agreements --accept-package-agreements

# Install Git for Windows and refresh the Path
winget install --id Git.Git --exact --accept-source-agreements --accept-package-agreements
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Clone a personal Microsoft DaRT Repo
git clone https://github.com/OSDeploy/MicrosoftDaRT.git "C:\Program Files\Microsoft DaRT\v10"
