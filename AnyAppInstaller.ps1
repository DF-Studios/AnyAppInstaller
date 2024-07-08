<#
.SYNOPSIS
    This script installs an application from a specified URL, with support for different installer types (EXE, MSI, MSIX, ZIP).

.PARAMETER program
    The name of the program to be installed.

.PARAMETER urlPath
    The URL to the installer (EXE, MSI, MSIX, or ZIP).

.PARAMETER nestedInstallerFolderAndFile
    If the installer is a ZIP file, the name of the sub-folder/file after extraction.

.PARAMETER arguments
    The arguments to be passed to the installer.

.PARAMETER fileToCheck
    The file path to check if the application is already installed.

.DESCRIPTION
    This script downloads an installer from a specified URL and installs the application. It supports different installer types
    (EXE, MSI, MSIX, ZIP) and handles nested installers within ZIP files. The script also includes a cleanup function to remove
    temporary files after installation.

.EXAMPLE
    .\installerScript.ps1 -program "MyApp" -urlPath "http://example.com/installer.zip" -nestedInstallerFolderAndFile "setup.exe" -arguments "/S" -fileToCheck "C:\Program Files\MyApp\installed.txt"

.NOTES
    Ensure that the necessary permissions are granted to run installers and manage files in the specified locations.

.AUTHOR
    Paul Clemons

.REVISION
    v1.0 - Initial version. PC - 2024/07/07
    v1.1 - Added parameters and conditional base variable assignment. DF - 2024/07/07
#>

param (
    [string]$jsonPath = "" # 'installers.json' here if possible.
)

# Example JSON content defined in the script if external not possible.
$jsonContent = @"
[
    {
        "program": "Program1",
        "urlPath": "http://example.com/installer1.zip",
        "nestedInstallerFolderAndFile": "setup1.exe",
        "arguments": "/S",
        "fileToCheck": "C:\\Program Files\\Program1\\installed.txt"
    },
    {
        "program": "Program2",
        "urlPath": "http://example.com/installer2.zip",
        "nestedInstallerFolderAndFile": "setup2.exe",
        "arguments": "/quiet",
        "fileToCheck": "C:\\Program Files\\Program2\\installed.txt"
    }
]
"@ | ConvertFrom-Json

# Overwrite JSON content if jsonPath is provided and valid
if ($jsonPath -ne "" -and (Test-Path $jsonPath)) {
    $jsonContent = Get-Content -Path $jsonPath | ConvertFrom-Json
} elseif ($jsonPath -ne "") {
    Write-Output "JSON file not found."
    exit 1
}

