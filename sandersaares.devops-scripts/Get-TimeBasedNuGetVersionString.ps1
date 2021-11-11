$ErrorActionPreference = "Stop"

function Get-TimeBasedNuGetVersionString() {
    # Only compatible with Azure DevOps (for now).

    # Assumption: we are executing in pipeline whose name is the version string from Set-TimeBasedVersionString.ps1

    # The full version string is expected to be of the form [branch-name-]1111.2222.33-abcabca[-foobar]
    # The NuGet version string form will be 1111.2222.33[-foobar].
    # Number of digits may vary in some components.

    $original = $env:BUILD_BUILDNUMBER

    if (!$original) {
        Write-Error "BUILD_BUILDNUMBER environment variable not defined."
    }

    $parser = '^(?<branch>.*-)?(?<versionnumber>\d{4}\.\d{3,4}\.\d+)-.+?(?<suffix>-.+)?$'
    if (-not ($original -match $parser)) {
        Write-Error "Pipeline name $original does not match regex: $buildNumberParser"
    }

    $versionnumber = $Matches.versionnumber
    $suffix = $Matches.suffix

    $nugetVersionString = "$versionnumber$suffix"
    Write-Host "NuGet version string is $nugetVersionString"

    Write-Host "##vso[task.setvariable variable=NUGET_VERSION_STRING;]$nugetVersionString"
    return $nugetVersionString
}