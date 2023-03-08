#Region './prefix.ps1' 0
# Import nested, 'DscResource.Common' module
$script:dscResourceCommonModulePath = Join-Path -Path $PSScriptRoot -ChildPath 'Modules\DscResource.Common'
Import-Module -Name $script:dscResourceCommonModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'
#EndRegion './prefix.ps1' 6
#Region './Enum/1.Ensure.ps1' 0
enum Ensure
{
    Present
    Absent
}
#EndRegion './Enum/1.Ensure.ps1' 6
#Region './Classes/001.ResourceBase.ps1' 0
<#
    .SYNOPSIS
        A class with methods that are equal for all class-based resources.

    .DESCRIPTION
       A class with methods that are equal for all class-based resources.

    .NOTES
        This class should not contain any DSC properties.
#>

class ResourceBase
{
    # Hidden property for holding localization strings
    hidden [System.Collections.Hashtable] $localizedData = @{}

    # Default constructor
    ResourceBase()
    {
        Assert-Module -ModuleName 'DnsServer'

        $localizedDataFileName = ('{0}.strings.psd1' -f $this.GetType().Name)

        $this.localizedData = Get-LocalizedData -DefaultUICulture 'en-US' -FileName $localizedDataFileName
    }

    [ResourceBase] Get([Microsoft.Management.Infrastructure.CimInstance] $CommandProperties)
    {
        $dscResourceObject = [System.Activator]::CreateInstance($this.GetType())

        foreach ($propertyName in $this.PSObject.Properties.Name)
        {
            if ($propertyName -in @($CommandProperties.PSObject.Properties.Name))
            {
                $dscResourceObject.$propertyName = $CommandProperties.$propertyName
            }
        }

        # Always set this as it won't be in the $CommandProperties
        $dscResourceObject.DnsServer = $this.DnsServer

        return $dscResourceObject
    }

    [void] Set()
    {
    }

    [System.Boolean] Test()
    {
        $isInDesiredState = $true

        <#
            Returns all enforced properties not in desires state, or $null if
            all enforced properties are in desired state.
        #>
        $propertiesNotInDesiredState = $this.Compare()

        if ($propertiesNotInDesiredState)
        {
            $isInDesiredState = $false
        }

        return $isInDesiredState
    }

    # Returns a hashtable containing all properties that should be enforced.
    hidden [System.Collections.Hashtable[]] Compare()
    {
        $currentState = $this.Get() | ConvertTo-HashTableFromObject
        $desiredState = $this | ConvertTo-HashTableFromObject

        # Remove properties that have $null as the value.
        @($desiredState.Keys) | ForEach-Object -Process {
            $isReadProperty = $this.GetType().GetMember($_).CustomAttributes.Where( { $_.NamedArguments.MemberName -eq 'NotConfigurable' }).NamedArguments.TypedValue.Value -eq $true

            # Also remove read properties so that there is no chance to campare those.
            if ($isReadProperty -or $null -eq $desiredState[$_])
            {
                $desiredState.Remove($_)
            }
        }

        $CompareDscParameterState = @{
            CurrentValues     = $currentState
            DesiredValues     = $desiredState
            Properties        = $desiredState.Keys
            ExcludeProperties = @('DnsServer')
            IncludeValue      = $true
        }

        <#
            Returns all enforced properties not in desires state, or $null if
            all enforced properties are in desired state.
        #>
        return (Compare-DscParameterState @CompareDscParameterState)
    }

    # Returns a hashtable containing all properties that should be enforced.
    hidden [System.Collections.Hashtable] GetDesiredStateForSplatting([System.Collections.Hashtable[]] $Properties)
    {
        $desiredState = @{}

        $Properties | ForEach-Object -Process {
            $desiredState[$_.Property] = $_.ExpectedValue
        }

        return $desiredState
    }
}
#EndRegion './Classes/001.ResourceBase.ps1' 111
#Region './Classes/001.ResourcePropertiesBase.ps1' 0
<#
    .SYNOPSIS
        A class with DSC properties that are equal for all class-based resources.

    .DESCRIPTION
       A class with DSC properties that are equal for all class-based resources.

    .PARAMETER DnsServer
        The host name of the Domain Name System (DNS) server, or use 'localhost'
        for the current node. Defaults to `'localhost'`.
#>

class ResourcePropertiesBase
{
    [DscProperty()]
    [System.String]
    $DnsServer = 'localhost'
}
#EndRegion './Classes/001.ResourcePropertiesBase.ps1' 19
#Region './Classes/002.DnsRecordBase.ps1' 0
<#
    .SYNOPSIS
        A DSC Resource for MS DNS Server that is not exposed to end users representing the common fields available to all resource records.

    .DESCRIPTION
        A DSC Resource for MS DNS Server that is not exposed to end users representing the common fields available to all resource records.

    .PARAMETER ZoneName
        Specifies the name of a DNS zone. (Key Parameter)

    .PARAMETER TimeToLive
        Specifies the TimeToLive value of the SRV record. Value must be in valid TimeSpan string format (i.e.: Days.Hours:Minutes:Seconds.Miliseconds or 30.23:59:59.999).

    .PARAMETER Ensure
        Whether the host record should be present or removed.
#>

class DnsRecordBase : ResourcePropertiesBase
{
    [DscProperty(Key)]
    [System.String]
    $ZoneName

    [DscProperty()]
    [System.String]
    $TimeToLive

    [DscProperty()]
    [Ensure]
    $Ensure = [Ensure]::Present

    # Hidden property to determine whether the class is a scoped version
    hidden [System.Boolean] $isScoped

    # Hidden property for holding localization strings
    hidden [System.Collections.Hashtable] $localizedData

    # Hidden method to integrate localized strings from classes up the inheritance stack
    hidden [void] SetLocalizedData()
    {
        # Create a list of the inherited class names
        $inheritedClasses = @(,$this.GetType().Name)
        $parentClass = $this.GetType().BaseType
        while ($parentClass -ne [System.Object])
        {
            $inheritedClasses += $parentClass.Name
            $parentClass = $parentClass.BaseType
        }

        $this.localizedData = @{}

        foreach ($className in $inheritedClasses)
        {
            # Get localized data for the class
            $localizationFile = "$($className).strings.psd1"

            try
            {
                $tmpData = Get-LocalizedData -DefaultUICulture 'en-US' -FileName $localizationFile -ErrorAction Stop

                # Append only previously unspecified keys in the localization data
                foreach ($key in $tmpData.Keys)
                {
                    if (-not $this.localizedData.ContainsKey($key))
                    {
                        $this.localizedData[$key] = $tmpData[$key]
                    }
                }
            }
            catch
            {
                if ($_.CategoryInfo.Category.ToString() -eq 'ObjectNotFound')
                {
                    Write-Warning $_.Exception.Message
                }
                else
                {
                    throw $_
                }
            }
        }

        Write-Debug ($this.localizedData | ConvertTo-JSON)
    }

    # Default constructor sets the $isScoped variable and loads the localization strings
    DnsRecordBase()
    {
        # Determine scope
        $this.isScoped = $this.PSObject.Properties.Name -contains 'ZoneScope'

        # Import the localization strings
        $this.SetLocalizedData()
    }

    #region Generic DSC methods -- DO NOT OVERRIDE

    [DnsRecordBase] Get()
    {
        Write-Verbose -Message ($this.localizedData.GettingDscResourceObject -f $this.GetType().Name)

        $dscResourceObject = $null

        $record = $this.GetResourceRecord()

        if ($null -eq $record)
        {
            Write-Verbose -Message $this.localizedData.RecordNotFound

            <#
                Create an object of the correct type (i.e.: the subclassed resource type)
                and set its values to those specified in the object, but set Ensure to Absent
            #>
            $dscResourceObject = [System.Activator]::CreateInstance($this.GetType())

            foreach ($propertyName in $this.PSObject.Properties.Name)
            {
                $dscResourceObject.$propertyName = $this.$propertyName
            }

            $dscResourceObject.Ensure = 'Absent'
        }
        else
        {
            Write-Verbose -Message $this.localizedData.RecordFound

            # Build an object reflecting the current state based on the record found
            $dscResourceObject = $this.NewDscResourceObjectFromRecord($record)
        }

        return $dscResourceObject
    }

