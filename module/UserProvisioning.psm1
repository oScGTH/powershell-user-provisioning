# UserProvisioning.psm1
# Core module for user and access automation

Set-StrictMode -Version Latest

#Import user data.
function Import-UPUserData {
    
    # Makes the function run as a cmdlet.
    [CmdletBinding()]

    # Makes sure a path is given.
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    # If statement giving error if path isn't found.
    if (-not (Test-Path $Path)) {
        throw "Input file not found: $Path"
    }

    # Gets the filetype.
    $extension = [IO.path]::GetExtension($Path).ToLower()

    # Compares filetype expression with multiple conditions.
    switch ($extension) {
        ".csv" {
            return Import-Csv -Path $Path
        }
        ".json" {
            return Get-Content -Path $Path -Raw | ConvertFrom-Json
        }
        default {
            throw "Unsupported input format: $extension"
        }
    }
}


# Logging function.
function Write-UPLog {
    [CmdletBinding()]

    param (
        # Parameter forcing message input, preventing empty logs.
        [Parameter(Mandatory)]
        [string]$Message,

        # The only valid values. Input validation.
        [ValidateSet("INFO", "WARN", "ERROR")]
        [string]$Level = "INFO",

        # Creates a directory for logs.
        [string]$LogPath = "..\logs\provisioning.log"
    )
    
    # Gets the timestamp of the log.
    $timestamp = Get-Date -Format "dd-MM-yyyy HH:mm:ss"

    # The actual log entry, with timestamp, level of log and message.
    $entry = "$timestamp [$Level] $Message"

    # Makes sure that the log directory exists.
    $logDir = Split-Path $LogPath -Parent

    # Function preventing the script from failing if the directory is missing.
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir | Out-Null
    }
    
    #Writes to the log file.
    Add-Content -Path $LogPath -Value $Entry
}

# Defines the modules public API.
Export-ModuleMember -Function Import-UPUserData, Write-UPLog