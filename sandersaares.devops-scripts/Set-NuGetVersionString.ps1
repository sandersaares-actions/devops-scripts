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
        [switch]$stableVersion
    )

    # Output is the TFS process variable NuGetPackageVersion.

    if ($previewVersion -and $stableVersion) {
        Write-Error "Cannot set both previewVersion and stableVersion."
        return
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
}