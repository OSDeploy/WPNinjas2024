<#
.SYNOPSIS
Create a self-signed certificate for Autopilot registration.

.NOTES
   Version:			0.1
   Creation Date:	27.08.2024
   Author:			Ákos Bakos
   Company:			SmartCon GmbH
   Contact:			akos.bakos@smartcon.ch

   Copyright (c) 2024 SmartCon GmbH

HISTORY:
Date			By			Comments
----------		---			----------------------------------------------------------
27.08.2024		Ákos Bakos	Script created

#>

# Create public (self-signed) certificate
$subjectName = "AutopilotRegistration"

$newCert = @{
    Subject           = "CN=$($subjectName)"
    CertStoreLocation = "Cert:\LocalMachine\My"
    KeyExportPolicy   = "Exportable"
    KeySpec           = "Signature"
    KeyLength         = "2048"
    KeyAlgorithm      = "RSA"
    HashAlgorithm     = "SHA512"
    NotAfter          = (Get-Date).AddMonths(60) #5 years validity period
}
$Cert = New-SelfSignedCertificate @newCert

# Export public key only
New-Item -Path "C:\OSDCloud\Certs" -ItemType Directory -Force | Out-Null
$certFolder = "C:\OSDCloud\Certs"
$certExport = @{
    Cert     = $Cert
    FilePath = "$($certFolder)\$($subjectName).cer"
}
Export-Certificate @certExport

# Export with private key
$certThumbprint = $Cert.Thumbprint # xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
$certPassword = ConvertTo-SecureString -String "H1ghS3cureP@ssword!" -Force -AsPlainText

$pfxExport = @{
    Cert         = "Cert:\LocalMachine\My\$($certThumbprint)"
    FilePath     = "$($certFolder)\$($subjectName).pfx"
    ChainOption  = "EndEntityCertOnly"
    NoProperties = $null
    Password     = $certPassword
}
Export-PfxCertificate @pfxExport