# Exports the NuGet version string as VSTS process variable "NuGetPackageVersion"
# Exports the variable also as a PowerShell output value
function Set-NuGetVersionString {
    [CmdletBinding()]
    param(
        # The full TFS build number string of the build whose output we are publishing.
        # This should be the version string produced by Set-DotNetBuildAndVersionStrings.
        [Parameter(Mandatory)]
        [string]$buildNumber,

        # If set, marks the published version as a preview version.
        # Cannot be set together with stableVersion.
        # If neither is set, marks the published version as a CB version.
        [Parameter()]
        [switch]$previewVersion,

        # If set, marks the published version as a stable version.
        # Cannot be set together with previewVersion.
        # If neither is set, marks the published version as a CB version.
        [Parameter()]
        [switch]$stableVersion,

        # Allows the version number to be resolved when using a non-default branch (with the branch name in front of the version string).
        # For NuGet packages we just trim the branch name since NuGet Gallery does not support the notion of branches - they are all mixed.
        [Parameter()]
        [switch]$allowFromBranch
    )

    # Output is the TFS process variable NuGetPackageVersion.

    if ($previewVersion -and $stableVersion) {
        Write-Error "Cannot set both previewVersion and stableVersion."
        return
    }

    # If we expect branch-specific version strings as input, we trim everything up to the first number, to get rid of any branch name prefix.
    if ($allowFromBranch) {
        $branchlessBuildNumber = $buildNumber -replace "^(.*?)(\d+\.\d+\.\d+-.*)$", '$2'

        if ($branchlessBuildNumber -ne $buildNumber) {
            Write-Host "Removed branch name from version string: $branchlessBuildNumber"
        }

        $buildNumber = $branchlessBuildNumber
    }

    # Expected input: 1.2.3-XXXXXX-YYYYYYY
    # XXXXX can be of any length but is assumed to be eternally incrementing.
    $components = $buildNumber -split "-"

    if ($components.Length -ne 3) {
        Write-Error "buildNumber did not consist of the expected 3 components."
        return
    }

    $version = $components[0]

    if ($stableVersion) {
        # All good, that's enough.
    }
    else {
        if ($previewVersion) {
            $version = $version + "-pre-"
        }
        else {
            $version = $version + "-cb-"
        }

        $version = $version + $components[1] + "-" + $components[2]
    }

    Write-Host "NuGet package version is $version"

    Write-Output $version
    Write-Host "##vso[task.setvariable variable=NuGetPackageVersion;]$version"
    Write-Host "::set-output name=nugetversionstring::$version"
}