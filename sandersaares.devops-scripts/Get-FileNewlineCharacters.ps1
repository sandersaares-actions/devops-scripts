function Get-FileNewlineCharacters {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$path
    )

    if (!(Test-Path $path -PathType Leaf)) {
        Write-Error "File not found: $path"
    }

    $absolutePath = Resolve-Path $path
    $contentBytes = [System.IO.File]::ReadAllBytes($absolutePath)

    $cr = $contentBytes -contains 0x0d
    $lf = $contentBytes -contains 0x0a

    # Kind of hacky but whatever.
    if ($cr -and $lf) {
        Write-Verbose "Using CR LF for line endings."
        return "`r`n"
    }
    elseif ($cr) {
        Write-Verbose "Using CR for line endings."
        return "`r"
    }
    elseif ($lf) {
        return "`n"
    }
    else {
        # Fall back to whatever the platform default is, if none were found in the file.
        Write-Verbose "Using platform default for line endings."
        return [Environment]::NewLine
    }
}
