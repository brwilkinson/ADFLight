DSCR_AppxPackage
====

PowerShell DSC Resource to manage UWP App Packages

## Install
You can install Resource through [PowerShell Gallery](https://www.powershellgallery.com/packages/DSCR_AppxPackage/).
```PowerShell
Install-Module -Name DSCR_AppxPackage
```
----
## DSC Resources
* **cAppxPackage**
For add / remove UWP Apps package to a user account.
This is a wrapper resource of `Add-AppxPackage` and `Remove-AppxPackage` cmdlets.

* **cAppxPackageSet**
For remove multiple UWP Apps package to a user account at once.

* **cAppxProvisionedPackage**
For add / remove UWP Apps package to a computer.
( Provisioned apps will install for each new user to logon Windows. )
This is a wrapper resource of `Add-AppxProvisionedPackage` and `Remove-AppxProvisionedPackage` cmdlets.

* **cAppxProvisionedPackageSet**
For remove multiple UWP Apps package to a computer at once.

## Properties
### cAppxPackage
+ [string] **Ensure** (Write):
    + Specifies whether or not the App should be installed or not.
    + The default value is `Present` { `Present` | `Absent` }

+ [string] **Name** (Key):
    + Specifies the Name of the App.
    + The param is used to determine the App is installed or not.
    + The Name is searched forward match.

+ [string] **PackagePath** (Write):
    + Specifies the file path of the app package. An app package has an `.appx` or `.appxbundle` extension.

+ [string[]] **DependencyPath** (Write):
    + Specifies an array of file paths of dependency packages that are required for the installation of the app package.

+ [Boolean] **Register** (Write):
    + Indicates that this resource registers an existing app package installation that has been disabled, did not register, or has become corrupted.
    + The default value is `$false`

+ [PSCredential] **PsDscRunAsCredential** (Required):
    + The credential for a user that will add /remove the App.

### cAppxPackageSet
+ [string] **Ensure** (Write):
    + You should specify `Absent`

+ [string[]] **Name** (Key):
    + Specifies Names of Apps.
    + The param is used to determine Apps are installed or not.

### cAppxProvisionedPackage
+ [string] **Ensure** (Write):
    + Specifies whether or not the App should be installed or not.
    + The default value is `Present` { `Present` | `Absent` }

+ [string] **PackageName** (Key):
    + Specifies the Name of the App.
    + The param is used to determine the App is installed or not.
    + The Name is searched forward match.

+ [string] **PackagePath** (Write):
    + Specifies the file path of the app package. An app package has an `.appx` or `.appxbundle` extension.

+ [string[]] **DependencyPackagePath** (Write):
    + Specifies an array of file paths of dependency packages that are required for the installation of the app package.

+ [string] **LicensePath** (Write):
    + Specifies the location of the `.xml` file containing your application license.

### cAppxProvisionedPackageSet
+ [string] **Ensure** (Write):
    + You should specify `Absent`

+ [string[]] **PackageName** (Key):
    + Specifies Names of Apps.
    + The param is used to determine Apps are installed or not.

----
## Examples
Please look in the [Sample](https://github.com/mkht/DSCR_AppxPackage/tree/master/Sample) directory.

----
## ChangeLog
### 0.3.0
+ Add `cAppxPackageSet` resource.
+ Add `cAppxProvisionedPackageSet` resource.

### 0.2.1
+ Initial public release.
