$ErrorActionPreference = "Stop"

function Get-TimeBasedVersionString([string]$buildType) {
    # Only compatible with Azure DevOps (for now).

    $expectedFormat = '$(date:yyyy).$(date:Mdd).$(rev:r)'
    # We expect the name of the pipeline (in Build.BuildNumber) to be the above Azure DevOps format string.
    # To this, we suffix the Git commit ID (-abcabcabc).
    # To this, we prefix the branch name if this is not the default branch (my-branch-123-).

    # Note about incrementing build numbers: The major and minor part are date-based, so strictly increasing.
    # The revision, however, is specific to the build pipeline! Different pipelines have different revision counters.
    # As such, you could theoretically create multiple builds from different pipelines with the same version string.
    # This is not ideal, especially for NuGet which will reject duplicates we attempt to publish.
    # The solution? Suffix the version string with the build type.
    # This suffix will also serve as the NuGet "preview version" marker string (1.2.3-foobar).

    # So the final full version string will be [branch-name-]1111.2222.33-abcabca[-foobar]
    # Number of digits may vary in some components.

    $commitId = $env:BUILD_SOURCEVERSION

    $versionNumber = $env:BUILD_BUILDNUMBER

    if (!$commitId) {
        Write-Error "BUILD_SOURCEVERSION environment variable not defined."
    }

    if (!$versionNumber) {
        Write-Error "BUILD_BUILDNUMBER environment variable not defined."
    }

    ### Validate the version number.

    $buildNumberParser = '^(?<major>\d{4})\.(?<minor>\d{3,4})\.(?<revision>\d+)$'
    if (-not ($versionNumber -match $buildNumberParser)) {
        Write-Error "Pipeline name $versionNumber does not match expected Azure DevOps format string $expectedFormat"
    }

    Write-Host "Version number is $versionNumber"

    ### Add Git commit ID.

    $DESIRED_COMMIT_ID_LENGTH = 7

    if ($commitId.Length -gt $DESIRED_COMMIT_ID_LENGTH) {
        $commitId = $commitId.Substring(0, $DESIRED_COMMIT_ID_LENGTH)
    }

    ### Add branch prefix.

    $PRIMARY_BRANCH_NAMES = @("master", "main", "dev")

    if ($env:SYSTEM_PULLREQUEST_SOURCEBRANCH) {
        # This is an Azure PR build.
        $sourceRef = $env:SYSTEM_PULLREQUEST_SOURCEBRANCH

        # We obtained the reference to the source branch but don't have the prefix figured out yet.
        # So we cut the reference string (refs/heads/abc123) after the last / and life is easy again.
        if ($sourceRef.Contains("/")) {
            $branchPrefix = $sourceRef.Substring($sourceRef.LastIndexOf("/") + 1)
        }
        else {
            Write-Error "Unable to parse source reference: $sourceRef"
        }
    }
    elseif ($env:BUILD_SOURCEBRANCHNAME -and $PRIMARY_BRANCH_NAMES -notcontains $env:BUILD_SOURCEBRANCHNAME) {
        # This is an ADO build of a non-primary branch but is not a pull request.
        # Just tick the branch name in front (lowercase).
        $branchPrefix = ($env:BUILD_SOURCEBRANCHNAME).ToLower()
    }

    if ($branchPrefix) {
        $branchPrefix = $branchPrefix + "-"
    }

    ### Make the final version string.

    if ($buildType) {
        $buildTypeSuffix = "-$buildType"
    }

    $versionString = "$branchPrefix$versionNumber-$commitId$buildTypeSuffix"
    Write-Host "Version string is $versionString"

    Write-Host "##vso[task.setvariable variable=VERSION_STRING;]$versionString"
    return $versionString
}