    [void] Set()
    {
        # Initialize dns cmdlet Parameters for removing a record
        $dnsParameters = @{
            ZoneName     = $this.ZoneName
            ComputerName = $this.DnsServer
        }

        # Accomodate for scoped records as well
        if ($this.isScoped)
        {
            $dnsParameters['ZoneScope'] = ($this.PSObject.Properties | Where-Object -FilterScript { $_.Name -eq 'ZoneScope' }).Value
        }

        $existingRecord = $this.GetResourceRecord()

        if ($this.Ensure -eq 'Present')
        {
            if ($null -ne $existingRecord)
            {
                $currentState = $this.Get() | ConvertTo-HashTableFromObject
                $desiredState = $this | ConvertTo-HashTableFromObject

                # Remove properties that have $null as the value
                @($desiredState.Keys) | ForEach-Object -Process {
                    if ($null -eq $desiredState[$_])
                    {
                        $desiredState.Remove($_)
                    }
                }

                # Returns all enforced properties not in desires state, or $null if all enforced properties are in desired state
                $propertiesNotInDesiredState = Compare-DscParameterState -CurrentValues $currentState -DesiredValues $desiredState -Properties $desiredState.Keys -IncludeValue

                if ($null -ne $propertiesNotInDesiredState)
                {
                    Write-Verbose -Message $this.localizedData.ModifyingExistingRecord

                    $this.ModifyResourceRecord($existingRecord, $propertiesNotInDesiredState)
                }
            }
            else
            {
                Write-Verbose -Message ($this.localizedData.AddingNewRecord -f $this.GetType().Name)

                # Adding record
                $this.AddResourceRecord()
            }
        }
        elseif ($this.Ensure -eq 'Absent')
        {
            if ($null -ne $existingRecord)
            {
                Write-Verbose -Message $this.localizedData.RemovingExistingRecord

                # Removing existing record
                $existingRecord | Remove-DnsServerResourceRecord @dnsParameters -Force
            }
        }
    }

    [System.Boolean] Test()
    {
        $isInDesiredState = $true

        $currentState = $this.Get() | ConvertTo-HashTableFromObject
        $desiredState = $this | ConvertTo-HashTableFromObject

        if ($this.Ensure -eq 'Present')
        {
            if ($currentState.Ensure -eq 'Present')
            {
                # Remove properties that have $null as the value
                @($desiredState.Keys) | ForEach-Object -Process {
                    if ($null -eq $desiredState[$_])
                    {
                        $desiredState.Remove($_)
                    }
                }

                # Returns all enforced properties not in desires state, or $null if all enforced properties are in desired state
                $propertiesNotInDesiredState = Compare-DscParameterState -CurrentValues $currentState -DesiredValues $desiredState -Properties $desiredState.Keys -ExcludeProperties @('Ensure')

                if ($propertiesNotInDesiredState)
                {
                    $isInDesiredState = $false
                }
            }
            else
            {
                Write-Verbose -Message ($this.localizedData.PropertyIsNotInDesiredState -f 'Ensure', $desiredState['Ensure'], $currentState['Ensure'])

                $isInDesiredState = $false
            }
        }

        if ($this.Ensure -eq 'Absent')
        {
            if ($currentState['Ensure'] -eq 'Present')
            {
                Write-Verbose -Message ($this.localizedData.PropertyIsNotInDesiredState -f 'Ensure', $desiredState['Ensure'], $currentState['Ensure'])

                $isInDesiredState = $false
            }
        }

        if ($isInDesiredState)
        {
            Write-Verbose -Message $this.localizedData.ObjectInDesiredState
        }
        else
        {
            Write-Verbose -Message $this.localizedData.ObjectNotInDesiredState
        }

        return $isInDesiredState
    }

    #endregion

    #region Methods to override

    # Using the values supplied to $this, query the DNS server for a resource record and return it
    hidden [Microsoft.Management.Infrastructure.CimInstance] GetResourceRecord()
    {
        throw $this.localizedData.GetResourceRecordNotImplemented
    }

    # Add a resource record using the properties of this object.
    hidden [void] AddResourceRecord()
    {
        throw $this.localizedData.AddResourceRecordNotImplemented
    }

    <#
        Modifies a resource record using the properties of this object.

        The data in each hashtable will contain the following properties:

