$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "Expand-Tokens.ps1")
. (Join-Path $PSScriptRoot "Get-FileEncoding.ps1")
. (Join-Path $PSScriptRoot "Get-FileNewlineCharacters.ps1")
. (Join-Path $PSScriptRoot "Get-TimeBasedNuGetVersionString.ps1")
. (Join-Path $PSScriptRoot "Get-TimeBasedVersionString.ps1")
. (Join-Path $PSScriptRoot "Set-DotNetBuildAndVersionStrings.ps1")
. (Join-Path $PSScriptRoot "Set-NuGetVersionString.ps1")
. (Join-Path $PSScriptRoot "Set-PowerShellModuleBuildString.ps1")
. (Join-Path $PSScriptRoot "Set-PowerShellModuleMetadataBeforeBuild.ps1")
. (Join-Path $PSScriptRoot "Set-VersionStringBranchPrefix.ps1")