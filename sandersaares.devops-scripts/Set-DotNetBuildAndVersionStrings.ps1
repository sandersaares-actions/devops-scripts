# Generates a version string in the following format:
# 11.22.33-123456789012-abcdef0
# The middle part is just a timestamp (yymmddhhmmss), useful for ordering builds by time.
# Returns the version string as the PowerShell output value

function Set-DotNetBuildAndVersionStrings {
    [CmdletBinding()]
    param(
        # This file must contain the AssemblyFileVersion (preferred) or AssemblyVersion attribute.
        # It is totally OK to use this script also for non-dotnet projects, all you need is the AssemblyInfo format versionstring to provide as input.
        [Parameter(Mandatory)]
        [string]$assemblyInfoPath,

        # Git commit ID.
        [Parameter(Mandatory)]
        [string]$commitId,

        # Name of the primary branch. Builds in any other branch get the branch name as a version string prefix.
        [Parameter()]
        [string]$primaryBranchName = "master"
    )

    if (!(Test-Path $assemblyInfoPath)) {
        Write-Error "AssemblyInfo file not found at $assemblyInfoPath."
    }

    if ($commitId.Length -lt 7) {
        Write-Error "The Git commit ID is too short to be a valid commit ID."
    }

    # Convert to absolute paths because .NET does not understand PowerShell relative paths.
    $assemblyInfoPath = Resolve-Path $assemblyInfoPath

    # If you are building a debug build, the concept of assigning a version and publishing it are rather dubious - emit a warning.
    if ($env:BuildConfiguration -and $env:BuildConfiguration -ne "Release") {
        Write-Warning "BuildConfiguration is not set to Release. You may want to verify whether you want to package these assets for publishing."
    }

    $assemblyInfo = [System.IO.File]::ReadAllText($assemblyInfoPath)

    # We prefer AssemblyFileVersion because for libraries in oldschool .NET Framework, there was some funny business
    # where you had to keep AssemblyVersion out of date for proper library upgrade functionality. Not relevant on Core.
    $primaryRegex = New-Object System.Text.RegularExpressions.Regex('AssemblyFileVersion(?:Attribute)?\("(.*)"\)')
    $fallbackRegex = New-Object System.Text.RegularExpressions.Regex('AssemblyVersion(?:Attribute)?\("(.*)"\)')

    $versionMatch = $primaryRegex.Matches($assemblyInfo)

    if (!$versionMatch.Success) {
        $versionMatch = $fallbackRegex.Matches($assemblyInfo)

        if (!$versionMatch.Success) {
            Write-Error "Unable to find AssemblyFileVersion or AssemblyVersion attribute."
        }
    }

    $version = $versionMatch.Groups[1].Value

    Write-Host "AssemblyInfo version is $version"

    # Shorten the commit ID. 7 characters seem to be the standard.
    $commitId = $commitId.Substring(0, 7)

    $temporalIdentifier = [DateTimeOffset]::UtcNow.ToString("yyMMddHHmmss")

    $version = "$version-$temporalIdentifier-$commitId"
    Write-Host "Version string is $version"

    # VSTS does not immediately update it, so update it manually to pass along to the next script.
    $env:BUILD_BUILDNUMBER = $version
    $version = Set-VersionStringBranchPrefix -primaryBranchName $primaryBranchName -skipBuildNumberUpdate

    Write-Output $version

    # Publish to Azure Pipelines.
    # NB! In Azure YAML pipelines, a followup pipeline (e.g. a release) does NOT pick up the updated build number!
    # Microsoft says this is by design. You may need to write the version string to a file in order to pick it up in a release again.
    Write-Host "##vso[build.updatebuildnumber]$version"

    Write-Host "Version string set!"
}