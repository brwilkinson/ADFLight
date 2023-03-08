Configuration cAppxPackageSet
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('Present', 'Absent')]
        [string]
        $Ensure,

        [parameter(Mandatory = $true)]
        [string[]]
        $Name
    )

    if ($Ensure -ne 'Absent') {
        Write-Error 'This resource supports only removing apps. Please specify the Ensure parameter as "Absent".'
        return
    }

    $TemplateString = @"
    cAppxPackage Resource{0}
    {{
        Ensure = '{1}'
        Name   = '{2}'
    }}
"@

    $ResourceCount = 0
    $ResourceString = ($Name | foreach {
            ($TemplateString -f $ResourceCount, $Ensure, $_)
            $ResourceCount++
        }) -join "`r`n"

    . ([ScriptBlock]::Create($ResourceString))
}