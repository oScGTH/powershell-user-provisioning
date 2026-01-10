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
        [string]$Path,

        [string]$LogPath = "..\logs\provisioning.log"
    )

    write-UPLog -Message "Starting user data import from $Path" -LogPath $LogPath
    
    try {
        # If statement giving error if path isn't found.
        if (-not (Test-Path $Path)) {
            throw "Input file not found: $Path"
        }

        # Gets the filetype.
        $extension = [IO.path]::GetExtension($Path).ToLower()

        # Compares filetype expression with multiple conditions.
        switch ($extension) {
            ".csv" {
                $data = Import-Csv -Path $Path
            }
            ".json" {
                $data = Get-Content -Path $Path -Raw | ConvertFrom-Json
            }
            default {
                throw "Unsupported input format: $extension"
            }
        }

        $count = @($data).Count
        write-UPLog -Message "Successfully imported $count user record(s)." -LogPath $LogPath

        return $data
    }
    catch {
        write-UPLog -Message "Failed to import user data: $_" -Level ERROR -LogPath $LogPath
        throw
    }
    
}

# Validating information about users.
function Test-UPUserData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object[]]$Users,

        [string[]]$RequiredFields = @(
            "FirstName",
            "LastName",
            "Username",
            "Department",
            "Role"
        ),

        [string]$LogPath = "..\logs\provisioning.log"

    )

    $validUsers = @()

    foreach ($user in $Users) {
        $missingFields = @()

        foreach ($field in $RequiredFields) {
            if (-not ($user.PSObject.Properties.Name -contains $field)) {
                    $missingFields += $field
                    continue
            }

            $value = $user.PSObject.Properties[$field].value

            if ([string]::IsNullOrWhiteSpace($value)) {
                $missingFields += $field
            }
        }

        if ($missingFields.Count -gt 0) {
            $username = $user.PSObject.Properties["Username"].Value
            Write-UPLog `
                -Message "User '$username' is missing required field(s): $($missingFields -join ', ')" `
                -Level WARN `
                -LogPath $LogPath
            continue
        }

        $validUsers += $user
    } 

    Write-UPLog -Message "Validation complete: $($validUsers.Count) valid user(s)" -LogPath $LogPath
    return $validUsers
}

function Invoke-UPProvisioning {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [object[]]$Users,

        [string]$LogPath = "..\logs\provisioning.log"
    )

    foreach ($user in $Users) {

        $username   = $user.PSObject.Properties["Username"].Value
        $department = $user.PSObject.Properties["Department"].Value
        $role       = $user.PSObject.Properties["Role"].Value

        if ($PSCmdlet.ShouldProcess($username, "Provision user")) {
            Write-UPLog `
                -Message "Would provision user '$username' (Department: $department, Role: $role)"`
                -LogPath $LogPath
        }
    }

    Write-UPLog -Message "Provisioning simulation complete for $($Users.Count) user(s)" -LogPath $LogPath
}

function New-UPUser {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [object]$Users,

        [string]$DomainDN = "DC=lab,DC=local",

        [string]$LogPath = "..\logs\provisioning.log"
    )

    Import-Module ActiveDirectory -ErrorAction Stop

    $firstName  = $Users.PSObject.Properties["FirstName"].value
    $lastName   = $Users.PSObject.Properties["LastName"].value
    $username   = $Users.PSObject.Properties["Username"].value
    $department = $Users.PSObject.Properties["Department"].value
    
    $ouPath = "OU=$department,OU=Users,$DomainDN"

    if ($PSCmdlet.ShouldProcess($username, "Create AD user")) {
        Write-UPLog `
            -Message "Creating AD user '$username' in '$ouPath'" `
            -LogPath $LogPath
        
        New-UPUser `
            -Name "$firstName $lastName" `
            -GivenName $firstName `
            -Surname $lastName `
            -SamAccountName $username `
            -UserPrincipalName "username@$($DomainDN -replace 'DC=', '' -replace ',', '.')" `
            -Path $ouPath `
            -AccountPassword (ConvertTo-SecureString "TempP@ss123!" -AsPlainText -Force) `
            -Enabled $true `
            ChangePasswordAtLogon $true
    }
}

function Set-UPUserGroups {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [object]$Users,

        [string]$LogPath = "..\logs\provisioning.log"
    )
    
    Import-Module ActiveDirectory -ErrorAction Stop

    $username = $User.PSObject.Properties["Username"].Value
    $role     = $User.PSObject.Properties["Role"].Value

    # Role -> Group mapping
    $roleGroupMap = @{
        "Helpdesk" = @("IT-Helpdesk", "IT-Users")
        "HR-Advisor" = @("HR-Users")
    }

    if (-not $roleGroupMap.ContainsKey($role)) {
        Write-UPLog `
            -Message "No group mapping defined for role '$role' (user '$username')" `
            -Level WARN
            -LogPath $LogPath
        return
    }

    foreach ($group in $roleGroupMap[$role]) {
        if ($PSCmdlet.ShouldProcess($username, "Add to AD group '$group'")) {
            Write-UPLog `
                -Message "Adding user '$username' to group '$group'"`
                -LogPath $LogPath
            
            Add-ADGroupMember `
                -Identity $group `
                -Members $username
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
Export-ModuleMember -Function `
    Import-UPUserData, `
    Write-UPLog, `
    Test-UPUserData, `
    Invoke-UPProvisioning, `
    New-UPUser, `
    Set-UPUserGroups