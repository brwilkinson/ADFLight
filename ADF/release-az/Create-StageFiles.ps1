param (
    [Parameter(Mandatory)]
    [String]$Environment,
    [Parameter(Mandatory)]
    [String]$App,
    [Parameter(Mandatory)]
    [String]$Location,
    [Parameter(Mandatory)]
    [String]$OrgName
    # [String]$ComponentName = 'EchoBot',
    # [String]$MetaDataFileName = 'componentBuild.json'
)

Write-Output $PSScriptRoot

$LocationLookup = Get-Content -Path $PSScriptRoot\..\bicep\global\region.json | ConvertFrom-Json
$Prefix = $LocationLookup.$Location.Prefix

if (!(Test-Path -Path "$PSScriptRoot\..\tenants\${OrgName}"))
{
    mkdir -Path "$PSScriptRoot\..\tenants\${OrgName}" -Force
}

$filestocopy = @(
    @{
        SourcePath      = "$PSScriptRoot\..\templates\azuredeploy.parameters.json"
        DestinationPath = "$PSScriptRoot\..\tenants\${OrgName}\${Prefix}-${App}-${Environment}.parameters.json"
        TokenstoReplace = @()
    }

    # @{
    #     SourcePath      = "$PSScriptRoot\..\templates\ado-pipelines.yml"
    #     DestinationPath = "$PSScriptRoot\..\tenants\${OrgName}\ado-pipelines-${Prefix}-${App}-${Environment}.yml"
    #     TokenstoReplace = @(
    #        'OrgName', 'App', 'Prefix', 'Environment', 'Location'
    #     )
    # }

    @{
        SourcePath      = "$PSScriptRoot\..\templates\GH-actions.yml"
        DestinationPath = "$PSScriptRoot\..\..\.github\workflows\GH-actions-${Prefix}-${App}-${Environment}.yml"
        TokenstoReplace = @(
            'OrgName', 'App', 'Prefix', 'Environment', 'Location'
        )
    }
)

$filestocopy | ForEach-Object {
    $Destination = $_.DestinationPath

    if (! (Test-Path -Path $Destination))
    {
        Copy-Item -Path $_.SourcePath -Destination $Destination -Force -Recurse
    }

    foreach ($token in $_.TokenstoReplace)
    {
        if (Select-String -Pattern "{$token}" -Path $Destination)
        {
            ((Get-Content -Path $Destination -Raw) -replace "{$token}", (Get-Item -Path variable:\$token).value ) | Set-Content -Path $Destination
        }
    }
}

# Stage meta data file on storage used for app releases
[String]$SAName = "${Prefix}${OrgName}${App}${Environment}saglobal".tolower()
$Context = New-AzStorageContext -StorageAccountName $SAName -UseConnectedAccount
[String]$ContainerName = 'builds'
$StorageContainerParams = @{
    Container = $ContainerName
    Context   = $Context
}

Write-Verbose -Message "Global SAName:`t`t [$SAName] Container is: [$ContainerName]" -Verbose
if (! (Get-AzStorageContainer @StorageContainerParams -EA 0))
{
    try
    {
        # Create the storage blob Containers
        New-AzStorageContainer @StorageContainerParams -ErrorAction Stop
    }
    catch
    {
        Write-Warning $_
        break
    }
}

# if (! (Get-AzStorageBlob @StorageContainerParams -Blob $ComponentName/$MetaDataFileName -EA 0))
# {
#     try
#     {
#         # Copy up the metadata file
#         $Item = Get-Item -Path $PSScriptRoot\..\templates\$MetaDataFileName
#         Set-AzStorageBlobContent @StorageContainerParams -File $item.FullName -Blob $ComponentName/$MetaDataFileName -Verbose -Force
#     }
#     catch
#     {
#         Write-Warning $_
#         break
#     }
# }