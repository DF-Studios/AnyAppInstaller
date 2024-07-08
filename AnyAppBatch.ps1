<#
.SYNOPSIS
    This script reads a JSON file containing installation parameters for multiple programs
    and runs the installer script for each program sequentially.

.PARAMETER jsonPath
    The path to the JSON file containing installation parameters.

.DESCRIPTION
    This script reads a JSON file specified by the jsonPath parameter. It expects the JSON file to contain an array
    of objects where each object has the following fields: program, urlPath, nestedInstallerFolderAndFile, arguments, and fileToCheck.
    The script will then invoke the installerScript.ps1 for each object, passing these parameters to it, and wait for each installation
    to complete before moving to the next one.

.EXAMPLE
    .\runInstallersFromJson.ps1 -jsonPath "installers.json"

    This will read the installation parameters from the "installers.json" file and run the installer script for each program.

.NOTES
    Ensure that the installerScript.ps1 and the JSON file are in the same directory as this script or provide the correct paths.

.AUTHOR
    Dustin Fontaine

.REVISION
    v1.0 - Initial version - 2024/07/07
#>

param (
    [string]$jsonPath = "installers.json"
)

if (!(Test-Path $jsonPath)) {
    Write-Output "JSON file not found."
    exit 1
}

$jsonContent = Get-Content -Path $jsonPath | ConvertFrom-Json

foreach ($item in $jsonContent) {
    Write-Output "Running installer for $($item.program)"
    Start-Process -FilePath "powershell.exe" -ArgumentList `
        "-File `".\installerScript.ps1`" `
        -program `"$($item.program)`" `
        -urlPath `"$($item.urlPath)`" `
        -nestedInstallerFolderAndFile `"$($item.nestedInstallerFolderAndFile)`" `
        -arguments `"$($item.arguments)`" `
        -fileToCheck `"$($item.fileToCheck)`"" `
        -Wait
}