        - ActualType (System.RuntimeType)
        - ExpectedType (System.RuntimeType)
        - Property (String)
        - ExpectedValue (the property's type)
        - ActualValue (the property's type)
        - InDesiredState (System.Boolean)
    #>
    hidden [void] ModifyResourceRecord([Microsoft.Management.Infrastructure.CimInstance] $existingRecord, [System.Collections.Hashtable[]] $propertiesNotInDesiredState)
    {
        throw $this.localizedData.ModifyResourceRecordNotImplemented
    }

    # Given a resource record object, create an instance of this class with the appropriate data
    hidden [DnsRecordBase] NewDscResourceObjectFromRecord($record)
    {
        throw $this.localizedData.NewResourceObjectFromRecordNotImplemented
    }

    #endregion
}
#EndRegion './Classes/002.DnsRecordBase.ps1' 293
#Region './Classes/002.DnsRecordCname.ps1' 0
<#
    .SYNOPSIS
        The DnsRecordCname DSC resource manages CNAME DNS records against a specific zone on a Domain Name System (DNS) server.

    .DESCRIPTION
        The DnsRecordCname DSC resource manages CNAME DNS records against a specific zone on a Domain Name System (DNS) server.

    .PARAMETER Name
       Specifies the name of a DNS server resource record object. (Key Parameter)

    .PARAMETER HostNameAlias
       Specifies a a canonical name target for a CNAME record. This must be a fully qualified domain name (FQDN). (Key Parameter)
#>

[DscResource()]
class DnsRecordCname : DnsRecordBase
{
    [DscProperty(Key)]
    [System.String]
    $Name

    [DscProperty(Key)]
    [System.String]
    $HostNameAlias

    [DnsRecordCname] Get()
    {
        return ([DnsRecordBase] $this).Get()
    }

    [void] Set()
    {
        ([DnsRecordBase] $this).Set()
    }

    [System.Boolean] Test()
    {
        return ([DnsRecordBase] $this).Test()
    }

    hidden [Microsoft.Management.Infrastructure.CimInstance] GetResourceRecord()
    {
        Write-Verbose -Message ($this.localizedData.GettingDnsRecordMessage -f 'CNAME', $this.ZoneName, $this.ZoneScope, $this.DnsServer)

        $dnsParameters = @{
            ZoneName     = $this.ZoneName
            ComputerName = $this.DnsServer
            RRType       = 'CNAME'
            Name         = $this.Name
        }

        if ($this.isScoped)
        {
            $dnsParameters['ZoneScope'] = $this.ZoneScope
        }

        $record = Get-DnsServerResourceRecord @dnsParameters -ErrorAction SilentlyContinue | Where-Object -FilterScript {
            $_.RecordData.HostNameAlias -eq "$($this.HostnameAlias)."
        }

        return $record
    }

    hidden [DnsRecordCname] NewDscResourceObjectFromRecord([Microsoft.Management.Infrastructure.CimInstance] $record)
    {
        $dscResourceObject = [DnsRecordCname] @{
            ZoneName      = $this.ZoneName
            Name          = $this.Name
            HostNameAlias = $this.HostNameAlias
            TimeToLive    = $record.TimeToLive.ToString()
            DnsServer     = $this.DnsServer
            Ensure        = 'Present'
        }

        return $dscResourceObject
    }

    hidden [void] AddResourceRecord()
    {
        $dnsParameters = @{
            ZoneName      = $this.ZoneName
            ComputerName  = $this.DnsServer
            CNAME         = $true
            Name          = $this.Name
            HostNameAlias = $this.HostNameAlias
        }

        if ($this.isScoped)
        {
            $dnsParameters['ZoneScope'] = $this.ZoneScope
        }

        if ($null -ne $this.TimeToLive)
        {
            $dnsParameters.Add('TimeToLive', $this.TimeToLive)
        }

        Write-Verbose -Message ($this.localizedData.CreatingDnsRecordMessage -f 'CNAME', $this.ZoneName, $this.ZoneScope, $this.DnsServer)

        Add-DnsServerResourceRecord @dnsParameters
    }

    hidden [void] ModifyResourceRecord([Microsoft.Management.Infrastructure.CimInstance] $existingRecord, [System.Collections.Hashtable[]] $propertiesNotInDesiredState)
    {
        $dnsParameters = @{
            ZoneName     = $this.ZoneName
            ComputerName = $this.DnsServer
        }

        if ($this.isScoped)
        {
            $dnsParameters['ZoneScope'] = $this.ZoneScope
        }

        # Copy the existing record and modify values as appropriate
        $newRecord = [Microsoft.Management.Infrastructure.CimInstance]::new($existingRecord)

        foreach ($propertyToChange in $propertiesNotInDesiredState)
        {
            switch ($propertyToChange.Property)
            {
                # Key parameters will never be affected, so only include Mandatory and Optional values in the switch statement
                'TimeToLive'
                {
                    $newRecord.TimeToLive = [System.TimeSpan] $propertyToChange.ExpectedValue
                }

            }
        }

        Set-DnsServerResourceRecord @dnsParameters -OldInputObject $existingRecord -NewInputObject $newRecord -Verbose
    }
}
#EndRegion './Classes/002.DnsRecordCname.ps1' 134
#Region './Classes/002.DnsRecordPtr.ps1' 0
<#
    .SYNOPSIS
        The DnsRecordPtr DSC resource manages PTR DNS records against a specific zone on a Domain Name System (DNS) server.

    .DESCRIPTION
        The DnsRecordPtr DSC resource manages PTR DNS records against a specific zone on a Domain Name System (DNS) server.

    .PARAMETER IpAddress
       Specifies the IP address to which the record is associated (Can be either IPv4 or IPv6. (Key Parameter)

    .PARAMETER Name
       Specifies the FQDN of the host when you add a PTR resource record. (Key Parameter)

    .NOTES
       Reverse lookup zones do not support scopes, so there should be no DnsRecordPtrScoped subclass created.
#>

[DscResource()]
class DnsRecordPtr : DnsRecordBase
{
    [DscProperty(Key)]
    [System.String]
    $IpAddress

    [DscProperty(Key)]
    [System.String]
    $Name

    hidden [System.String] $recordHostName

    [DnsRecordPtr] Get()
    {
        # Ensure $recordHostName is set
        $this.recordHostName = $this.getRecordHostName($this.IpAddress)

        return ([DnsRecordBase] $this).Get()
    }

    [void] Set()
    {
        # Ensure $recordHostName is set
        $this.recordHostName = $this.getRecordHostName($this.IpAddress)

        ([DnsRecordBase] $this).Set()
    }

    [System.Boolean] Test()
    {
        # Ensure $recordHostName is set
        $this.recordHostName = $this.getRecordHostName($this.IpAddress)

        return ([DnsRecordBase] $this).Test()
    }

    hidden [Microsoft.Management.Infrastructure.CimInstance] GetResourceRecord()
    {
        Write-Verbose -Message ($this.localizedData.GettingDnsRecordMessage -f 'Ptr', $this.ZoneName, $this.ZoneScope, $this.DnsServer)

        $dnsParameters = @{
            ZoneName     = $this.ZoneName
            ComputerName = $this.DnsServer
            RRType       = 'PTR'
            Name         = $this.recordHostName
        }

        $record = Get-DnsServerResourceRecord @dnsParameters -ErrorAction SilentlyContinue | Where-Object -FilterScript {
            $_.RecordData.PtrDomainName -eq "$($this.Name)."
        }

        return $record
    }

    hidden [DnsRecordPtr] NewDscResourceObjectFromRecord([Microsoft.Management.Infrastructure.CimInstance] $record)
    {
        $dscResourceObject = [DnsRecordPtr] @{
            ZoneName   = $this.ZoneName
            IpAddress  = $this.IpAddress
            Name       = $this.Name
            TimeToLive = $record.TimeToLive.ToString()
            DnsServer  = $this.DnsServer
            Ensure     = 'Present'
        }

        return $dscResourceObject
    }

    hidden [void] AddResourceRecord()
    {
        $dnsParameters = @{
            ZoneName      = $this.ZoneName
            ComputerName  = $this.DnsServer
            PTR           = $true
            Name          = $this.recordHostName
            PtrDomainName = $this.Name
        }

        if ($null -ne $this.TimeToLive)
        {
            $dnsParameters.Add('TimeToLive', $this.TimeToLive)
        }

        Write-Verbose -Message ($this.localizedData.CreatingDnsRecordMessage -f 'PTR', $this.ZoneName, $this.ZoneScope, $this.DnsServer)

        Add-DnsServerResourceRecord @dnsParameters
    }

    hidden [void] ModifyResourceRecord([Microsoft.Management.Infrastructure.CimInstance] $existingRecord, [System.Collections.Hashtable[]] $propertiesNotInDesiredState)
    {
        $dnsParameters = @{
            ZoneName     = $this.ZoneName
            ComputerName = $this.DnsServer
        }

        # Copy the existing record and modify values as appropriate
        $newRecord = [Microsoft.Management.Infrastructure.CimInstance]::new($existingRecord)

        foreach ($propertyToChange in $propertiesNotInDesiredState)
        {
            switch ($propertyToChange.Property)
            {
                # Key parameters will never be affected, so only include Mandatory and Optional values in the switch statement
                'TimeToLive'
                {
                    $newRecord.TimeToLive = [System.TimeSpan] $propertyToChange.ExpectedValue
                }

            }
        }

        Set-DnsServerResourceRecord @dnsParameters -OldInputObject $existingRecord -NewInputObject $newRecord -Verbose
    }

    # Take a compressed IPv6 string (i.e.: fd00::1) and expand it out to the full notation (i.e.: fd00:0000:0000:0000:0000:0000:0000:0001)
    hidden [System.String] expandIPv6String($string)
    {
        # Split the string on the colons
        $segments = [System.Collections.ArrayList]::new(($string -split ':'))

        # Determine how many segments need to be added to reach the 8 required
        $blankSegmentCount = 8 - $segments.count

        # Insert missing segments
        for ($i = 0; $i -lt $blankSegmentCount; $i++)
        {
            $segments.Insert(1, '0000')
        }

        # Pad out all segments with leading zeros
        $paddedSegments = $segments | ForEach-Object {
            $_.PadLeft(4, '0')
        }
        return ($paddedSegments -join ':')
    }

    # Translate the IP address to the reverse notation used by the DNS server
    hidden [System.String] getReverseNotation([System.Net.IpAddress] $ipAddressObj)
    {
        $significantData = [System.Collections.ArrayList]::New()

        switch ($ipAddressObj.AddressFamily)
        {
            'InterNetwork'
            {
                $significantData.AddRange(($ipAddressObj.IPAddressToString -split '\.'))
                break
            }

            'InterNetworkV6'
            {
                # Get the hex values into an ArrayList
                $significantData.AddRange(($this.expandIPv6String($ipAddressObj.IPAddressToString) -replace ':', '' -split ''))
                break
            }
        }

        $significantData.Reverse()

        # The reverse lookup notation puts a '.' between each hex value
        return ($significantData -join '.').Trim('.')
    }

    # Determine the record host name
    hidden [System.String] getRecordHostName([System.Net.IpAddress] $ipAddressObj)
    {
        $reverseLookupAddressComponent = ""

        switch ($ipAddressObj.AddressFamily)
        {
            'InterNetwork'
            {
                if (-not $this.ZoneName.ToLower().EndsWith('.in-addr.arpa'))
                {
                    throw ($this.localizedData.NotAnIPv4Zone -f $this.ZoneName)
                }
                $reverseLookupAddressComponent = $this.ZoneName.Replace('.in-addr.arpa', '')
                break
            }

            'InterNetworkV6'
            {
                if (-not $this.ZoneName.ToLower().EndsWith('.ip6.arpa'))
                {
                    throw ($this.localizedData.NotAnIPv6Zone -f $this.ZoneName)
                }
                $reverseLookupAddressComponent = $this.ZoneName.Replace('.ip6.arpa', '')
                break
            }
        }

        $reverseNotation = $this.getReverseNotation($ipAddressObj)

        # Check to make sure that the ip address actually belongs in this zone
        if ($reverseNotation -notmatch "$($reverseLookupAddressComponent)`$")
        {
            throw $this.localizedData.WrongZone -f $ipAddressObj.IPAddressToString, $this.ZoneName
        }

        # Strip the zone name from the reversed IP using a regular expression
        $ptrRecordHostName = $reverseNotation -replace "\.$([System.Text.RegularExpressions.Regex]::Escape($reverseLookupAddressComponent))`$", ""

        return $ptrRecordHostName
    }
}
#EndRegion './Classes/002.DnsRecordPtr.ps1' 224
#Region './Classes/003.DnsRecordA.ps1' 0
<#
    .SYNOPSIS
        The DnsRecordA DSC resource manages A DNS records against a specific zone on a Domain Name System (DNS) server.

    .DESCRIPTION
        The DnsRecordA DSC resource manages A DNS records against a specific zone on a Domain Name System (DNS) server.

    .PARAMETER Name
        Specifies the name of a DNS server resource record object. (Key Parameter)

    .PARAMETER IPv4Address
       Specifies the IPv4 address of a host. (Key Parameter)
#>

[DscResource()]
class DnsRecordA : DnsRecordBase
{
    [DscProperty(Key)]
    [System.String]
    $Name

    [DscProperty(Key)]
    [System.String]
    $IPv4Address

    [DnsRecordA] Get()
    {
        return ([DnsRecordBase] $this).Get()
    }

    [void] Set()
    {
        ([DnsRecordBase] $this).Set()
    }

    [System.Boolean] Test()
    {
        return ([DnsRecordBase] $this).Test()
    }

    hidden [Microsoft.Management.Infrastructure.CimInstance] GetResourceRecord()
    {
        Write-Verbose -Message ($this.localizedData.GettingDnsRecordMessage -f 'A', $this.ZoneName, $this.ZoneScope, $this.DnsServer)

        $dnsParameters = @{
            ZoneName     = $this.ZoneName
            ComputerName = $this.DnsServer
            RRType       = 'A'
            Name         = $this.Name
        }

        if ($this.isScoped)
        {
            $dnsParameters['ZoneScope'] = $this.ZoneScope
        }

        $record = Get-DnsServerResourceRecord @dnsParameters -ErrorAction SilentlyContinue | Where-Object {
            $_.RecordData.IPv4Address -eq $this.IPv4Address
        }

        return $record
    }

    hidden [DnsRecordA] NewDscResourceObjectFromRecord([Microsoft.Management.Infrastructure.CimInstance] $record)
    {
        $dscResourceObject = [DnsRecordA] @{
            ZoneName    = $this.ZoneName
            Name        = $this.Name
            IPv4Address = $this.IPv4Address
            TimeToLive  = $record.TimeToLive.ToString()
            DnsServer   = $this.DnsServer
            Ensure      = 'Present'
        }

        return $dscResourceObject
    }

    hidden [void] AddResourceRecord()
    {
        $dnsParameters = @{
            ZoneName     = $this.ZoneName
            ComputerName = $this.DnsServer
            A            = $true
            Name         = $this.Name
            IPv4Address  = $this.IPv4Address
        }

        if ($this.isScoped)
        {
            $dnsParameters['ZoneScope'] = $this.ZoneScope
        }

        if ($null -ne $this.TimeToLive)
        {
            $dnsParameters.Add('TimeToLive', $this.TimeToLive)
        }

        Write-Verbose -Message ($this.localizedData.CreatingDnsRecordMessage -f 'A', $this.ZoneName, $this.ZoneScope, $this.DnsServer)

        Add-DnsServerResourceRecord @dnsParameters
    }

    hidden [void] ModifyResourceRecord([Microsoft.Management.Infrastructure.CimInstance] $existingRecord, [System.Collections.Hashtable[]] $propertiesNotInDesiredState)
    {
        $dnsParameters = @{
            ZoneName     = $this.ZoneName
            ComputerName = $this.DnsServer
        }

        if ($this.isScoped)
        {
            $dnsParameters['ZoneScope'] = $this.ZoneScope
        }

        # Copy the existing record and modify values as appropriate
        $newRecord = [Microsoft.Management.Infrastructure.CimInstance]::new($existingRecord)

        foreach ($propertyToChange in $propertiesNotInDesiredState)
        {
            switch ($propertyToChange.Property)
            {
                # Key parameters will never be affected, so only include Mandatory and Optional values in the switch statement
                'TimeToLive'
                {
                    $newRecord.TimeToLive = [System.TimeSpan] $propertyToChange.ExpectedValue
                }

            }
        }

        Set-DnsServerResourceRecord @dnsParameters -OldInputObject $existingRecord -NewInputObject $newRecord -Verbose
    }
}
#EndRegion './Classes/003.DnsRecordA.ps1' 134
#Region './Classes/003.DnsRecordAaaa.ps1' 0
<#
    .SYNOPSIS
        The DnsRecordAaaa DSC resource manages AAAA DNS records against a specific zone on a Domain Name System (DNS) server.

    .DESCRIPTION
        The DnsRecordAaaa DSC resource manages AAAA DNS records against a specific zone on a Domain Name System (DNS) server.

    .PARAMETER Name
        Specifies the name of a DNS server resource record object. (Key Parameter)

    .PARAMETER IPv6Address
       Specifies the IPv6 address of a host. (Key Parameter)
#>

[DscResource()]
class DnsRecordAaaa : DnsRecordBase
{
    [DscProperty(Key)]
    [System.String]
    $Name

    [DscProperty(Key)]
    [System.String]
    $IPv6Address

    [DnsRecordAaaa] Get()
    {
        return ([DnsRecordBase] $this).Get()
    }

    [void] Set()
    {
        ([DnsRecordBase] $this).Set()
    }

    [System.Boolean] Test()
    {
        return ([DnsRecordBase] $this).Test()
    }

    hidden [Microsoft.Management.Infrastructure.CimInstance] GetResourceRecord()
    {
        Write-Verbose -Message ($this.localizedData.GettingDnsRecordMessage -f 'Aaaa', $this.ZoneName, $this.ZoneScope, $this.DnsServer)

        $dnsParameters = @{
            ZoneName     = $this.ZoneName
            ComputerName = $this.DnsServer
            RRType       = 'AAAA'
            Name         = $this.Name
        }

        if ($this.isScoped)
        {
            $dnsParameters['ZoneScope'] = $this.ZoneScope
        }

        $record = Get-DnsServerResourceRecord @dnsParameters -ErrorAction SilentlyContinue | Where-Object -FilterScript {
                $_.RecordData.IPv6Address -eq $this.IPv6Address
        }

        return $record
    }

    hidden [DnsRecordAaaa] NewDscResourceObjectFromRecord([Microsoft.Management.Infrastructure.CimInstance] $record)
    {
        $dscResourceObject = [DnsRecordAaaa] @{
            ZoneName    = $this.ZoneName
            Name        = $this.Name
            IPv6Address = $this.IPv6Address
            TimeToLive  = $record.TimeToLive.ToString()
            DnsServer   = $this.DnsServer
            Ensure      = 'Present'
        }

        return $dscResourceObject
    }

    hidden [void] AddResourceRecord()
    {
        $dnsParameters = @{
            ZoneName     = $this.ZoneName
            ComputerName = $this.DnsServer
            AAAA         = $true
            Name         = $this.name
            IPv6Address  = $this.IPv6Address
        }

        if ($this.isScoped)
        {
            $dnsParameters['ZoneScope'] = $this.ZoneScope
        }

        if ($null -ne $this.TimeToLive)
        {
            $dnsParameters.Add('TimeToLive', $this.TimeToLive)
        }

        Write-Verbose -Message ($this.localizedData.CreatingDnsRecordMessage -f 'AAAA', $this.ZoneName, $this.ZoneScope, $this.DnsServer)

        Add-DnsServerResourceRecord @dnsParameters
    }

    hidden [void] ModifyResourceRecord([Microsoft.Management.Infrastructure.CimInstance] $existingRecord, [System.Collections.Hashtable[]] $propertiesNotInDesiredState)
    {
        $dnsParameters = @{
            ZoneName     = $this.ZoneName
            ComputerName = $this.DnsServer
        }

        if ($this.isScoped)
        {
            $dnsParameters['ZoneScope'] = $this.ZoneScope
        }

        # Copy the existing record and modify values as appropriate
        $newRecord = [Microsoft.Management.Infrastructure.CimInstance]::new($existingRecord)

        foreach ($propertyToChange in $propertiesNotInDesiredState)
        {
            switch ($propertyToChange.Property)
            {
                # Key parameters will never be affected, so only include Mandatory and Optional values in the switch statement
                'TimeToLive'
                {
                    $newRecord.TimeToLive = [System.TimeSpan] $propertyToChange.ExpectedValue
                }

            }
        }

        Set-DnsServerResourceRecord @dnsParameters -OldInputObject $existingRecord -NewInputObject $newRecord -Verbose
    }
}
#EndRegion './Classes/003.DnsRecordAaaa.ps1' 134
#Region './Classes/003.DnsRecordCnameScoped.ps1' 0
<#
    .SYNOPSIS
        The DnsRecordCnameScoped DSC resource manages CNAME DNS records against a specific zone and zone scope on a Domain Name System (DNS) server.

    .DESCRIPTION
        The DnsRecordCnameScoped DSC resource manages CNAME DNS records against a specific zone and zone scope on a Domain Name System (DNS) server.

    .PARAMETER ZoneScope
        Specifies the name of a zone scope. (Key Parameter)
#>

[DscResource()]
class DnsRecordCnameScoped : DnsRecordCname
{
    [DscProperty(Key)]
    [System.String]
    $ZoneScope

    [DnsRecordCnameScoped] Get()
    {
        return ([DnsRecordBase] $this).Get()
    }

    [void] Set()
    {
        ([DnsRecordBase] $this).Set()
    }

    [System.Boolean] Test()
    {
        return ([DnsRecordBase] $this).Test()
    }

    hidden [Microsoft.Management.Infrastructure.CimInstance] GetResourceRecord()
    {
        return ([DnsRecordCname] $this).GetResourceRecord()
    }

    hidden [DnsRecordCnameScoped] NewDscResourceObjectFromRecord([Microsoft.Management.Infrastructure.CimInstance] $record)
    {
        $dscResourceObject = [DnsRecordCnameScoped] @{
            ZoneName      = $this.ZoneName
            ZoneScope     = $this.ZoneScope
            Name          = $this.Name
            HostNameAlias = $this.HostNameAlias
            TimeToLive    = $record.TimeToLive.ToString()
            DnsServer     = $this.DnsServer
            Ensure        = 'Present'
        }

        return $dscResourceObject
    }

    hidden [void] AddResourceRecord()
    {
        ([DnsRecordCname] $this).AddResourceRecord()
    }

    hidden [void] ModifyResourceRecord([Microsoft.Management.Infrastructure.CimInstance] $existingRecord, [System.Collections.Hashtable[]] $propertiesNotInDesiredState)
    {
        ([DnsRecordCname] $this).ModifyResourceRecord($existingRecord, $propertiesNotInDesiredState)
    }
}
#EndRegion './Classes/003.DnsRecordCnameScoped.ps1' 64
#Region './Classes/003.DnsRecordMx.ps1' 0
<#
    .SYNOPSIS
        The DnsRecordMx DSC resource manages MX DNS records against a specific zone on a Domain Name System (DNS) server.

    .DESCRIPTION
        The DnsRecordMx DSC resource manages MX DNS records against a specific zone on a Domain Name System (DNS) server.

    .PARAMETER EmailDomain
       Everything after the '@' in the email addresses supported by this mail exchanger. It must be a subdomain the zone or the zone itself. To specify all subdomains, use the '*' character (i.e.: *.contoso.com). (Key Parameter)

    .PARAMETER MailExchange
       FQDN of the server handling email for the specified email domain. When setting the value, this FQDN must resolve to an IP address and cannot reference a CNAME record. (Key Parameter)

    .PARAMETER Priority
       Specifies the priority for this MX record among other MX records that belong to the same email domain, where a lower value has a higher priority. (Mandatory Parameter)
#>

[DscResource()]
class DnsRecordMx : DnsRecordBase
{
    [DscProperty(Key)]
    [System.String]
    $EmailDomain

    [DscProperty(Key)]
    [System.String]
    $MailExchange

    [DscProperty(Mandatory)]
    [System.UInt16]
    $Priority

    hidden [System.String] $recordName

    [DnsRecordMx] Get()
    {
        $this.recordName = $this.getRecordName()
        return ([DnsRecordBase] $this).Get()
    }

    [void] Set()
    {
        $this.recordName = $this.getRecordName()
        ([DnsRecordBase] $this).Set()
    }

    [System.Boolean] Test()
    {
        $this.recordName = $this.getRecordName()
        return ([DnsRecordBase] $this).Test()
    }

    [System.String] getRecordName()
    {
        $aRecordName = $null
        $regexMatch = $this.EmailDomain | Select-String -Pattern "^((.*?)\.){0,1}$($this.ZoneName)`$"
        if ($null -eq $regexMatch)
        {
            throw ($this.localizedData.DomainZoneMismatch -f $this.EmailDomain, $this.ZoneName)
        }
        else
        {
            # Match group 2 contains the value in which we are interested.
            $aRecordName = $regexMatch.Matches.Groups[2].Value
            if ($aRecordName -eq '')
            {
                $aRecordName = '.'
            }
        }
        return $aRecordName
    }

    hidden [Microsoft.Management.Infrastructure.CimInstance] GetResourceRecord()
    {
        Write-Verbose -Message ($this.localizedData.GettingDnsRecordMessage -f 'Mx', $this.ZoneName, $this.ZoneScope, $this.DnsServer)

        $dnsParameters = @{
            ZoneName     = $this.ZoneName
            ComputerName = $this.DnsServer
            RRType       = 'MX'
        }

        if ($this.isScoped)
        {
            $dnsParameters['ZoneScope'] = $this.ZoneScope
        }

        $record = Get-DnsServerResourceRecord @dnsParameters -ErrorAction SilentlyContinue | Where-Object -FilterScript {
            $translatedRecordName = $this.getRecordName()
            if ($translatedRecordName -eq '.')
            {
                $translatedRecordName = '@'
            }
            $_.HostName -eq $translatedRecordName -and
            $_.RecordData.MailExchange -eq "$($this.MailExchange)."
        }

        <#
            It is technically possible, outside of this resource to have more than one record with the same target, but
            different priorities. So, although the idea of doing so is nonsensical, we have to ensure we are selecting
            only one record in this method. It doesn't matter which one.
        #>
        return $record | Select-Object -First 1
    }

    hidden [DnsRecordMx] NewDscResourceObjectFromRecord([Microsoft.Management.Infrastructure.CimInstance] $record)
    {
        $dscResourceObject = [DnsRecordMx] @{
            ZoneName     = $this.ZoneName
            EmailDomain  = $this.EmailDomain
            MailExchange = $this.MailExchange
            Priority     = $record.RecordData.Preference
            TimeToLive   = $record.TimeToLive.ToString()
            DnsServer    = $this.DnsServer
            Ensure       = 'Present'
        }

        return $dscResourceObject
    }

    hidden [void] AddResourceRecord()
    {
        $dnsParameters = @{
            ZoneName     = $this.ZoneName
            ComputerName = $this.DnsServer
            MX           = $true
            Name         = $this.getRecordName()
            MailExchange = $this.MailExchange
            Preference   = $this.Priority
        }

        if ($this.isScoped)
        {
            $dnsParameters['ZoneScope'] = $this.ZoneScope
        }

        if ($null -ne $this.TimeToLive)
        {
            $dnsParameters.Add('TimeToLive', $this.TimeToLive)
        }

        Write-Verbose -Message ($this.localizedData.CreatingDnsRecordMessage -f 'MX', $this.ZoneName, $this.ZoneScope, $this.DnsServer)

        Add-DnsServerResourceRecord @dnsParameters
    }

    hidden [void] ModifyResourceRecord([Microsoft.Management.Infrastructure.CimInstance] $existingRecord, [System.Collections.Hashtable[]] $propertiesNotInDesiredState)
    {
        $dnsParameters = @{
            ZoneName     = $this.ZoneName
            ComputerName = $this.DnsServer
        }

        if ($this.isScoped)
        {
            $dnsParameters['ZoneScope'] = $this.ZoneScope
        }

        # Copy the existing record and modify values as appropriate
        $newRecord = [Microsoft.Management.Infrastructure.CimInstance]::new($existingRecord)

        foreach ($propertyToChange in $propertiesNotInDesiredState)
        {
            switch ($propertyToChange.Property)
            {
                # Key parameters will never be affected, so only include Mandatory and Optional values in the switch statement

                'Priority'
                {
                    $newRecord.RecordData.Preference = $propertyToChange.ExpectedValue
                }

                'TimeToLive'
                {
                    $newRecord.TimeToLive = [System.TimeSpan] $propertyToChange.ExpectedValue
                }

            }
        }

        Set-DnsServerResourceRecord @dnsParameters -OldInputObject $existingRecord -NewInputObject $newRecord -Verbose
    }
}
#EndRegion './Classes/003.DnsRecordMx.ps1' 184
#Region './Classes/003.DnsRecordSrv.ps1' 0
<#
    .SYNOPSIS
        The DnsRecordSrv DSC resource manages SRV DNS records against a specific zone on a Domain Name System (DNS) server.

    .DESCRIPTION
        The DnsRecordSrv DSC resource manages SRV DNS records against a specific zone on a Domain Name System (DNS) server.

    .PARAMETER SymbolicName
        Service name for the SRV record. eg: xmpp, ldap, etc. (Key Parameter)

    .PARAMETER Protocol
        Service transmission protocol ('TCP' or 'UDP') (Key Parameter)

    .PARAMETER Port
        The TCP or UDP port on which the service is found (Key Parameter)

    .PARAMETER Target
        Specifies the Target Hostname or IP Address. (Key Parameter)

    .PARAMETER Priority
        Specifies the Priority value of the SRV record. (Mandatory Parameter)

    .PARAMETER Weight
        Specifies the weight of the SRV record. (Mandatory Parameter)
#>

[DscResource()]
class DnsRecordSrv : DnsRecordBase
{
    [DscProperty(Key)]
    [System.String]
    $SymbolicName

    [DscProperty(Key)]
    [ValidateSet('TCP', 'UDP')]
    [System.String]
    $Protocol

    [DscProperty(Key)]
    [ValidateRange(1, 65535)]
    [System.UInt16]
    $Port

    [DscProperty(Key)]
    [System.String]
    $Target

    [DscProperty(Mandatory)]
    [System.UInt16]
    $Priority

    [DscProperty(Mandatory)]
    [System.UInt16]
    $Weight

    hidden [System.String] getRecordHostName()
    {
        return $this.getRecordHostName($this.SymbolicName, $this.Protocol)
    }

    hidden [System.String] getRecordHostName($aSymbolicName, $aProtocol)
    {
        return "_$($aSymbolicName)._$($aProtocol)".ToLower()
    }

    [DnsRecordSrv] Get()
    {
        return ([DnsRecordBase] $this).Get()
    }

    [void] Set()
    {
        ([DnsRecordBase] $this).Set()
    }

    [System.Boolean] Test()
    {
        return ([DnsRecordBase] $this).Test()
    }

    hidden [Microsoft.Management.Infrastructure.CimInstance] GetResourceRecord()
    {
        $recordHostName = $this.getRecordHostName()

        Write-Verbose -Message ($this.localizedData.GettingDnsRecordMessage -f $recordHostName, $this.target, 'SRV', $this.ZoneName, $this.ZoneScope, $this.DnsServer)

        $dnsParameters = @{
            Name         = $recordHostName
            ZoneName     = $this.ZoneName
            ComputerName = $this.DnsServer
            RRType       = 'SRV'
        }

        if ($this.isScoped)
        {
            $dnsParameters['ZoneScope'] = $this.ZoneScope
        }

        $record = Get-DnsServerResourceRecord @dnsParameters -ErrorAction SilentlyContinue | Where-Object -FilterScript {
            $_.HostName -eq $recordHostName -and
            $_.RecordData.Port -eq $this.Port -and
            $_.RecordData.DomainName -eq "$($this.Target)."
        }

        return $record
    }

    hidden [DnsRecordSrv] NewDscResourceObjectFromRecord([Microsoft.Management.Infrastructure.CimInstance] $record)
    {
        $dscResourceObject = [DnsRecordSrv] @{
            ZoneName     = $this.ZoneName
            SymbolicName = $this.SymbolicName
            Protocol     = $this.Protocol.ToLower()
            Port         = $this.Port
            Target       = ($record.RecordData.DomainName).TrimEnd('.')
            Priority     = $record.RecordData.Priority
            Weight       = $record.RecordData.Weight
            TimeToLive   = $record.TimeToLive.ToString()
            DnsServer    = $this.DnsServer
            Ensure       = 'Present'
        }

        return $dscResourceObject
    }

    hidden [void] AddResourceRecord()
    {
        $recordHostName = $this.getRecordHostName()

        $dnsParameters = @{
            ZoneName     = $this.ZoneName
            ComputerName = $this.DnsServer
            Name         = $recordHostName
            Srv          = $true
            DomainName   = $this.Target
            Port         = $this.Port
            Priority     = $this.Priority
            Weight       = $this.Weight
        }

        if ($this.isScoped)
        {
            $dnsParameters['ZoneScope'] = $this.ZoneScope
        }

        if ($null -ne $this.TimeToLive)
        {
            $dnsParameters.Add('TimeToLive', $this.TimeToLive)
        }

        Write-Verbose -Message ($this.localizedData.CreatingDnsRecordMessage -f 'SRV', $recordHostName, $this.Target, $this.ZoneName, $this.ZoneScope, $this.DnsServer)

        Add-DnsServerResourceRecord @dnsParameters
    }

    hidden [void] ModifyResourceRecord([Microsoft.Management.Infrastructure.CimInstance] $existingRecord, [System.Collections.Hashtable[]] $propertiesNotInDesiredState)
    {
        $recordHostName = $this.getRecordHostName()

        $dnsParameters = @{
            ZoneName     = $this.ZoneName
            ComputerName = $this.DnsServer
        }

        if ($this.isScoped)
        {
            $dnsParameters['ZoneScope'] = $this.ZoneScope
        }

        # Copy the existing record and modify values as appropriate
        $newRecord = [Microsoft.Management.Infrastructure.CimInstance]::new($existingRecord)

        foreach ($propertyToChange in $propertiesNotInDesiredState)
        {
            switch ($propertyToChange.Property)
            {
                # Key parameters will never be affected, so only include Mandatory and Optional values in the switch statement
                'Priority'
                {
                    $newRecord.RecordData.Priority = $propertyToChange.ExpectedValue
                }

                'Weight'
                {
                    $newRecord.RecordData.Weight = $propertyToChange.ExpectedValue
                }

                'TimeToLive'
                {
                    $newRecord.TimeToLive = [System.TimeSpan] $propertyToChange.ExpectedValue
                }

            }
        }

        Set-DnsServerResourceRecord @dnsParameters -OldInputObject $existingRecord -NewInputObject $newRecord -Verbose
    }
}
#EndRegion './Classes/003.DnsRecordSrv.ps1' 199
#Region './Classes/003.DnsServerEDns.ps1' 0
<#
    .SYNOPSIS
        The DnsServerEDns DSC resource manages _extension mechanisms for DNS (EDNS)_
        on a Microsoft Domain Name System (DNS) server.

    .DESCRIPTION
        The DnsServerEDns DSC resource manages _extension mechanisms for DNS (EDNS)_
        on a Microsoft Domain Name System (DNS) server.

    .PARAMETER DnsServer
        The host name of the Domain Name System (DNS) server, or use `'localhost'`
        for the current node.

    .PARAMETER CacheTimeout
        Specifies the number of seconds that the DNS server caches EDNS information.

    .PARAMETER EnableProbes
        Specifies whether to enable the server to probe other servers to determine
        whether they support EDNS.

    .PARAMETER EnableReception
        Specifies whether the DNS server accepts queries that contain an EDNS record.
#>

[DscResource()]
class DnsServerEDns : ResourceBase
{
    [DscProperty(Key)]
    [System.String]
    $DnsServer

    [DscProperty()]
    [System.String]
    $CacheTimeout

    [DscProperty()]
    [Nullable[System.Boolean]]
    $EnableProbes

    [DscProperty()]
    [Nullable[System.Boolean]]
    $EnableReception

    [DnsServerEDns] Get()
    {
        Write-Verbose -Message ($this.localizedData.GetCurrentState -f $this.DnsServer)

        $getDnsServerEDnsParameters = @{}

        if ($this.DnsServer -ne 'localhost')
        {
            $getDnsServerEDnsParameters['ComputerName'] = $this.DnsServer
        }

        $getDnsServerEDnsResult = Get-DnsServerEDns @getDnsServerEDnsParameters

        # Call the base method to return the properties.
        return ([ResourceBase] $this).Get($getDnsServerEDnsResult)
    }

    [void] Set()
    {
        $this.AssertProperties()

        Write-Verbose -Message ($this.localizedData.SetDesiredState -f $this.DnsServer)

        # Call the base method to get enforced properties that are not in desired state.
        $propertiesNotInDesiredState = $this.Compare()

        if ($propertiesNotInDesiredState)
        {
            $setDnsServerEDnsParameters = $this.GetDesiredStateForSplatting($propertiesNotInDesiredState)

            $setDnsServerEDnsParameters.Keys | ForEach-Object -Process {
                Write-Verbose -Message ($this.localizedData.SetProperty -f $_, $setDnsServerEDnsParameters.$_)
            }

            if ($this.DnsServer -ne 'localhost')
            {
                $setDnsServerEDnsParameters['ComputerName'] = $this.DnsServer
            }

            Set-DnsServerEDns @setDnsServerEDnsParameters
        }
        else
        {
            Write-Verbose -Message $this.localizedData.NoPropertiesToSet
        }
    }

    [System.Boolean] Test()
    {
        $this.AssertProperties()

        Write-Verbose -Message ($this.localizedData.TestDesiredState -f $this.DnsServer)

        # Call the base method to test all of the properties that should be enforced.
        $isInDesiredState = ([ResourceBase] $this).Test()

        if ($isInDesiredState)
        {
            Write-Verbose -Message ($this.localizedData.InDesiredState -f $this.DnsServer)
        }
        else
        {
            Write-Verbose -Message ($this.localizedData.NotInDesiredState -f $this.DnsServer)
        }

        return $isInDesiredState
    }

    hidden [void] AssertProperties()
    {
        @(
            'CacheTimeout'
        ) | ForEach-Object -Process {
            $valueToConvert = $this.$_

            # Only evaluate properties that have a value.
            if ($null -ne $valueToConvert)
            {
                Assert-TimeSpan -PropertyName $_ -Value $valueToConvert -Minimum '0.00:00:00'
            }
        }
    }
}
#EndRegion './Classes/003.DnsServerEDns.ps1' 127
#Region './Classes/003.DnsServerScavenging.ps1' 0
<#
    .SYNOPSIS
        The DnsServerScavenging DSC resource manages scavenging on a Microsoft
        Domain Name System (DNS) server.

    .DESCRIPTION
        The DnsServerScavenging DSC resource manages scavenging on a Microsoft
        Domain Name System (DNS) server.

    .PARAMETER DnsServer
        The host name of the Domain Name System (DNS) server, or use 'localhost'
        for the current node.

    .PARAMETER ScavengingState
        Specifies whether to Enable automatic scavenging of stale records.
        `ScavengingState` determines whether the DNS scavenging feature is enabled
        by default on newly created zones.

    .PARAMETER ScavengingInterval
        Specifies a length of time as a value that can be converted to a `[TimeSpan]`
        object. `ScavengingInterval` determines whether the scavenging feature for
        the DNS server is enabled and sets the number of hours between scavenging
        cycles. The value `0` disables scavenging for the DNS server. A setting
        greater than `0` enables scavenging for the server and sets the number of
        days, hours, minutes, and seconds (formatted as dd.hh:mm:ss) between
        scavenging cycles. The minimum value is 0. The maximum value is 365.00:00:00
        (1 year).

    .PARAMETER RefreshInterval
        Specifies the refresh interval as a value that can be converted to a `[TimeSpan]`
        object (formatted as dd.hh:mm:ss). During this interval, a DNS server can
        refresh a resource record that has a non-zero time stamp. Zones on the server
        inherit this value automatically. If a DNS server does not refresh a resource
        record that has a non-zero time stamp, the DNS server can remove that record
        during the next scavenging. Do not select a value smaller than the longest
        refresh period of a resource record registered in the zone. The minimum value
        is `0`. The maximum value is 365.00:00:00 (1 year).

    .PARAMETER NoRefreshInterval
        Specifies a length of time as a value that can be converted to a `[TimeSpan]`
        object (formatted as dd.hh:mm:ss). `NoRefreshInterval` sets a period of time
        in which no refreshes are accepted for dynamically updated records. Zones on
        the server inherit this value automatically. This value is the interval between
        the last update of a timestamp for a record and the earliest time when the
        timestamp can be refreshed. The minimum value is 0. The maximum value is
        365.00:00:00 (1 year).

    .PARAMETER LastScavengeTime
        The time when the last scavenging cycle was executed.
#>

[DscResource()]
class DnsServerScavenging : ResourceBase
{
    [DscProperty(Key)]
    [System.String]
    $DnsServer

    [DscProperty()]
    [Nullable[System.Boolean]]
    $ScavengingState

    [DscProperty()]
    [System.String]
    $ScavengingInterval

    [DscProperty()]
    [System.String]
    $RefreshInterval

    [DscProperty()]
    [System.String]
    $NoRefreshInterval

    [DscProperty(NotConfigurable)]
    [Nullable[System.DateTime]]
    $LastScavengeTime

    [DnsServerScavenging] Get()
    {
        Write-Verbose -Message ($this.localizedData.GetCurrentState -f $this.DnsServer)

        $getDnsServerScavengingParameters = @{}

        if ($this.DnsServer -ne 'localhost')
        {
            $getDnsServerScavengingParameters['ComputerName'] = $this.DnsServer
        }

        $getDnsServerScavengingResult = Get-DnsServerScavenging @getDnsServerScavengingParameters

        # Call the base method to return the properties.
        return ([ResourceBase] $this).Get($getDnsServerScavengingResult)
    }

    [void] Set()
    {
        $this.AssertProperties()

        Write-Verbose -Message ($this.localizedData.SetDesiredState -f $this.DnsServer)

        # Call the base method to get enforced properties that are not in desired state.
        $propertiesNotInDesiredState = $this.Compare()

        if ($propertiesNotInDesiredState)
        {
            $setDnsServerScavengingParameters = $this.GetDesiredStateForSplatting($propertiesNotInDesiredState)

            $setDnsServerScavengingParameters.Keys | ForEach-Object -Process {
                Write-Verbose -Message ($this.localizedData.SetProperty -f $_, $setDnsServerScavengingParameters.$_)
            }

            if ($this.DnsServer -ne 'localhost')
            {
                $setDnsServerScavengingParameters['ComputerName'] = $this.DnsServer
            }

            Set-DnsServerScavenging @setDnsServerScavengingParameters
        }
        else
        {
            Write-Verbose -Message $this.localizedData.NoPropertiesToSet
        }
    }

    [System.Boolean] Test()
    {
        $this.AssertProperties()

        Write-Verbose -Message ($this.localizedData.TestDesiredState -f $this.DnsServer)

        # Call the base method to test all of the properties that should be enforced.
        $isInDesiredState = ([ResourceBase] $this).Test()

        if ($isInDesiredState)
        {
            Write-Verbose -Message ($this.localizedData.InDesiredState -f $this.DnsServer)
        }
        else
        {
            Write-Verbose -Message ($this.localizedData.NotInDesiredState -f $this.DnsServer)
        }

        return $isInDesiredState
    }

    hidden [void] AssertProperties()
    {
        @(
            'ScavengingInterval'
            'RefreshInterval'
            'NoRefreshInterval'
        ) | ForEach-Object -Process {
            $valueToConvert = $this.$_

            # Only evaluate properties that have a value.
            if ($null -ne $valueToConvert)
            {
                Assert-TimeSpan -PropertyName $_ -Value $valueToConvert -Maximum '365.00:00:00' -Minimum '0.00:00:00'
            }
        }
    }
}
#EndRegion './Classes/003.DnsServerScavenging.ps1' 164
#Region './Classes/004.DnsRecordAaaaScoped.ps1' 0
<#
    .SYNOPSIS
        The DnsRecordAaaaScoped DSC resource manages AAAA DNS records against a specific zone and zone scope on a Domain Name System (DNS) server.

    .DESCRIPTION
        The DnsRecordAaaaScoped DSC resource manages AAAA DNS records against a specific zone and zone scope on a Domain Name System (DNS) server.

    .PARAMETER ZoneScope
        Specifies the name of a zone scope. (Key Parameter)
#>

[DscResource()]
class DnsRecordAaaaScoped : DnsRecordAaaa
{
    [DscProperty(Key)]
    [System.String]
    $ZoneScope

    [DnsRecordAaaaScoped] Get()
    {
        return ([DnsRecordBase] $this).Get()
    }

    [void] Set()
    {
        ([DnsRecordBase] $this).Set()
    }

    [System.Boolean] Test()
    {
        return ([DnsRecordBase] $this).Test()
    }

    hidden [Microsoft.Management.Infrastructure.CimInstance] GetResourceRecord()
    {
        return ([DnsRecordAaaa] $this).GetResourceRecord()
    }

    hidden [DnsRecordAaaaScoped] NewDscResourceObjectFromRecord([Microsoft.Management.Infrastructure.CimInstance] $record)
    {
        $dscResourceObject = [DnsRecordAaaaScoped] @{
            ZoneName    = $this.ZoneName
            ZoneScope   = $this.ZoneScope
            Name        = $this.Name
            IPv6Address = $this.IPv6Address
            TimeToLive  = $record.TimeToLive.ToString()
            DnsServer   = $this.DnsServer
            Ensure      = 'Present'
        }

        return $dscResourceObject
    }

    hidden [void] AddResourceRecord()
    {
        ([DnsRecordAaaa] $this).AddResourceRecord()
    }

    hidden [void] ModifyResourceRecord([Microsoft.Management.Infrastructure.CimInstance] $existingRecord, [System.Collections.Hashtable[]] $propertiesNotInDesiredState)
    {
        ([DnsRecordAaaa] $this).ModifyResourceRecord($existingRecord, $propertiesNotInDesiredState)
    }
}
#EndRegion './Classes/004.DnsRecordAaaaScoped.ps1' 64
#Region './Classes/004.DnsRecordAScoped.ps1' 0
<#
    .SYNOPSIS
        The DnsRecordAScoped DSC resource manages A DNS records against a specific zone and zone scope on a Domain Name System (DNS) server.

    .DESCRIPTION
        The DnsRecordAScoped DSC resource manages A DNS records against a specific zone and zone scope on a Domain Name System (DNS) server.

    .PARAMETER ZoneScope
        Specifies the name of a zone scope. (Key Parameter)
#>

[DscResource()]
class DnsRecordAScoped : DnsRecordA
{
    [DscProperty(Key)]
    [System.String]
    $ZoneScope

    [DnsRecordAScoped] Get()
    {
        return ([DnsRecordBase] $this).Get()
    }

    [void] Set()
    {
        ([DnsRecordBase] $this).Set()
    }

    [System.Boolean] Test()
    {
        return ([DnsRecordBase] $this).Test()
    }

    hidden [Microsoft.Management.Infrastructure.CimInstance] GetResourceRecord()
    {
        return ([DnsRecordA] $this).GetResourceRecord()
    }

    hidden [DnsRecordAScoped] NewDscResourceObjectFromRecord([Microsoft.Management.Infrastructure.CimInstance] $record)
    {
        $dscResourceObject = [DnsRecordAScoped] @{
            ZoneName    = $this.ZoneName
            ZoneScope   = $this.ZoneScope
            Name        = $this.Name
            IPv4Address = $this.IPv4Address
            TimeToLive  = $record.TimeToLive.ToString()
            DnsServer   = $this.DnsServer
            Ensure      = 'Present'
        }

        return $dscResourceObject
    }

    hidden [void] AddResourceRecord()
    {
        ([DnsRecordA] $this).AddResourceRecord()
    }

    hidden [void] ModifyResourceRecord([Microsoft.Management.Infrastructure.CimInstance] $existingRecord, [System.Collections.Hashtable[]] $propertiesNotInDesiredState)
    {
        ([DnsRecordA] $this).ModifyResourceRecord($existingRecord, $propertiesNotInDesiredState)
    }
}
#EndRegion './Classes/004.DnsRecordAScoped.ps1' 64
#Region './Classes/004.DnsRecordMxScoped.ps1' 0
<#
    .SYNOPSIS
        The DnsRecordMxScoped DSC resource manages MX DNS records against a specific zone and zone scope on a Domain Name System (DNS) server.

    .DESCRIPTION
        The DnsRecordMxScoped DSC resource manages MX DNS records against a specific zone and zone scope on a Domain Name System (DNS) server.

    .PARAMETER ZoneScope
        Specifies the name of a zone scope. (Key Parameter)
#>

[DscResource()]
class DnsRecordMxScoped : DnsRecordMx
{
    [DscProperty(Key)]
    [System.String]
    $ZoneScope

    [DnsRecordMxScoped] Get()
    {
        return ([DnsRecordBase] $this).Get()
    }

    [void] Set()
    {
        ([DnsRecordBase] $this).Set()
    }

    [System.Boolean] Test()
    {
        return ([DnsRecordBase] $this).Test()
    }

    hidden [Microsoft.Management.Infrastructure.CimInstance] GetResourceRecord()
    {
        return ([DnsRecordMx] $this).GetResourceRecord()
    }

    hidden [DnsRecordMxScoped] NewDscResourceObjectFromRecord([Microsoft.Management.Infrastructure.CimInstance] $record)
    {
        $dscResourceObject = [DnsRecordMxScoped] @{
            ZoneName     = $this.ZoneName
            ZoneScope    = $this.ZoneScope
            EmailDomain  = $this.EmailDomain
            MailExchange = $this.MailExchange
            Priority     = $record.RecordData.Preference
            TimeToLive   = $record.TimeToLive.ToString()
            DnsServer    = $this.DnsServer
            Ensure       = 'Present'
        }

        return $dscResourceObject
    }

    hidden [void] AddResourceRecord()
    {
        ([DnsRecordMx] $this).AddResourceRecord()
    }

    hidden [void] ModifyResourceRecord([Microsoft.Management.Infrastructure.CimInstance] $existingRecord, [System.Collections.Hashtable[]] $propertiesNotInDesiredState)
    {
        ([DnsRecordMx] $this).ModifyResourceRecord($existingRecord, $propertiesNotInDesiredState)
    }
}
#EndRegion './Classes/004.DnsRecordMxScoped.ps1' 65
#Region './Classes/004.DnsRecordSrvScoped.ps1' 0
<#
    .SYNOPSIS
        The DnsRecordSrvScoped DSC resource manages SRV DNS records against a specific zone and zone scope on a Domain Name System (DNS) server.

    .DESCRIPTION
        The DnsRecordSrvScoped DSC resource manages SRV DNS records against a specific zone and zone scope on a Domain Name System (DNS) server.

    .PARAMETER ZoneScope
        Specifies the name of a zone scope. (Key Parameter)
#>

[DscResource()]
class DnsRecordSrvScoped : DnsRecordSrv
{
    [DscProperty(Key)]
    [System.String]
    $ZoneScope

    [DnsRecordSrvScoped] Get()
    {
        return ([DnsRecordBase] $this).Get()
    }

    [void] Set()
    {
        ([DnsRecordBase] $this).Set()
    }

    [System.Boolean] Test()
    {
        return ([DnsRecordBase] $this).Test()
    }

    hidden [Microsoft.Management.Infrastructure.CimInstance] GetResourceRecord()
    {
        return ([DnsRecordSrv] $this).GetResourceRecord()
    }

    hidden [DnsRecordSrvScoped] NewDscResourceObjectFromRecord([Microsoft.Management.Infrastructure.CimInstance] $record)
    {
        $dscResourceObject = [DnsRecordSrvScoped] @{
            ZoneName     = $this.ZoneName
            ZoneScope    = $this.ZoneScope
            SymbolicName = $this.SymbolicName
            Protocol     = $this.Protocol.ToLower()
            Port         = $this.Port
            Target       = ($record.RecordData.DomainName).TrimEnd('.')
            Priority     = $record.RecordData.Priority
            Weight       = $record.RecordData.Weight
            TimeToLive   = $record.TimeToLive.ToString()
            DnsServer    = $this.DnsServer
            Ensure       = 'Present'
        }

        return $dscResourceObject
    }

    hidden [void] AddResourceRecord()
    {
        ([DnsRecordSrv] $this).AddResourceRecord()
    }

    hidden [void] ModifyResourceRecord([Microsoft.Management.Infrastructure.CimInstance] $existingRecord, [System.Collections.Hashtable[]] $propertiesNotInDesiredState)
    {
        ([DnsRecordSrv] $this).ModifyResourceRecord($existingRecord, $propertiesNotInDesiredState)
    }
}
#EndRegion './Classes/004.DnsRecordSrvScoped.ps1' 68
#Region './Private/Assert-TimeSpan.ps1' 0
<#
    .SYNOPSIS
        Assert that the value provided can be converted to a TimeSpan object.

    .PARAMETER Value
       The time value as a string that should be converted.
#>
function Assert-TimeSpan
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.String]
        $Value,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PropertyName,

        [Parameter()]
        [System.TimeSpan]
        $Maximum,

        [Parameter()]
        [System.TimeSpan]
        $Minimum
    )

