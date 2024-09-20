# Create a self-signed certificate for Autopilot registration

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
$certPassword = ConvertTo-SecureString -String "WPNinjaS2024!" -Force -AsPlainText

$pfxExport = @{
    Cert         = "Cert:\LocalMachine\My\$($certThumbprint)"
    FilePath     = "$($certFolder)\$($subjectName).pfx"
    ChainOption  = "EndEntityCertOnly"
    NoProperties = $null
    Password     = $certPassword
}
Export-PfxCertificate @pfxExport