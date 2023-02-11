# This script prefixes the TFS/VSTS version string with a branch name.
# It will trigger a build number update in VSTS unless the skip switch is specified.
# A process variable "versionPrefix" will contain the added text.
# The output of the script will be the updated version string (even if no update was made).
#
# If in the primary branch, the version string is not modified (but the prefix is still emitted as empty string).

function Set-VersionStringBranchPrefix {
    [CmdletBinding()]
    param(
        # Name of the primary branch. Builds in any other branch get the branch name as a version string prefix.
        [Parameter()]
        [string]$primaryBranchName = "master",

        # If set, will not update the build number in VSTS and just write it to output. Useful when calling
        # from another script that already sets the build number, as this action is racy and should be done only once.
        #
        # The prefix variable will always be set as this script is the source of truth for the prefix.
        [Parameter()]
        [switch]$skipBuildNumberUpdate
    )

    $version = $env:BUILD_BUILDNUMBER

    if (!$version) {
        Write-Error "Unable to detect version string."
        return
    }

    if ($env:SYSTEM_PULLREQUEST_SOURCEBRANCH) {
        # This is an Azure PR build.
        $sourceRef = $env:SYSTEM_PULLREQUEST_SOURCEBRANCH
    }
    elseif ($env:GITHUB_REF) {
        # This is a GitHub build (either PR or regular)
        $sourceRef = $env:GITHUB_REF

        # If this is a PR, use the head (foreign) branch ref instead of the triggering ref.
        if ($env:GITHUB_HEAD_REF) {
            $sourceRef = $env:GITHUB_HEAD_REF
        }
        else {
            # GitHub workflows run this logic for all builds. Don't prefix if there's nothing special.
            if ($sourceRef -eq "refs/heads/$primaryBranchName") {
                $sourceRef = ""
            }
        }
    }
    elseif ($env:BUILD_SOURCEBRANCHNAME -and $env:BUILD_SOURCEBRANCHNAME -ne $primaryBranchName) {
        # This is an Azure build of a branch but is not a pull request.
        # If we are not in the primary branch, stick the branch name in front (lowercase).
        $versionPrefix = ($env:BUILD_SOURCEBRANCHNAME).ToLower()
    }
    else {
        # We can't determine any prefix to add - might just be a build from the primary branch and that's all.
    }

    if ($sourceRef) {
        # We obtained the reference to the source branch but don't have the prefix figured out yet.
        # So we cut the reference string (refs/heads/abc123) after the last / and life is easy again.
        # NB! This only leaves the branch name but loses any other information on the type of reference.
        if ($sourceRef.Contains("/")) {
            $versionPrefix = $sourceRef.Substring($sourceRef.LastIndexOf("/") + 1)
        }
        else {
            # What? Not sure - should have been a reference with the /s in it but okay, just go with it.
            $versionPrefix = $sourceRef
        }
    }

    if ($versionPrefix) {
        # Replace all '_' in $versionPrefix with '-' before combining it with $version because '_' will fail version
        # string validation. 
        $versionPrefix = $versionPrefix.Replace("_", "-");

        Write-Host "Prefixing version string with '$versionPrefix' to signal the branch."

        $version = $versionPrefix + "-" + $version

        # Export a versionstring.prefix variable so this can be easily referenced later on without string manipulation.
        # We will even include the dash in there so consumers can just stick it in there and it will work either way.
        Write-Host "##vso[task.setvariable variable=versionstring.prefix;]$versionPrefix-"

        Write-Output $version

        if (!$skipBuildNumberUpdate) {
            Write-Host "##vso[build.updatebuildnumber]$version"

            Write-Host "Version string has been updated to contain a prefix and the update has been published."
        }
        else {
            Write-Host "Version string has been updated to contain a prefix but the update has not been published."
        }
    }
    else {
        Write-Host "Will not prefix the version string with anything because we are in the primary branch."

        # Still write it to output for equivalent output.
        Write-Output $version

        Write-Host "##vso[task.setvariable variable=versionstring.prefix;]"
    }
}