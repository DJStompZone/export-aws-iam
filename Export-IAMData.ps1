<#
.SYNOPSIS
Exports AWS IAM user data in JSON format via AWS CLI and AWSTools.

.DESCRIPTION
This script connects to an AWS account using a specified profile and exports all IAM user information to a given directory in JSON format.
It includes:
- Basic user metadata
- Attached policies
- Inline policies
- Tags (if supported by the installed AWS.Tools.IAM module)
- Permissions boundaries

Note that AWS Tools for PowerShell must be installed for this script to work correctly.
(See links section for more information)

.PARAMETER SourceProfile
The AWS CLI named profile to use when querying IAM data. Defaults to 'default'.

.PARAMETER ExportPath
The local directory to save exported JSON files. Defaults to 'C:\IAMExport'.

.EXAMPLE
.\Export-IAMData.ps1 -SourceProfile "prod" -ExportPath "C:\Backups\IAM"

.EXAMPLE
.\export-iam-stuff.ps1

This will run the export using the default profile and save to C:\IAMExport.

.NOTES
Author: DJ Stomp <85457381+DJStompZone@users.noreply.github.com>
License: MIT
Project: https://github.com/djstompzone/export-aws-iam

.LINK
https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html

.LINK
https://aws.amazon.com/powershell/
#>

param (
    [string]$SourceProfile = "default",
    [string]$ExportPath = "C:\IAMExport",
	[switch]$EraseFirst,
	[switch]$Force
)

if (-not (Test-Path -Path $ExportPath)) {
    New-Item -ItemType Directory -Path $ExportPath -Force | Out-Null
}

function Export-IAMUserObject {
    param ($UserName)
    try {
        $data = Get-IAMUser -UserName $UserName -ProfileName $SourceProfile
        if ($data) {
            $data | ConvertTo-Json -Depth 10 | Set-Content "$($ExportPath)\user-$($UserName).json"
            if ($data.PermissionsBoundary -and $data.PermissionsBoundary.PermissionsBoundaryArn) {
				$data.PermissionsBoundary | ConvertTo-Json -Depth 3 | Set-Content "$($ExportPath)\user-permissions-boundary-$($UserName).json"
			}

        }
    } catch {
        Write-Warning "  - Failed to get user object for $($UserName): $($_)"
    }
}

function Export-IAMAttachedPolicies {
    param ($UserName)
    try {
        $attached = Get-IAMAttachedUserPolicyList -UserName $UserName -ProfileName $SourceProfile
        if ($attached.AttachedPolicies) {
            $attached | ConvertTo-Json -Depth 10 | Set-Content "$($ExportPath)\user-attached-policies-$($UserName).json"
        }
    } catch {
        Write-Warning "  - Failed to get attached policies for $($UserName): $($_)"
    }
}

function Export-IAMInlinePolicies {
    param ($UserName)
    try {
        $inline = Get-IAMUserPolicyList -UserName $UserName -ProfileName $SourceProfile
        if ($inline.PolicyNames) {
            foreach ($PolicyName in $inline.PolicyNames) {
                try {
                    $policy = Get-IAMUserPolicy -UserName $UserName -PolicyName $PolicyName -ProfileName $SourceProfile
                    $policy | ConvertTo-Json -Depth 10 | Set-Content "$($ExportPath)\user-inline-policy-$($UserName)-$($PolicyName).json"
                } catch {
                    Write-Warning "    - Failed to export inline policy `'$($PolicyName)`' for $($UserName): $($_)"
                }
            }
        }
    } catch {
        Write-Warning "  - Failed to list inline policies for $($UserName): $($_)"
    }
}

function Export-IAMUserTags {
    param ($UserName)
    if (-not (Get-Command Get-IAMUserTag -ErrorAction SilentlyContinue)) {
        Write-Verbose "  - Skipping tag export: Get-IAMUserTag not available"
        return
    }
    try {
        $tags = Get-IAMUserTag -UserName $UserName -ProfileName $SourceProfile
        if ($tags.Tags) {
            $tags | ConvertTo-Json -Depth 5 | Set-Content "$($ExportPath)\user-tags-$($UserName).json"
        }
    } catch {
        Write-Warning "  - Failed to get tags for $($UserName): $($_)"
    }
}

function Export-IAMUserData {
    param ($UserName)
    Write-Host "`n[+] Exporting user: $($UserName)"
    Export-IAMUserObject $UserName
    Export-IAMAttachedPolicies $UserName
    Export-IAMInlinePolicies $UserName
    Export-IAMUserTags $UserName
}

function Erase-ExportDirectory {
    param (
        [bool]$ForceErasure = $false
    )

    if (-not (Test-Path -Path $ExportPath)) {
        Write-Warning "Nothing to erase; Path $($ExportPath) does not exist."
        return
    }

    if (-not $ForceErasure) {
        $confirmation = Read-Host -Prompt "This will ERASE all data in $($ExportPath) and subfolders.`nAre you sure? (y/n)"
        if (-not $confirmation.ToLower().StartsWith("y")) {
            Write-Host "Erasure operation aborted. No action taken."
            return
        }
    }

    Write-Host "Erasing all data in $($ExportPath)..."
    try {
        Remove-Item -Path "$ExportPath\*" -Recurse -Force -ErrorAction Stop
    } catch {
        Write-Warning "  - Failed to clear export directory: $($_)"
    }
}

function Export-IAMData {
	if ($EraseFirst){
		Erase-ExportDirectory -ForceErasure $Force
	}
    Write-Host "`n== Exporting IAM users from profile `'$($SourceProfile)`' =="
    $users = Get-IAMUserList -ProfileName $SourceProfile

    if (-not $users) {
        Write-Warning "No users found in profile `'$($SourceProfile)`'."
        exit 0
    }

    $users | ConvertTo-Json -Depth 5 | Set-Content "$($ExportPath)\users.json"

    foreach ($user in $users) {
        Export-IAMUserData -UserName $user.UserName
    }

    Write-Host "`nExport complete. Files saved to "$ExportPath
}

Export-IAMData
