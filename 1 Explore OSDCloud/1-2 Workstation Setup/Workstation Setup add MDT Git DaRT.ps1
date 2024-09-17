# Install Microsoft Deployment Toolkit
winget install --id Microsoft.DeploymentToolkit --version 6.3.8456.1000 --exact --accept-source-agreements --accept-package-agreements

# Install Git for Windows and refresh the Path
winget install --id Git.Git --exact --accept-source-agreements --accept-package-agreements
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Clone a personal Microsoft DaRT Repo
git clone https://github.com/OSDeploy/MicrosoftDaRT.git "C:\Program Files\Microsoft DaRT\v10"
