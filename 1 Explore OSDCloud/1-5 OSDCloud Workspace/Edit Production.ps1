# Set the OSDCloud Workspace to Production
Set-OSDCloudWorkspace -WorkspacePath "C:\OSDCloud\Production"

# Edit WinPE
Edit-OSDCloudWinPE -UseDefaultWallpaper -CloudDriver * -UpdateUSB

# Test Virtual Machine
New-OSDCloudVM
