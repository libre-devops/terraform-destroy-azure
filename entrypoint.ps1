#!/usr/bin/env pwsh

param()

$ErrorActionPreference = 'Stop'

function Get-ActionInput {
    param(
        [string]$name,
        $default = $null
    )
    $envVar = "INPUT_$($name.Replace('-', '_').ToUpper())"
    $value = [System.Environment]::GetEnvironmentVariable($envVar)
    if (![string]::IsNullOrEmpty($value)) {
        return $value
    }
    return $default
}

Write-Host "===== DEBUG: Dumping all INPUT_* env vars ====="
Get-ChildItem env: | Where-Object { $_.Name -like 'INPUT_*' } | Sort-Object Name | ForEach-Object { Write-Host "$($_.Name) = $($_.Value)" }
Write-Host "===== END DEBUG ====="

# Map all inputs from action.yml (use the kebab-case name)
$TerraformCodeLocation                      = Get-ActionInput 'terraform-code-location'                     'terraform'
$TerraformStackToRunJson                    = Get-ActionInput 'terraform-stack-to-run-json'                 '["all"]'
$TerraformWorkspace                         = Get-ActionInput 'terraform-workspace'                         ''
$RunTerraformInit                           = Get-ActionInput 'run-terraform-init'                          'true'
$RunTerraformValidate                       = Get-ActionInput 'run-terraform-validate'                      'true'
$RunTerraformPlan                           = Get-ActionInput 'run-terraform-plan'                          'true'
$RunTerraformPlanDestroy                    = Get-ActionInput 'run-terraform-plan-destroy'                  'false'
$RunTerraformApply                          = Get-ActionInput 'run-terraform-apply'                         'false'
$RunTerraformDestroy                        = Get-ActionInput 'run-terraform-destroy'                       'false'
$TerraformInitCreateBackendStateFileName    = Get-ActionInput 'terraform-init-create-backend-state-file-name' 'true'
$TerraformInitCreateBackendStateFilePrefix  = Get-ActionInput 'terraform-init-create-backend-state-file-prefix' ''
$TerraformInitCreateBackendStateFileSuffix  = Get-ActionInput 'terraform-init-create-backend-state-file-suffix' ''
$TerraformInitExtraArgsJson                 = Get-ActionInput 'terraform-init-extra-args-json'              '[ ]'
$TerraformPlanExtraArgsJson                 = Get-ActionInput 'terraform-plan-extra-args-json'              '[ ]'
$TerraformPlanDestroyExtraArgsJson          = Get-ActionInput 'terraform-plan-destroy-extra-args-json'      '[ ]'
$TerraformApplyExtraArgsJson                = Get-ActionInput 'terraform-apply-extra-args-json'             '[ ]'
$TerraformDestroyExtraArgsJson              = Get-ActionInput 'terraform-destroy-extra-args-json'           '[ ]'
$DebugMode                                  = Get-ActionInput 'debug-mode'                                 'false'
$DeletePlanFiles                            = Get-ActionInput 'delete-plan-files'                           'true'
$TerraformVersion                           = Get-ActionInput 'terraform-version'                           'latest'
$RunCheckov                                 = Get-ActionInput 'run-checkov'                                'true'
$CheckovSkipCheck                           = Get-ActionInput 'checkov-skip-check'                         ''
$CheckovSoftfail                            = Get-ActionInput 'checkov-softfail'                           'false'
$CheckovExtraArgsJson                       = Get-ActionInput 'checkov-extra-args-json'                     '[ ]'
$TerraformPlanFileName                      = Get-ActionInput 'terraform-plan-file-name'                    'tfplan.plan'
$TerraformDestroyPlanFileName               = Get-ActionInput 'terraform-destroy-plan-file-name'            'tfplan-destroy.plan'
$CreateTerraformWorkspace                   = Get-ActionInput 'create-terraform-workspace'                  'true'
$UseAzureClientSecretLogin                  = Get-ActionInput 'use-azure-client-secret-login'               'false'
$UseAzureOidcLogin                          = Get-ActionInput 'use-azure-oidc-login'                       'true'
$UseAzureUserLogin                          = Get-ActionInput 'use-azure-user-login'                        'false'
$UseAzureManagedIdentityLogin               = Get-ActionInput 'use-azure-managed-identity-login'            'false'
$UseAzureServiceConnection                  = Get-ActionInput 'use-azure-service-connection'                'true'
$InstallTenvTerraform                      = Get-ActionInput 'install-tenv-terraform'                      'false'
$InstallAzureCli                           = Get-ActionInput 'install-azure-cli'                           'false'
$AttemptAzureLogin                         = Get-ActionInput 'attempt-azure-login'                         'false'
$InstallCheckov                            = Get-ActionInput 'install-checkov'                             'false'

