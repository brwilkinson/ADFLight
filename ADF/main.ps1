param (
    [parameter(mandatory)]
    [string]$OrgName,

    [string]$App = 'APP',

    [string]$Environment = 'D1',

    [string]$Location = 'centralus',

    [switch]$FullUpload,

    [switch]$PackageDSC
)

$base = $PSScriptRoot
$LocationLookup = Get-Content -Path $base/bicep/global/region.json | ConvertFrom-Json
$Prefix = $LocationLookup.$Location.Prefix
Write-Warning -Message "Prefix [$Prefix] Org [$OrgName] App [$App] Environment [$Environment]"
[String]$SAName = "${Prefix}${OrgName}${App}${Environment}saglobal".tolower()

$Context = Get-AzContext | Select-Object Name, Account, Environment, Subscription, Tenant
if ($Context)
{
    Write-Verbose -Message "Deploying to:`n $($Context | Format-List | Out-String)" -Verbose
    
    . $base\release-az\Start-AzDeploy.ps1
    
    $Params = @{
        Prefix             = $Prefix
        App                = $App
        OrgName            = $OrgName
        Environment        = $Environment
        StorageAccountName = $SAName
        PackageDSC         = $PackageDSC
    }
    AzDeploy @Params -FullUpload:$FullUpload
}