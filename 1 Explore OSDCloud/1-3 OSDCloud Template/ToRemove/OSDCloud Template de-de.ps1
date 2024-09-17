# OSDCloud Template named de-de using the ADK WinPE.wim
# Add German Language Pack
# Set all International Defaults to German
# Set keyboard to de-CH Swiss German
New-OSDCloudTemplate -Name de-de -Language de-de -SetAllIntl de-de -SetInputLocale '0807:00000807'
