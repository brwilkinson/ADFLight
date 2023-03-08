$output = 'C:\MOF'

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                    = 'localhost'
            PSDscAllowPlainTextPassword = $true
        }
    )
}

Configuration DSCR_AppxPackage_Sample
{
    Param(
        [Parameter(Mandatory)]
        [PSCredential]
        $Credential
    )

    Import-DscResource -ModuleName DSCR_AppxPackage
    Node localhost
    {
        cAppxPackage Install_Sample
        {
            Name                 = 'Mkht.SampleApp1'
            PackagePath          = "C:\Sample\App1_1.0.0.0_x86_x64.appxbundle"
            DependencyPath       = "C:\Sample\Dependencies\x64\Microsoft.NET.Native.Framework.1.7.appx"
            PsDscRunAsCredential = $Credential
        }

        cAppxPackage Uninstall_Calc
        {
            Ensure               = 'Absent'
            Name                 = 'Microsoft.WindowsCalculator'
            PsDscRunAsCredential = $Credential
        }


        cAppxProvisionedPackage Provision_Sample
        {
            PackageName           = 'Mkht.SampleApp2'
            PackagePath           = "C:\Sample\App2_1.0.0.0_x86_x64.appxbundle"
            DependencyPackagePath = "C:\Sample\Dependencies\x64\Microsoft.NET.Native.Framework.1.7.appx"
        }

        cAppxProvisionedPackage Uninstall_Alarm
        {
            Ensure      = "Absent"
            PackageName = 'Microsoft.WindowsAlarms'
        }
    }
}

DSCR_AppxPackage_Sample -OutputPath $output -ConfigurationData $ConfigurationData
Start-DscConfiguration -Path  $output -Verbose -wait
Remove-DscConfigurationDocument -stage Current, Previous, Pending -Force