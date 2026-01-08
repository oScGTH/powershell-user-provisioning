## Input Handling

User data is imported via Import-UPUserData, which abstracts CSV and JSON input into PowerShell objects. This allows the provisioning logic to remain input-agnostic and simplifies future extensions.

## Logging

All operations are logged through a centralized Write-UPLog function.
This ensures consistent formatting, supports severity levels, and
simplifies future error handling and rollback mechanisms.