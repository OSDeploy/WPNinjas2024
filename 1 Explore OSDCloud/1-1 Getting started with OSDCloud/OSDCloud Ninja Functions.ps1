# Load the OSDCloud Ninja Functions
Invoke-Expression (Invoke-RestMethod https://ninja.osdcloud.com)

# Or use the alias to save keystrokes
iex (irm ninja.osdcloud.com)

# List the Ninja Functions
Get-Command ninja*

# Install the ADK + WinPE Addons
ninja-WinGetInstallADK23H2
