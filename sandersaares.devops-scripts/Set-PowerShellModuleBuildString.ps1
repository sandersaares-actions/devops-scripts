function Set-PowerShellModuleBuildString {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$path,

        [Parameter(Mandatory)]
        [string]$buildTimestamp
    )

    # The purpose of this script is to take the version string from the module manifest and to stick it in
    # the build number string of the build itself, just to associate builds with versions a bit better.

    # We will actually parse the module manifest for real here, since it is just read-only operation.

    # It needs to be .ps1 to be parsed (executed).
    $tempfile = [IO.Path]::GetTempFileName()
    $scriptfile = [IO.Path]::ChangeExtension($tempfile, ".ps1")
    Move-Item $tempfile $scriptfile | Out-Null
    Get-Content $path | Set-Content -Path $scriptfile

    $module = & $scriptfile

    $version = $module.ModuleVersion

    if ($module.PrivateData.PSData.Prerelease) {
        $version += $module.PrivateData.PSData.Prerelease
    }

    Write-Host "Parsed version string $version"

    $fullVersion = "$version-$buildTimestamp"

    Write-Host "##vso[build.updatebuildnumber]$fullVersion"
    Write-Host "::set-output name=versionstring::$fullVersion"
}