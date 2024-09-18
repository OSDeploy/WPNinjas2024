# Demo of the WinPE StartURL parameter
# Edit-OSDCloudWinPE -StartURL "https://raw.githubusercontent.com/OSDeploy/WPNinjas2024/main/Examples/WinPEStartURLRestart.ps1"

# Run before OSDCloud

# Run OSDCloud
Start-OSDCloud -OSName 'Windows 11 23H2 x64' -OSEdition Enterprise -OSLanguage en-us

# Run after OSDCloud
Restart-Computer