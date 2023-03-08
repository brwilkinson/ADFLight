@{
    # Version number of this module. This is controlled by gitversion.
    moduleVersion = '2.0.0'

    # ID used to uniquely identify this module
    GUID = 'b42ff085-bd2b-4232-90ba-02b4c780e2d9'

    # Author of this module
    Author = 'DSC Community'

    # Company or vendor of this module
    CompanyName = 'DSC Community'

    # Copyright statement for this module
    Copyright = 'Copyright the DSC Community contributors. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Module with DSC Resources for Remote Desktop Session Host'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '4.0'

    # Minimum version of the common language runtime (CLR) required by this module
    CLRVersion = '4.0'

    # Functions to export from this module
    FunctionsToExport = @()

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # DSC resources to export from this module
    DscResourcesToExport = @(
        'xRDCertificateConfiguration'
        'xRDGatewayConfiguration'
        'xRDLicenseConfiguration'
        'xRDRemoteApp'
        'xRDServer'
        'xRDSessionCollection'
        'xRDSessionCollectionConfiguration'
        'xRDsessionDeployment'
    )

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource')

            # A URL to an icon representing this module.
            IconUri = 'https://dsccommunity.org/images/DSC_Logo_300p.png'

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/dsccommunity/xRemoteDesktopSessionHost/blob/master/LICENSE'

            # Set to a prerelease string value if the release should be a prerelease.
            Prerelease = ''

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/dsccommunity/xRemoteDesktopSessionHost'

            # ReleaseNotes of this module
            ReleaseNotes = '## [2.0.0] - 2020-09-29

### Changed

- Updated filename for CHANGELOG.MD to CHANGELOG.md

## 2.0.0

### Added

- xRemoteDesktopSessionHost
  - Added automatic release with a new CI pipeline.
  - Added DSC HQRM Tests
- xRDCertificateConfiguration
  - New resource to configure the used certificate on a deployment

### Changed

- Changes to xRDSessionCollectionConfiguration
  - Fixing comparison of some RD Session Collection Configuration properties and
    supplied parameters by moving to the DscResource.Common `Test-DscParameterState` cmdlet.
    ([issue #82](https://github.com/dsccommunity/xRemoteDesktopSessionHost/issues/82)).
- Changes to xRDSessionDeployment
  - Fixing Get-TargetResource to target the connection broker, instead of
    assuming localhost
- Changes to xRDServer
  - Changed resouce key from Server alone to Role + Server.
    This allows the resource to be used multiple times for different roles on
    the same server. (Issue #62)
- Changes to xRemoteApp
  - Fix xRDRemoteApp Test-TargetResource to not test PowerShell common parameters
- Changes to tests
  - Pin tests to use Pester v4 instead of latest (v5)

## 1.9.0.0

- Changes to xRDRemoteApp
  - Fixing typo in parameter name when calling the function ValidateCustomModeParameters (issue #50).
- Changes to xRDSessionDeployment
  - When RDMS service does not exist the Get-TargetResource will no longer throw an error (issue #47).
- Rename Tests/Unit folder to use upper case on first letter.
- Update appveyor.yml to use the default template.
- Added default template files .codecov.yml, .gitattributes, and .gitignore, and
  .vscode folder.
- xRDSessionCollectionConfiguration:
  - Changed CollectionName variable validation max length to 256
- xRDSessionCollection
  - Changed CollectionName variable validation max length to 256
- xRDRemoteApp
  - Changed CollectionName variable validation max length to 256

## 1.8.0.0

- Changes to xRDSessionDeployment
  - Fixed issue where an initial deployment failed due to a convert to lowercase (issue #39).
  - Added unit tests to test Get, Test and Set results in this resource.
- Change to xRDRemoteApp
  - Fixed issue where this resource ignored the CollectionName provided in the parameters (issue #41).
  - Changed key values in schema.mof to only Alias and CollectionName, DisplayName and FilePath are not key values.
  - Added Ensure property (Absent or Present) to enable removal of RemoteApps.
  - Added unit tests to test Get, Test and Set results in this resource.

## 1.7.0.0

- Added additional resources, copied from the [Azure RDS quickstart templates](https://github.com/Azure/RDS-Templates).
- xRDSessionCollection:
  - Fixed call to Add-RDSessionHost in Set-TargetResource by properly removing CollectionDescription from PSBoundParameters (issue #28)
  - Fixed bug on Get-TargetResource that did return any collection instead of the one collection the user asked for (issue #27)
  - Added unit tests to test Get, Test and Set results in this resource

## 1.6.0.0

- xRDSessionCollectionConfiguration: Add support to configure UserProfileDisks on Windows Server 2016

## 1.5.0.0

- Fix issue where DSC configuration gets into a reboot loop because sessionhost does not match (casing) and RDMS service is not started in time

## 1.4.0.0

- Updated CollectionName parameter to validate length between 1 and 15 characters, and added tests to verify.

## 1.3.0.0

- Converted appveyor.yml to install Pester from PSGallery instead of from Chocolatey.

## 1.2.0.0

- Fixed an issue with version checks where OS version greater than 9 would fail (Windows 10/Server 2016)

## 1.1.0.0

- Fixed encoding

## 1.0.1

## 1.0.0.0

- Initial release with the following resources
  - xRDSessionDeployment
  - xRDSessionCollection
  - xRDSessionCollectionConfiguration
  - xRDRemoteApp
'

        } # End of PSData hashtable

    } # End of PrivateData hashtable
}










