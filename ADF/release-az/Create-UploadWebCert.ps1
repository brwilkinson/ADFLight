param (
    [Parameter(Mandatory)]
    [String]$Environment,
    [Parameter(Mandatory)]
    [String]$App,
    [Parameter(Mandatory)]
    [String]$Location,
    [Parameter(Mandatory)]
    [String]$OrgName,
    [string]$TempCertPath = ('c:\temp\Certs')
)

Write-Output $PSScriptRoot
$LocationLookup = Get-Content -Path $PSScriptRoot\..\bicep\global\region.json | ConvertFrom-Json
$Prefix = $LocationLookup.$Location.Prefix
$DNSNames = @(
    "*.${Location}.cloudapp.azure.com"
)

# Azure Keyvault Info
[String]$KVName = "${Prefix}-${OrgName}-${App}-${Environment}-kvGlobal".tolower()
$CertFile = $DNSNames[0] -replace '\W', ''
$CertFilePath = Join-Path -Path $TempCertPath -ChildPath "$CertFile.pfx"
$CertExpiry = (Get-Date).AddYears(2)

if (! (Test-Path -Path $TempCertPath))
{
    mkdir $TempCertPath
}

# TLS Cert
Write-Verbose -Message "Primary KV Name:`t $KVName certificate for: [$($DNSNames[0])]" -Verbose
if (! (Get-AzKeyVaultCertificate -VaultName $KVName -Name WildcardCert -EA SilentlyContinue))
{
    try
    {
        $KV = Get-AzKeyVault -VaultName $KVName -EA SilentlyContinue
        $PW = Get-AzKeyVaultSecret -VaultName $KVName -Name localadmin -EA SilentlyContinue

        if (! $PW)
        {
            Throw 'Please setup Admin Credentials first'
        }

        # Create Web wildcard cert
        $CertParams = @{
            NotAfter          = $CertExpiry
            DnsName           = $DNSNames
            CertStoreLocation = 'Cert:\CurrentUser\My'
            Provider          = 'Microsoft Enhanced RSA and AES Cryptographic Provider'
            KeyUsageProperty  = 'All'
            KeyProtection     = 'None'
        }

        $cert = New-SelfSignedCertificate @CertParams
        $cert

        Export-PfxCertificate -FilePath $CertFilePath -Cert $cert -Password $PW.SecretValue

        # Write the Cert and the thumbprint and admin secret back to the param function 

        $Temp = Get-Content -Path $PSScriptRoot\..\tenants\${OrgName}\${Prefix}-${App}-${Environment}.parameters.json | ConvertFrom-Json
        $Temp.parameters.vmAdminPassword.reference.keyVault.id = $KV.ResourceId
        $Temp | ConvertTo-Json -Depth 10 | Set-Content -Path $PSScriptRoot\..\tenants\${OrgName}\${Prefix}-${App}-${Environment}.parameters.json
        
        $Temp = Get-Content -Path $PSScriptRoot\..\tenants\${OrgName}\${Prefix}-${App}-${Environment}.parameters.json | ConvertFrom-Json
        $Temp.parameters.DeploymentInfo.value.CertificateThumbprint = $cert.Thumbprint
        $Temp | ConvertTo-Json -Depth 10 | Set-Content -Path $PSScriptRoot\..\tenants\${OrgName}\${Prefix}-${App}-${Environment}.parameters.json

        Import-AzKeyVaultCertificate -FilePath $CertFilePath -Name WildcardCert -VaultName $KVName -Password $PW.SecretValue -OutVariable kvcert
        $Temp = Get-Content -Path $PSScriptRoot\..\tenants\${OrgName}\${Prefix}-${App}-${Environment}.parameters.json | ConvertFrom-Json
        $Temp.parameters.DeploymentInfo.value.certificateUrl = $kvcert[0].SecretId
        $Temp | ConvertTo-Json -Depth 10 | Set-Content -Path $PSScriptRoot\..\tenants\${OrgName}\${Prefix}-${App}-${Environment}.parameters.json
    }
    catch
    {
        Write-Warning $_
        break
    }
}
else
{
    Write-Warning "Certificate exists:`t [WildcardCert]"
}

