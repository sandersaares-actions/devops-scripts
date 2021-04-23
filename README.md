A set of useful devops scripts that are published as standalone zip, PowerShell module and as GitHub actions.

Usage as raw scripts:

1. Get the scripts as ZIP, extract somewhere.
1. Execute `sandersaares-actions/Load-AllFunctions.ps1`
1. Call the scripts as PowerShell functions (do not call them as scripts).

Usage as PowerShell module:

1. `Install-Module sandersaares.devops-scripts` (On first run)
1. `Import-Module sandersaares.devops-scripts` (If already installed)
1. Call the scripts as PowerShell functions (do not call them as scripts).

Usage as GitHub actions:

1. See marketplace for `sandersaares-actions/*`.

Not every script is available as a GitHub action (created on-demand as needed).