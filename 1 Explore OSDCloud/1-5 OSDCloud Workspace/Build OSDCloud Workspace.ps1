# Set the OSDCloud Template to default
Set-OSDCloudTemplate -Name default
# Create an OSDCloud Workspace named Development
New-OSDCloudWorkspace -WorkspacePath "C:\OSDCloud\Development"

# Set the OSDCloud Template to Wireless
Set-OSDCloudTemplate -Name Wireless
# Create an OSDCloud Workspace named Production
New-OSDCloudWorkspace -WorkspacePath "C:\OSDCloud\Production"
