$ErrorActionPreference = "Stop"

function Get-TimeBasedVersionString([string]$buildType) {
    # Expected Azure DevOps version string format: $(date:yyyy).$(date:Mdd).$(rev:r)
    # If using GitHub, call Get-VersionNumberFromCurrentTime before this to set the version number to this format.

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
    # The same logic roughly follows for GitHub version numbers (timestamp based), as conflicts can occur there, as well.

    # So the final full version string will be [branch-name-]1111.2222.33-abcabca[-foobar]
    # Number of digits may vary in some components.

    # Try read commit ID for Azure DevOps.
    $commitId = $env:BUILD_SOURCEVERSION

    if (!$commitId) {
        # Maybe it is GitHub instead?
        $commitId = $env:GITHUB_SHA
    }

    if (!$commitId) {
        Write-Error "BUILD_SOURCEVERSION or GITHUB_SHA environment variable must be defined and contain a Git commit ID."
    }

    $versionNumber = $env:BUILD_BUILDNUMBER

    if (!$versionNumber) {
        Write-Error "BUILD_BUILDNUMBER environment variable must be defined."
    }

    ### Validate the version number.

    $buildNumberParser = '^(?<major>\d{4})\.(?<minor>\d{3,4})\.(?<revision>\d+)$'
    if (-not ($versionNumber -match $buildNumberParser)) {
        Write-Error "BUILD_BUILDNUMBER value '$versionNumber' does not match expected Azure DevOps format string $expectedFormat or the equivalent defined by Get-VersionNumberFromCurrentTime."
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

        # branchPrefix will be parsed from sourceRef down below
    }
    elseif ($env:BUILD_SOURCEBRANCHNAME -and $PRIMARY_BRANCH_NAMES -notcontains $env:BUILD_SOURCEBRANCHNAME) {
        # This is an ADO build of a non-primary branch but is not a pull request.
        # Just tick the branch name in front (lowercase).
        $branchPrefix = ($env:BUILD_SOURCEBRANCHNAME).ToLower()
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
            foreach ($candidate in $PRIMARY_BRANCH_NAMES) {
                if ($sourceRef -eq "refs/heads/$candidate") {
                    $sourceRef = ""
                }
            }
        }

        # branchPrefix will be parsed from sourceRef down below (if sourceRef got set)
    }

    if ($sourceRef) {
        # We obtained the reference to the source branch but don't have the prefix figured out yet.
        # So we cut the reference string (refs/heads/abc123) after the last / and life is easy again.

        if ($sourceRef.Contains("/")) {
            $branchPrefix = $sourceRef.Substring($sourceRef.LastIndexOf("/") + 1)
        }
        else {
            Write-Error "Unable to parse source reference: $sourceRef"
        }
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
    Write-Host "::set-output name=VERSION_STRING::$versionString"
    return $versionString
}