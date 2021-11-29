$ErrorActionPreference = "Stop"

# For GitHub usage, generates a version number variable that matches the Azure DevOps pattern exepcted by Get-TimeBasedVersionString.
# Emits GitHub Actions "BUILD_BUILDNUMBER" output parameter.
# Try not to start two builds at the exact same second, to avoid version number conflicts.
function Get-VersionNumberFromCurrentTime() {
    # $(date:yyyy).$(date:Mdd).$(rev:r)
    # We do not have the "revision" feature outside Azure DevOps so we replace that with the day's seconds counter (0..86400).
    $now = Get-Date -AsUTC

    $firstPart = $now.ToString("yyyy.Mdd.")

    # For the last part, we need to get seconds from the start of the day.
    $dayElapsed = $now - $now.Date

    $lastPart = [int]$dayElapsed.TotalSeconds

    $versionNumber = $firstPart + $lastPart
    Write-Host "Generated timestamp-based version number: $versionNumber"

    # Set the environment variable, in case some next PowerShell command needs it.
    $env:BUILD_BUILDNUMBER = $versionNumber

    # Write it as a GitHub Actions output value.
    Write-Host "::set-output name=BUILD_BUILDNUMBER::$versionNumber"

    # And return the value for completeness.
    return $versionNumber
}