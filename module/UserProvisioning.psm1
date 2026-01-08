# UserProvisioning.psm1
# Core module for user and access automation

Set-StrictMode -Version Latest

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

# Exports the function.
Export-ModuleMember -Function Import-UPUserData