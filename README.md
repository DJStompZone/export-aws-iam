# Export AWS IAM

Exports IAM user configurations from an AWS account into structured JSON files, using [AWS Tools for PowerShell](https://aws.amazon.com/powershell/).

## Features 

- Exports all IAM users in the specified AWS profile
- Captures:
  - User metadata
  - Attached policies
  - Inline policies
  - Permissions boundaries
  - Tags (if supported)
- Optionally erases previous exports
- Attempts to auto-install missing Powershell modules, if needed


## Requirements 

- Windows PowerShell 5.1+ or PowerShell Core
- [`AWS.Tools.Installer`](https://www.powershellgallery.com/packages/AWS.Tools.Installer/1.0.2.5) (Optional, but advised)
- [`AWS.Tools.IdentityManagement`](https://www.powershellgallery.com/packages/AWS.Tools.IdentityManagement)
- [AWS CLI](https://winget.run/pkg/Amazon/AWSCLI) configured with one or more named profiles (`aws configure`)


## Usage 

```powershell
.\Export-IAMData.ps1 [-SourceProfile <profile>] [-ExportPath <path>] [-EraseFirst] [-Force]
````

### Parameters

| Name            | Description                                        | Default        |
| --------------- | -------------------------------------------------- | -------------- |
| `SourceProfile` | AWS CLI profile name to use                        | `"default"`    |
| `ExportPath`    | Where to save exported files                       | `C:\IAMExport` |
| `EraseFirst`    | Wipes the export directory before writing          | `False`        |
| `Force`         | Skips confirmation when erasing with `-EraseFirst` | `False`        |


## Example 

```powershell
.\Export-IAMData.ps1 -SourceProfile "prod" -ExportPath "D:\IAMBackups" -EraseFirst -Force
```

This will:

* Erase the `D:\IAMBackups` folder
* Export all IAM user data from the `prod` AWS profile
* Save individual user files as JSON for portability and re-import




## 🛠 Installing AWS Tools (Manually)

```powershell
Install-Module -Name AWS.Tools.Installer -Force
# You may need to restart Powershell before proceeding
Install-AWSToolsModule -Name AWS.Tools.IdentityManagement -Force
```

