param (
    [Parameter(Mandatory)]
    [String]$Environment,
    [Parameter(Mandatory)]
    [String]$App,
    [Parameter(Mandatory)]
    [String]$Location,
    [Parameter(Mandatory)]
    [String]$OrgName
)

Write-Output $PSScriptRoot
$LocationLookup = Get-Content -Path $PSScriptRoot\..\bicep\global\region.json | ConvertFrom-Json
$Prefix = $LocationLookup.$Location.Prefix

# Azure Blob Container Info
[String]$KVName = "${Prefix}-${OrgName}-${App}-${Environment}-kvGlobal".tolower()

$Temp = Get-Content -Path $PSScriptRoot\..\tenants\${OrgName}\${Prefix}-${App}-${Environment}.parameters.json | ConvertFrom-Json
$CertificateThumbprint = $Temp.parameters.DeploymentInfo.value.CertificateThumbprint

$BaseSecrets = @(
    @{ Name = 'Prefix'; Value = $Prefix },
    @{ Name = 'OrgName'; Value = $OrgName },
    @{ Name = 'App'; Value = $App },
    @{ Name = 'SpeechConfigKey'; Value = 'nullvalue' },
    @{ Name = 'Environment'; Value = $Environment },
    @{ 
        Name  = 'CertificateThumbprint'
        Value = $CertificateThumbprint
    },
    @{ 
        Name  = 'ServiceDNSName'
        Value = ('{0}-{1}-{2}-{3}-lbbotvmss01-1.{4}.cloudapp.azure.com' -f $prefix, $OrgName, $App, $Environment, $Location).ToLower()
    }
)

$BaseSecrets | ForEach-Object {

    $Secret = $_.Name
    $Value = $_.Value
    # LocalAdmin Creds
    Write-Verbose -Message "Primary KV Name: [$KVName] Secret for [$Secret]" -Verbose
    if (! (Get-AzKeyVaultSecret -VaultName $KVName -Name $Secret -EA SilentlyContinue))
    {
        try
        {
            $SV = $Value | ConvertTo-SecureString -AsPlainText -Force
            Set-AzKeyVaultSecret -VaultName $KVName -Name $Secret -SecretValue $SV
        }
        catch
        {
            Write-Warning $_
            break
        }
    }
    else 
    {
        Write-Output "`t Primary KV Name: $KVName Secret for [$Secret] Exists!!!`n`n" -Verbose
    }
}

# App Secrets required to be published to the keyvault
$RequiredSecrets = @() # @('AppName', 'AadAppId', 'AadAppSecret')
Write-Warning -Message "There are [$($RequiredSecrets.count)] Secrets required, you can enter them now or cancel."
Write-Warning -Message "You can add a prompt for secrets here: [ADF\release-az\Create-AppSecrets.ps1:64]"
Write-Warning -Message "The secrets used by the App are: [$($RequiredSecrets)]`n`n"

$RequiredSecrets | ForEach-Object {

    $Secret = $_
    # LocalAdmin Creds
    Write-Verbose -Message "Primary KV Name: [$KVName] Secret for [$Secret]" -Verbose
    if (! (Get-AzKeyVaultSecret -VaultName $KVName -Name $Secret -EA SilentlyContinue))
    {
        try
        {
            $options = 'Enter secret now?', 'Skip entering?' | ForEach-Object {
                [System.Management.Automation.Host.ChoiceDescription]::New("&$_", $_)
            }
            $chosen = $host.ui.PromptForChoice('Keyvault Secrets Setup', "Enter secret value for: [$Secret]", $options, 0)
            switch ($options[$chosen].HelpMessage)
            {
                'Skip entering?'
                {
                    Write-Warning -Message "Setting up Secret value [$Secret] skipped, please rerun before deploying!!!`n`n"
                }
                'Enter secret now?'
                {
                    Set-AzKeyVaultSecret -VaultName $KVName -Name $Secret
                }
            }
        }
        catch
        {
            Write-Warning $_
            break
        }
    }
    else 
    {
        Write-Output "`t Primary KV Name: $KVName Secret for [$Secret] Exists!!!`n`n" -Verbose
    }
}