@{
    # Version number of this module.
    moduleVersion     = '2.0.0'

    # ID used to uniquely identify this module
    GUID              = '5f70e6a1-f1b2-4ba0-8276-8967d43a7ec2'

    # Author of this module
    Author            = 'DSC Community'

    # Company or vendor of this module
    CompanyName       = 'DSC Community'

    # Copyright statement for this module
    Copyright         = 'Copyright the DSC Community contributors. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'This module contains DSC resources for the management and configuration of Windows Server DNS Server.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.0'

    # Script module or binary module file associated with this manifest.
    RootModule = 'xDnsServer.psm1'

    # Functions to export from this module
    FunctionsToExport = @()

    # Cmdlets to export from this module
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport   = @()

    DscResourcesToExport = @('DnsRecordSrv','DnsRecordSrvScoped','xDnsRecord','xDnsRecordMx','xDnsServerADZone','xDnsServerClientSubnet','xDnsServerConditionalForwarder','xDnsServerDiagnostics','xDnsServerForwarder','xDnsServerPrimaryZone','xDnsServerRootHint','xDnsServerSecondaryZone','xDnsServerSetting','xDnsServerZoneAging','xDnsServerZoneScope','xDnsServerZoneTransfer','DnsRecordCname','DnsRecordPtr','DnsRecordA','DnsRecordAaaa','DnsRecordCnameScoped','DnsRecordMx','DnsServerEDns','DnsServerScavenging','DnsRecordAaaaScoped','DnsRecordAScoped','DnsRecordMxScoped')

    <#
      Private data to pass to the module specified in RootModule/ModuleToProcess.
      This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    #>
    PrivateData       = @{
        PSData = @{
            # Set to a prerelease string value if the release should be a prerelease.
            Prerelease   = ''

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/dsccommunity/xDnsServer/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/dsccommunity/xDnsServer'

            # A URL to an icon representing this module.
            IconUri = 'https://dsccommunity.org/images/DSC_Logo_300p.png'

            # ReleaseNotes of this module
            ReleaseNotes = '## [2.0.0] - 2021-03-26

### Deprecated

- **The module _xDnsServer_ will be renamed _DnsServerDsc_. Version `2.0.0`
  will be the the last release of _xDnsServer_. Version `3.0.0` will be
  release as _DnsServerDsc_, it will be released shortly after the `2.0.0`
  release** ([issue #179](https://github.com/dsccommunity/xDnsServer/issues/179)).
  The prefix ''x'' will be removed from all resources in _DnsServerDsc_.
- xDnsRecord will be removed in the next release (of DnsServerDsc) ([issue #220](https://github.com/dsccommunity/xDnsServer/issues/220)).
  Start migrate to the resources _DnsRecord*_.
- xDnsRecordMx will be removed in the next release (of DnsServerDsc) ([issue #228](https://github.com/dsccommunity/xDnsServer/issues/228)).
  Start migrate to the resources _DnsRecordMx_.
- The properties `DefaultAgingState`, `ScavengingInterval`, `DefaultNoRefreshInterval`,
  and `DefaultRefreshInterval` will be removed from the resource xDnsServerSetting
  in the next release (of DnsServerDsc) ([issue #193](https://github.com/dsccommunity/xDnsServer/issues/193)).
  Migrate to use the resource _DnsServerScavenging_ to enforce these properties.
- The properties `EnableEDnsProbes` and `EDnsCacheTimeout` will be removed from
  the resource xDnsServerSetting in the next release (of DnsServerDsc) ([issue #195](https://github.com/dsccommunity/xDnsServer/issues/195)).
  Migrate to use the resource _DnsServerEDns_ to enforce these properties.
- The properties `Forwarders` and `ForwardingTimeout` will be removed from the
  resource xDnsServerSetting in the next release (of DnsServerDsc) ([issue #192](https://github.com/dsccommunity/xDnsServer/issues/192))
  Migrate to use the resource _xDnsServerForwarder_ to enforce these properties.

### Added

- xDnsServer
  - Added automatic release with a new CI pipeline.
  - Add unit tests for the Get-LocalizedData, NewTerminatingError, and
    Assert-Module helper functions.
  - Added description README files for each resource.
  - Add example files for resources
  - OptIn to the following Dsc Resource Meta Tests:
    - Common Tests - Validate Localization
    - Common Tests - Validate Example Files To Be Published
  - Standardize Resource Localization.
  - Added the build task `Publish_GitHub_Wiki_Content` to publish content
    to the GitHub repository wiki.
  - Added new source folder `WikiSource` which content will be published
    to the GitHub repository wiki.
    - Add the markdown file `Home.md` which will be automatically updated
      with the latest version before published to GitHub repository wiki.
  - Updated the prerequisites in the GitHub repository wiki (`Home.md`)
    that _Microsoft DNS Server_ is required on a node targeted by a resource,
    and that the DSC resources requires the [DnsServer](https://docs.microsoft.com/en-us/powershell/module/dnsserver)
    PowerShell module ([issue #37](https://github.com/dsccommunity/xDnsServer/issues/37)).
  - Added the base class `ResourcePropertiesBase` to hold DSC properties that
    can be inherited for all class-based resources.
  - Added the base class `ResourceBase` to hold methods that should be
    inherited for all class-based resources.
  - Added new private function `ConvertTo-TimeSpan` to help when evaluating
    properties that must be passed as strings and then converted to `[System.TimeSpan]`.
  - Added new private function `Assert-TimeSpan` to help assert that a value
    provided in a resource can be converted to a `[System.TimeSpan]` and
    optionally evaluates so it is not below a minium value or over a maximum
    value.
  - Added `prefix.ps1` that is used to import dependent modules like _DscResource.Common_.
  - Added new resource
    - _DnsServerScavenging_ - resource to enforce scavenging settings ([issue #189](https://github.com/dsccommunity/xDnsServer/issues/189)).
    - _DnsServerEDns_ - resource to enforce extension mechanisms for DNS
      (EDNS) settings ([issue #194](https://github.com/dsccommunity/xDnsServer/issues/194)).
- xDNSServerClientSubnet
  - Added integration tests.
- xDnsServerPrimaryZone
  - Added integration tests ([issue #173](https://github.com/dsccommunity/xDnsServer/issues/173)).
  - Added more examples.
- xDnsRecordMx
  - Added new resource to manage MX records
- xDnsServerZoneScope
  - Added integration tests ([issue #177](https://github.com/dsccommunity/xDnsServer/issues/177)).
  - New read-only property `ZoneFile` was added to return the zone scope
    file name used for the zone scope.
- xDnsServerZoneAging
  - Added integration tests ([issue #176](https://github.com/dsccommunity/xDnsServer/issues/176)).
- xDnsServerForwarder
  - Added integration tests ([issue #170](https://github.com/dsccommunity/xDnsServer/issues/170)).
  - Added new properties `Timeout` and `EnableReordering` ([issue #191](https://github.com/dsccommunity/xDnsServer/issues/191)).
- xDnsServerRootHint
  - Added integration tests ([issue #174](https://github.com/dsccommunity/xDnsServer/issues/174)).
- Added a class `DnsRecordBase` that is used as the base class for the resources that create DNS records.
  - Added unit tests to get code coverage on unimplemented method calls (ensuring the `throw` statements get called)
- DnsRecordSrv
  - Added new resource to manage SRV records
- DnsRecordSrvScoped
  - Added new resource to manage scoped SRV records
- DnsRecordA
  - Added new resource to manage A records
- DnsRecordAScoped
  - Added new resource to manage scoped A records
- DnsRecordAaaa
  - Added new resource to manage AAAA records
- DnsRecordAaaaScoped
  - Added new resource to manage scoped AAAA records
- DnsRecordCname
  - Added new resource to manage CNAME records
- DnsRecordCnameScoped
  - Added new resource to manage scoped CNAME records
- DnsRecordPtr
  - Added new resource to manage PTR records
- DnsRecordMx
  - Added new resource to manage MX records
- DnsRecordMxScoped
  - Added new resource to manage scoped MX records

### Changed

- xDnsServer
  - BREAKING CHANGE: Set the minimum required PowerShell version to 5.0 to support classes used in the DnsRecordBase-derived resources.
  - Resolve style guideline violations for hashtables
  - Update pipeline files.
  - Renamed the default branch to `main` ([issue #131](https://github.com/dsccommunity/xDnsServer/issues/131)).
  - Uses `PublishPipelineArtifact` in  _Azure Pipelines_ pipeline.
  - Unit tests are now run in PowerShell 7 in the _Azure Pipelines_
    pipeline ([issue #160](https://github.com/dsccommunity/xDnsServer/issues/160)).
  - Merged the historic changelog into CHANGELOG.md ([issue #163](https://github.com/dsccommunity/xDnsServer/issues/163)).
  - Only add required role in integration tests pipeline.
  - Updated the pipeline to use new deploy tasks.
  - Revert back to using the latest version of module Sampler for the pipeline ([issue #211](https://github.com/dsccommunity/xDnsServer/issues/211)).
  - Fixed the sections in the GitHub issue and pull request templates to
    have a bit higher font size. This makes it easier to distinguish the
    section headers from the text.
- DnsRecordBase
  - Changed class to inherit properties from ''ResourcePropertiesBase`.
- xDnsRecordSrv
  - Now uses `[CimInstance]::new()` both in the resource code and the resource
    unit test to clone the existing DNS record instead of using the method
    `Clone()` that does not exist in PowerShell 7.
- xDnsServerSetting
  - BREAKING CHANGE: The mandatory parameter was replaced by the mandatory
    parameter `DnsServer`. This prevents the resource from being used twice
    in the same configuration using the same value for the parameter `DnsServer`
    ([issue #156](https://github.com/dsccommunity/xDnsServer/issues/156)).
- xDnsServerDiagnostics
  - BREAKING CHANGE: The mandatory parameter was replaced by the mandatory
    parameter `DnsServer`. This prevents the resource from being used twice
    in the same configuration using the same value for the parameter `DnsServer`
    ([issue #157](https://github.com/dsccommunity/xDnsServer/issues/157)).
- xDnsServerPrimaryZone
  - Now the property `Name` is always returned from `Get-TargetResource`
    since it is a `Key` property.
- xDnsServerForwarder
  - When providing an empty collection the resource will enforce that no
    forwarders are present.
- DnsRecordSrv
  - Changed logic for calculating the record''s hostname

### Removed

- xDnsServer
  - BREAKING CHANGE: The DSC resource xDnsARecord was removed and are replaced
    by the DSC resource xDnsRecord.
  - Removing resource parameter information from README.md in favor of
    GitHub repository wiki.
  - Remove helper function `Remove-CommonParameter` in favor of the one in
    module _DscResource.Common_ ([issue #166](https://github.com/dsccommunity/xDnsServer/issues/166)).
  - Remove helper function `ConvertTo-CimInstance` in favor of the one in
    module _DscResource.Common_ ([issue #167](https://github.com/dsccommunity/xDnsServer/issues/167)).
  - Remove helper function `ConvertTo-HashTable` in favor of the one in
    module _DscResource.Common_ ([issue #168](https://github.com/dsccommunity/xDnsServer/issues/168)).
- xDnServerSetting
  - BREAKING CHANGE: The properties `LogIPFilterList`, `LogFilePath`, `LogFileMaxSize`,
    and `EventLogLevel` have been removed. Use the resource _xDnsServerDiagnostics_
    with the properties `FilterIPAddressList`, `LogFilePath`, `MaxMBFileSize`,
    and `EventLogLevel` respectively to enforce these settings ([issue #190](https://github.com/dsccommunity/xDnsServer/issues/190)).
    This is done in preparation to support more settings through the cmdlet
    `Get-DnsServerSetting` for the resource _xDnServerSetting_, and these
    values are not available through that cmdlet.

### Fixed

- xDnsServer
  - Enable Unit Tests to be run locally.
  - Rename integr'
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}




