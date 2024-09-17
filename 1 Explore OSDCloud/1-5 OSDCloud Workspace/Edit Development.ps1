# Set the OSDCloud Workspace to Development
Set-OSDCloudWorkspace -WorkspacePath "C:\OSDCloud\Development"

# Edit WinPE
Edit-OSDCloudWinPE -UseDefaultWallpaper

# Test Virtual Machine
New-OSDCloudVM
