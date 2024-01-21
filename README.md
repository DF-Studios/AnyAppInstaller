# AnyAppInstaller: A PowerShell Script for Automated Software Installation

AnyAppInstaller is a PowerShell script designed to streamline the process of downloading and installing software from a specified URL or server file path. The script supports a variety of file types, including EXE, MSI, MSIX, and ZIP files.

The sequence of operations begins with URL verification. If the URL points to a SharePoint location, the script appends "download=1" to ensure successful downloading. Following this, the script fetches the file name from the URL, preparing the local and server file paths.

User Account Control (UAC) settings are then inspected and temporarily disabled to avoid installation prompts. The script also ensures the presence of a local temporary folder for the download.

The script checks the availability of the file on the server. If found, it copies the file from the server to the local machine. Otherwise, the file is downloaded from the web.

Upon successful download, the script identifies the file type and employs the relevant method for installation. For ZIP files, it extracts the contents and identifies the file type of the nested installer to determine the installation procedure.

Post-installation, the script performs cleanup by deleting the installer and any extracted folders from the local machine. Finally, it reverts the UAC settings to their original state.

In essence, AnyAppInstaller provides a robust solution for automating software downloads and installations, saving time and enhancing efficiency.



# Instructions for Variables

Here are the instructions for modifying the variables in the script:

1. **$urlPath**: This variable should be set to the URL where the EXE, MSI, MSIX, or ZIP file is located. If the file is hosted on SharePoint, the script will automatically append "download=1" to the URL to ensure the file is downloaded.

2. **$nestedInstallerFolderAndFile**: If the file to be installed is a ZIP file, this variable should be set to the name of the sub-folder or file that will be extracted from the ZIP file. The primary folder is not required. This variable is used to locate the installer within the extracted contents of the ZIP file.

3. **$arguments**: This variable should be set to any arguments that need to be passed to the installer. These arguments will be used when running the installer.

4. **$fileSharePath**: This variable should be set to the file path on the server where the file is located. The script will first check this location for the file before attempting to download it from the URL. If the file is found on the server, it will be copied to the local machine for installation.

Remember to replace the empty quotes ("") with your desired values for each variable.
