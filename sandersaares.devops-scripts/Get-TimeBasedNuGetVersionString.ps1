$ErrorActionPreference = "Stop"

function Get-TimeBasedNuGetVersionString([string]$versionString) {
    # Assumption: input is the version string from Set-TimeBasedVersionString.ps1

    # The full version string is expected to be of the form [branch-name-]1111.2222.33-abcabca[-foobar]
    # The NuGet version string form will be 1111.2222.33[-foobar].
    # Number of digits may vary in some components.

    # If versionString is not provided, try take it from Azure DevOps environment variable.
    if (!$versionString) {
        $versionString = $env:BUILD_BUILDNUMBER
    }

    if (!$versionString) {
        Write-Error "BUILD_BUILDNUMBER environment variable must be defined or an explicit version string must be passed to the function."
    }

    $parser = '^(?<branch>.*-)?(?<versionnumber>\d{4}\.\d{3,4}\.\d+)-.+?(?<suffix>-.+)?$'
    if (-not ($versionString -match $parser)) {
        Write-Error "Version string $versionString does not match Get-TimeBasedVersionString output format as checked by regex: $buildNumberParser"
    }

    $versionnumber = $Matches.versionnumber
    $suffix = $Matches.suffix

    $nugetVersionString = "$versionnumber$suffix"
    Write-Host "NuGet version string is $nugetVersionString"

    Write-Host "##vso[task.setvariable variable=NUGET_VERSION_STRING;]$nugetVersionString"
    return $nugetVersionString
}