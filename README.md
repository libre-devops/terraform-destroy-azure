# Terraform Azure AzDO Pipeline Templates

A collection of **Azure DevOps pipeline templates** designed to simplify and standardize Terraform deployments for Azure.  
These templates leverage the **LibreDevOpsHelpers** PowerShell module for reusable tasks and workflows across your pipelines, but are available within the repo locally inside `PowerShellModules` folder.

---

## Prerequisites

- **Azure DevOps** organization and project.
- **Terraform** code repository structured with numeric stack folders (`0_rg`, `1_network`, etc.).
- **Service connection** in Azure DevOps with permissions to your Azure subscription.
- **PowerShell host** with `PowerShell 7+` agents (Windows, Linux, macOS).
- **LibreDevOpsHelpers** PowerShell module installed on agents or in the repository:
  ```powershell
  Install-Module -Name LibreDevOpsHelpers -Scope CurrentUser
  ```
  
- You can also call the script via `Run-AzTerraform.ps1`, where the local modules are imported istead of the remote.

---

## Concept

1. **Discover Stacks**
    - The script scans the `${TerraformCodeLocation}` folder for subdirectories matching `^\d+_.+` (e.g. `0_rg`, `1_network`, etc.).
    - It builds an ordered list based on the leading number in each folder name.

2. **Normalize Execution Order**
    - **Apply/Plan**: Uses the naturally sorted list (`0_rg`, then `1_network`, …).
    - **Destroy**: When `RunTerraformPlanDestroy` or `RunTerraformDestroy` is true, it reverses the sorted list so that higher-numbered stacks teardown first (e.g. `1_network` → `0_rg`).

3. **Per-Stack Workflow**  
   For each stack folder in the final order:
    1. **Fmt Check**
       ```powershell
       Invoke-TerraformFmtCheck -CodePath $folder
       ```
    2. **Init** (if enabled)
       ```powershell
       Invoke-TerraformInit -CodePath $folder -InitArgs '-input=false','-upgrade=true'
       ```
    3. **Workspace Select** (if enabled)
       ```powershell
       Invoke-TerraformWorkspaceSelect -CodePath $folder -WorkspaceName $TerraformWorkspace
       ```
    4. **Validate**
       ```powershell
       Invoke-TerraformValidate -CodePath $folder
       ```
    5. **Plan / Plan-Destroy**
        - **Plan**:
          ```powershell
          Invoke-TerraformPlan -CodePath $folder `
                              -PlanFile $TerraformPlanFileName `
                              -PlanArgs $TerraformPlanExtraArgs
          ```
        - **Plan-Destroy**:
          ```powershell
          Invoke-TerraformPlanDestroy -CodePath $folder `
                                     -PlanFile $TerraformDestroyPlanFileName `
                                     -PlanArgs $TerraformPlanDestroyExtraArgs
          ```
    6. **Convert to JSON + Checkov** (if planning)
       ```powershell
       Convert-TerraformPlanToJson -CodePath $folder -PlanFile $chosenPlanFile
       Invoke-Checkov -CodePath $folder `
                      -CheckovSkipChecks $CheckovSkipCheck `
                      -SoftFail:$CheckovSoftfail
       ```
    7. **Apply / Destroy**
        - **Apply**:
          ```powershell
          Invoke-TerraformApply -CodePath $folder `
                                -SkipApprove `
                                -ApplyArgs $TerraformApplyExtraArgs
          ```
        - **Destroy**:
          ```powershell
          Invoke-TerraformDestroy -CodePath $folder `
                                  -SkipApprove `
                                  -DestroyArgs $TerraformDestroyExtraArgs
          ```

4. **Cleanup**
    - After all stacks finish, if `DeletePlanFiles` is true, the script deletes all generated plan and JSON files from each stack folder.

---

This ensures that your infrastructure is built in dependency order (low-numbered stacks first) and torn down in reverse (high-numbered stacks first), with consistent formatting, validation, scanning and cleanup at each step.

---

## Usage

1. **Import templates** in your YAML pipeline:
   ```yaml
   resources:
     repositories:
       - repository: templates
         type: git
         name: <your org>/terraform-azure-azdo-pipeline-templates

   stages:
     - template: azure-pipeline.yml@templates
       parameters:
         TerraformCodeLocation: 'terraform'
         TerraformStackToRun: ['all']
         TerraformWorkspace: 'dev'
         UseAzureClientSecretLogin: true
         AzureServiceConnection: 'MyAzServiceConnection'
   ```

2. **Customize parameters**:
    - `TerraformCodeLocation`: Path to your Terraform code folder.
    - `TerraformStackToRun`: List of stack folder names (or `all`).
    - `TerraformWorkspace`: Terraform workspace name.
    - `RunTerraformInit`, `RunTerraformPlan`, `RunTerraformApply`, etc. (boolean flags).
    - `UseAzureClientSecretLogin`, `UseAzureOidcLogin`, etc. (authentication modes).

3. **Leverage helpers**:  
   Templates use `Invoke-Terraform*`, `Connect-AzureCli`, and `Invoke-Checkov` commands from the [LibreDevOpsHelpers](https://www.powershellgallery.com/packages/LibreDevOpsHelpers) module for a consistent experience.

---

## Template Files

- **azure-pipeline.yml**: Main pipeline entry point.
- **Local-DevelopmentScript.ps1**: Run and test pipelines locally.
- **PowerShellModules/**: Sample module directory for local development.

---

## Local Testing

To run locally without Azure DevOps:

```powershell
# Install required modules
Install-Module -Name LibreDevOpsHelpers -Scope CurrentUser

# Execute local script
.\Local-DevelopmentScript.ps1 -TerraformCodeLocation 'terraform' -TerraformStackToRun @('all') -UseAzureClientSecretLogin $true
```

---

## Contributing

1. Fork the repository.
2. Create a feature branch.
3. Submit a pull request.
4. CI will lint, validate, and test your changes.

---

## License

MIT © Libre DevOps  
