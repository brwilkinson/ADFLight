function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [string]
        $Name
    )

    if (Test-SystemUser) {
        Write-Error ('Running in System Context is not supported')
    }

    $GetRes = @{
        Ensure         = 'Absent'
        Name           = $Name
        PackagePath    = ''
        DependencyPath = ''
        Register       = $false
    }

    $Appx = Get-AppxPackage | ? {$_.Name -like ($Name + '*')} | select -First 1
    if ($Appx) {
        $GetRes.Ensure = 'Present'
        $GetRes.PackageName = $Appx.Name
    }
    else {
        $GetRes.Ensure = 'Absent'
    }

    $GetRes
} # end of Get-TargetResource

# ////////////////////////////////////////////////////////////////////////////////////////
# ////////////////////////////////////////////////////////////////////////////////////////
function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [ValidateSet("Present", "Absent")]
        [string]
        $Ensure = 'Present',

        [parameter(Mandatory = $true)]
        [string]
        $Name,

        [parameter()]
        [string]
        $PackagePath,

        [parameter()]
        [string[]]
        $DependencyPath,

        [parameter()]
        [bool]
        $Register = $false
    )

    Write-Verbose ('Testing existence of App')

    $CurrentState = Get-TargetResource -Name $Name
    if ($Ensure -ne $CurrentState.Ensure) {
        # Not match Ensure state
        Write-Verbose ('Not match Ensure state. your desired "{0}" but current "{1}"' -f $Ensure, $CurrentState.Ensure)
        return $false
    }
    else {
        return $true
    }
} # end of Test-TargetResource

# ////////////////////////////////////////////////////////////////////////////////////////
# ////////////////////////////////////////////////////////////////////////////////////////
function Set-TargetResource {
    [CmdletBinding()]
    param
    (
        [ValidateSet("Present", "Absent")]
        [string]
        $Ensure = 'Present',

        [parameter(Mandatory = $true)]
        [string]
        $Name,

        [parameter()]
        [string]
        $PackagePath,

        [parameter()]
        [string[]]
        $DependencyPath,

        [parameter()]
        [bool]
        $Register = $false
    )

    if (Test-SystemUser) {
        Write-Error ('Running in System Context is not supported')
    }

    switch ($Ensure) {
        'Absent' {
            $Appx = Get-TargetResource -Name $Name -ErrorAction SilentlyContinue
            if ($Appx) {
                Write-Verbose ('Removing the Appx package: {0}' -f $Appx.name)
                Get-AppxPackage -Name $Appx.name | Remove-AppxPackage
            }
            else {
                Write-Warning 'The Appx package was not found.'
            }
        }
        'Present' {
            if ((-not $PackagePath) -or (-not (Test-Path $PackagePath))) {
                Write-Error ('PackagePath "{0}" not found.' -f $PackagePath)
                return
            }

            $AppxParam = @{
                Path = $PackagePath
            }

            if ($DependencyPath) {
                $AppxParam.DependencyPath = $DependencyPath
            }

            if ($Register) {
                $AppxParam.Register = $true
                $AppxParam.DisableDevelopmentMode = $true
            }

            Write-Verbose 'Installing the Appx package'
            Add-AppxPackage @AppxParam -ForceApplicationShutdown -ErrorAction Stop
        }
    }

} # end of Set-TargetResource

# ////////////////////////////////////////////////////////////////////////////////////////
# ////////////////////////////////////////////////////////////////////////////////////////

function Test-SystemUser {
    ($env:COMPUTERNAME -eq $env:USERNAME)
}

# ////////////////////////////////////////////////////////////////////////////////////////
Export-ModuleMember -Function *-TargetResource
