@{
    # Version number of this module.
    moduleVersion        = '5.1.0'

    # ID used to uniquely identify this module
    GUID                 = '1b8d785e-79ae-4d95-ae58-b2460aec1031'

    # Author of this module
    Author               = 'DSC Community'

    # Company or vendor of this module
    CompanyName          = 'DSC Community'

    # Copyright statement for this module
    Copyright            = 'Copyright the DSC Community contributors. All rights reserved.'

    # Description of the functionality provided by this module
    Description          = 'DSC resources for managing certificates on a Windows Server.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion    = '4.0'

    # Minimum version of the common language runtime (CLR) required by this module
    CLRVersion           = '4.0'

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport    = @()

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport      = @()

    # Variables to export from this module
    VariablesToExport    = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport      = @()

    # DSC resources to export from this module
    DscResourcesToExport = @('CertificateExport','CertificateImport','CertReq','PfxImport','WaitForCertificateServices')

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData          = @{
        PSData = @{
            # Set to a prerelease string value if the release should be a prerelease.
            Prerelease   = ''

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('DesiredStateConfiguration', 'DSC', 'DSCResource', 'Certificate', 'PKI')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/dsccommunity/CertificateDsc/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/dsccommunity/CertificateDsc'

            # A URL to an icon representing this module.
            IconUri      = 'https://dsccommunity.org/images/DSC_Logo_300p.png'

            # ReleaseNotes of this module
            ReleaseNotes = '## [5.1.0] - 2021-02-26

### Added

- PfxImport:
  - Added Base64Content parameter to specify the content of a PFX file that can
    be included in the configuration MOF - Fixes [Issue #241](https://github.com/dsccommunity/CertificateDsc/issues/241).
- CertificateImport:
  - Added Base64Content parameter to specify the content of a certificate file
    that can be included in the configuration MOF - Fixes [Issue #241](https://github.com/dsccommunity/CertificateDsc/issues/241).

### Changed

- Fix bug where `Import-PfxCertificateEx` would not install private keys in the
  ALLUSERSPROFILE path when importing to LocalMachine store. [Issue #248](https://github.com/dsccommunity/CertificateDsc/issues/248).
- Renamed `master` branch to `main` - Fixes [Issue #237](https://github.com/dsccommunity/CertificateDsc/issues/237).
- Updated `GitVersion.yml` to latest pattern - Fixes [Issue #245](https://github.com/dsccommunity/CertificateDsc/issues/245).
- Changed `Test-Thumbprint` to cache supported hash algorithms to increase
  performance - Fixes [Issue #221](https://github.com/dsccommunity/CertificateDsc/issues/221).
- Added warning messages into empty catch blocks in `Certificate.PDT` module to
  assist with debugging.

### Fixed

- Removed requirement for tests to use `New-SelfSignedCertificateEx` from
  [TechNet Gallery due to retirement](https://docs.microsoft.com/teamblog/technet-gallery-retirement).
  This will prevent tests from running on Windows Server 2012 R2 - Fixes [Issue #250](https://github.com/dsccommunity/CertificateDsc/issues/250).
- Fixed FIPS support when used in versions of PowerShell Core 6 & PowerShell 7.
- Moved thumbprint generation for testing into helper function `New-CertificateThumbprint`
  and fixed tests for validating FIPS thumbprints in `Test-Thumbprint` so that it
  runs on PowerShell Core/7.x.

'
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}