    $timeSpanObject = $Value | ConvertTo-TimeSpan

    # If the conversion fails $null is returned.
    if ($null -eq $timeSpanObject)
    {
        $errorMessage = $script:localizedData.PropertyHasWrongFormat -f $PropertyName, $Value

        New-InvalidOperationException -Message $errorMessage
    }

    if ($PSBoundParameters.ContainsKey('Maximum') -and $timeSpanObject -gt $Maximum)
    {
        $errorMessage = $script:localizedData.TimeSpanExceedMaximumValue -f $PropertyName, $timeSpanObject.ToString(), $Maximum

        New-InvalidOperationException -Message $errorMessage
    }

    if ($PSBoundParameters.ContainsKey('Minimum') -and $timeSpanObject -lt $Minimum)
    {
        $errorMessage = $script:localizedData.TimeSpanBelowMinimumValue -f $PropertyName, $timeSpanObject.ToString(), $Minimum

        New-InvalidOperationException -Message $errorMessage
    }
}
#EndRegion './Private/Assert-TimeSpan.ps1' 54
#Region './Private/ConvertTo-HashtableFromObject.ps1' 0
<#
    .SYNOPSIS
        Convert any object to hashtable

    .PARAMETER InputObject
       The object that should convert to hashtable.
#>
function ConvertTo-HashtableFromObject
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]
        $InputObject
    )

    $hashResult = @{}

    $InputObject.psobject.Properties | Foreach-Object {
        $hashResult[$_.Name] = $_.Value
    }

    return $hashResult
}
#EndRegion './Private/ConvertTo-HashtableFromObject.ps1' 27
#Region './Private/ConvertTo-TimeSpan.ps1' 0
<#
    .SYNOPSIS
        Converts a string value to a TimeSpan object.

    .PARAMETER Value
       The time value as a string that should be converted.

    .OUTPUTS
        Returns an TimeSpan object containing the converted value, or $null if
        conversion was not possible.
#>
function ConvertTo-TimeSpan
{
    [CmdletBinding()]
    [OutputType([System.TimeSpan])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.String]
        $Value
    )

    $timeSpan = New-TimeSpan

    if (-not [System.TimeSpan]::TryParse($Value, [ref] $timeSpan))
    {
        $timeSpan = $null
    }

    return $timeSpan
}
#EndRegion './Private/ConvertTo-TimeSpan.ps1' 32
