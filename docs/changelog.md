# Changelog

## v0.6.0
- Added `Invoke-UPBulkProvisioning` to orchestrate user provisioning in bulk.
- Implemented per-user transaction handling with structured result output.
- Prepared rollback support by tracking completed actions per user.
- Enabled full simulation of bulk provisioning using `-WhatIf`.

## v0.5.0
- Added `Set-UPUserGroups` for role-based Active Directory group assignment.
- Implemented per-group `SupportsShouldProcess` handling.
- Introduced role-to-group mapping with safe handling of unknown roles.

## v0.4.0
- Added `New-UPUser` for creating Active Directory users.
- Implemented safe write operations using `SupportsShouldProcess`.
- Dynamic OU placement based on user department.
- Introduced first real AD write operation in the pipeline.

## v0.3.0
- Added provisioning stub using `Invoke-UPProvisioning`.
- Implemented `SupportsShouldProcess` for safe simulation with `-WhatIf`.
- Connected validated user pipeline to provisioning stage without side effects.

## v0.2.0
- Added strict input validation for user objects.
- Invalid users are filtered and logged with WARN severity.
- Ensured compatibility with PowerShell StrictMode.

## v0.1.1
- Fixed control flow in `Import-UPUserData` to prevent early function exit.
- Ensured successful imports are logged before returning data.
- Improved robustness of error handling under strict mode.

## v0.1.0
- Initial module structure.
- CSV and JSON input support.
- Centralized logging function.