Write-Host "🏗️  Starting Libre DevOps Terraform Action..."
Write-Host "TerraformCodeLocation: $TerraformCodeLocation"
Write-Host "TerraformStackToRunJson: $TerraformStackToRunJson"
Write-Host "TerraformWorkspace: $TerraformWorkspace"
Write-Host "TerraformVersion: $TerraformVersion"
Write-Host "DebugMode: $DebugMode"

$ScriptParams = @{
    TerraformCodeLocation                    = $TerraformCodeLocation
    TerraformStackToRunJson                  = $TerraformStackToRunJson
    TerraformWorkspace                       = $TerraformWorkspace
    RunTerraformInit                         = $RunTerraformInit
    RunTerraformValidate                     = $RunTerraformValidate
    RunTerraformPlan                         = $RunTerraformPlan
    RunTerraformPlanDestroy                  = $RunTerraformPlanDestroy
    RunTerraformApply                        = $RunTerraformApply
    RunTerraformDestroy                      = $RunTerraformDestroy
    TerraformInitCreateBackendStateFileName  = $TerraformInitCreateBackendStateFileName
    TerraformInitCreateBackendStateFilePrefix= $TerraformInitCreateBackendStateFilePrefix
    TerraformInitCreateBackendStateFileSuffix= $TerraformInitCreateBackendStateFileSuffix
    TerraformInitExtraArgsJson               = $TerraformInitExtraArgsJson
    TerraformPlanExtraArgsJson               = $TerraformPlanExtraArgsJson
    TerraformPlanDestroyExtraArgsJson        = $TerraformPlanDestroyExtraArgsJson
    TerraformApplyExtraArgsJson              = $TerraformApplyExtraArgsJson
    TerraformDestroyExtraArgsJson            = $TerraformDestroyExtraArgsJson
    DebugMode                                = $DebugMode
    DeletePlanFiles                          = $DeletePlanFiles
    TerraformVersion                         = $TerraformVersion
    RunCheckov                               = $RunCheckov
    CheckovSkipCheck                         = $CheckovSkipCheck
    CheckovSoftfail                          = $CheckovSoftfail
    CheckovExtraArgsJson                     = $CheckovExtraArgsJson
    TerraformPlanFileName                    = $TerraformPlanFileName
    TerraformDestroyPlanFileName             = $TerraformDestroyPlanFileName
    CreateTerraformWorkspace                 = $CreateTerraformWorkspace
    UseAzureClientSecretLogin                = $UseAzureClientSecretLogin
    UseAzureOidcLogin                        = $UseAzureOidcLogin
    UseAzureUserLogin                        = $UseAzureUserLogin
    UseAzureManagedIdentityLogin             = $UseAzureManagedIdentityLogin
    UseAzureServiceConnection                = $UseAzureServiceConnection
    InstallTenvTerraform                     = $InstallTenvTerraform
    InstallAzureCli                          = $InstallAzureCli
    AttemptAzureLogin                        = $AttemptAzureLogin
    InstallCheckov                           = $InstallCheckov
}

try {
    & ./Run-AzTerraform.ps1 @ScriptParams
} catch {
    throw "Libre DevOps Terraform Action failed: $($_.Exception.Message)"
}