function Install-AnyApp {
    ### Input Parameters ###
    param (
        [string]$program = "",
        [string]$urlPath = "",
        [string]$nestedInstallerFolderAndFile = "",
        [string]$arguments = "",
        [string]$fileToCheck = ""
    )

    ### Base Variables ###
    $baseProgram = "Default Program"
    $baseUrlPath = "http://example.com/installer.zip"
    $baseNestedInstallerFolderAndFile = "setup.exe"
    $baseArguments = "/S"
    $baseFileToCheck = "C:\Program Files\Default Program\installed.txt"

    ### Assign Parameters or Base Variables ###
    if ($program -eq "") {
        $program = $baseProgram
    }
    if ($urlPath -eq "") {
        $urlPath = $baseUrlPath
    }
    if ($nestedInstallerFolderAndFile -eq "") {
        $nestedInstallerFolderAndFile = $baseNestedInstallerFolderAndFile
    }
    if ($arguments -eq "") {
        $arguments = $baseArguments
    }
    if ($fileToCheck -eq "") {
        $fileToCheck = $baseFileToCheck
    }

    ### Static Variables ###
    if ($urlPath -match "sharepoint") { # Check if URL contains "sharepoint" and append "download=1" if true
        $urlPath = "$urlPath&download=1"
    }
    $head = Invoke-WebRequest -UseBasicParsing -Method Head $urlPath # Gets URL Header Info
    $downloadFileName = $head.BaseResponse.ResponseUri.Segments[-1] # Extracts File Name from Header
    $downloadPath = "C:\Temp" # Local Temp Folder
    $installer = "$downloadPath\$downloadFileName" # Local Installer Path
    $extension = [IO.Path]::GetExtension($downloadFileName) # Get File Extension
    $fileNamePrefix = [IO.Path]::GetFileNameWithoutExtension($downloadFileName) # Get File Name without Extension
    $extractedPath = "$downloadPath\$fileNamePrefix" # Extracted ZIP Path
    $nestedExtension = [IO.Path]::GetExtension($nestedInstallerFolderAndFile) # Get Nested File Extension
    $nestedInstaller = "$extractedPath\$nestedInstallerFolderAndFile" # Get Nested File Name without Extension

    function Cleanup($installer, $extractedPath) {
        Write-Output "Starting Cleanup."
        Start-Sleep -Seconds 5 # Give Time for Installer to Close
        Remove-Item -Path $installer -Force # Delete Installer
        if (Test-Path $extractedPath) { # Check for Extracted Folder
            Remove-Item -Path $extractedPath -Recurse -Force # Delete Extracted Folder
        }
            Write-Output "Finished Cleanup."
    }

    ### Create Local Temp Folder ###
    if (!(Test-Path $downloadPath)) { # Check for Temp Folder
    [void](New-Item -ItemType Directory -Force -Path $downloadPath) # Create Temp Folder
    Write-Output "Temp folder created."
    }

    ### Install Application ###
    if (!(Test-Path $fileToCheck)) { # Check if application is installed
        ### Download from Web if the installer does not exist locally ###
        if (!(Test-Path $installer)) { # Check if the installer file exists
            Write-Output "Downloading installer."
            $ProgressPreference = 'SilentlyContinue' # Disable Download Status Bar
            Invoke-WebRequest -Uri $urlPath -OutFile $installer # Download File from Web
        }
        try {
            if ($extension -eq ".exe") { # Check if EXE
                Write-Output "Running installer as EXE."
                Start-Process -FilePath $installer -ArgumentList $arguments -Verb RunAs -Wait # Install EXE
            } elseif ($extension -eq ".msi") { # Check if MSI
                Write-Output "Running installer as MSI."
                Start-Process msiexec.exe -ArgumentList "/I ""$installer"" $arguments" -Verb RunAs -Wait # Install MSI
            } elseif ($extension -eq ".msix") { # Check if MSIX
                Write-Output "Running installer as MSIX."
                Add-AppPackage -Path $installer # Install MSIX
            } elseif ($extension -eq ".zip") { # Check if ZIP
                Write-Output "Extracting ZIP."
                Expand-Archive -LiteralPath $installer -DestinationPath $extractedPath -Force # Extract ZIP
                if (Test-Path $extractedPath) { # Check for Extracted Folder
                    if ($nestedExtension -eq ".exe") { # Check if EXE
                        Write-Output "Running installer as EXE."
                        Start-Process -FilePath $nestedInstaller -ArgumentList $arguments -Verb RunAs -Wait # Install EXE
                    } elseif ($nestedExtension -eq ".msi") { # Check if MSI
                        Write-Output "Running installer as MSI."
                        Start-Process msiexec.exe -ArgumentList "/I ""$nestedInstaller"" $arguments" -Verb RunAs -Wait # Install MSI
                    } elseif ($nestedExtension -eq ".msix") { # Check if MSIX
                        Write-Output "Running installer as MSIX."
                        Add-AppPackage -Path $nestedInstaller # Install MSIX
                    }
                }
            }
            # Check if application is installed
            if (Test-Path $fileToCheck) {
                # Exit with success code
                Write-Output "Successful installation."
                Cleanup $installer $extractedPath
                exit 0
            } else {
                # Exit with error code
                Write-Output "Installation failed."
                Cleanup $installer $extractedPath
                exit 1
            }
        } catch {
            # Exit with error code
            Write-Output "Installation failed."
            Cleanup $installer $extractedPath
            exit 1
        }
    } else {
        # Exit with success code (since this is expected behavior)
        Write-Output "$program already installed. Skipping installation."
        exit 0
    }
}

foreach ($item in $jsonContent) {
    Write-Output "Running installer for $($item.program)"
    Install-AnyApp `
        -program $item.program `
        -urlPath $item.urlPath `
        -nestedInstallerFolderAndFile $item.nestedInstallerFolderAndFile `
        -arguments $item.arguments `
        -fileToCheck $item.fileToCheck
}
