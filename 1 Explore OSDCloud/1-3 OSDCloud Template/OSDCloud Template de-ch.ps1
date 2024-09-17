# OSDCloud Template named de-ch using the ADK WinPE.wim
# Add German Language Pack
# Set all International Defaults to Switzerland
# Set keyboard to de-CH Swiss German
New-OSDCloudTemplate -Name de-ch -Language de-de -SetAllIntl de-ch -SetInputLocale '0807:00000807'
