param (
    [string]$RunTerraformInit = "true",
    [string]$RunTerraformPlan = "true",
    [string]$RunTerraformPlanDestroy = "false",
    [string]$RunTerraformApply = "true",
    [string]$RunTerraformDestroy = "false",
    [string[]]$TerraformPlanExtraArgs = $null,
    [string[]]$TerraformPlanDestroyExtraArgs = $null,
    [string[]]$TerraformApplyExtraArgs = $null,
    [string[]]$TerraformDestroyExtraArgs = $null,
    [string]$DebugMode = "false",
    [string]$DeletePlanFiles = "true",
    [string]$TerraformVersion = "latest",
    [string]$RunCheckov = "true",
    [string]$CheckovSkipCheck = "CKV2_AZURE_31",
    [string]$CheckovSoftfail = "true",
    [string]$TerraformPlanFileName = "tfplan.plan",
    [string]$TerraformDestroyPlanFileName = "tfplan-destroy.plan",
    [string]$TerraformCodeLocation = "terraform",
    [string[]]$TerraformStackToRun = @('all'),
    [string]$CreateTerraformWorkspace = "true",
    [string]$TerraformWorkspace = "dev",
    [string]$AttemptAzureLogin = "true",
    [string]$UseAzureClientSecretLogin = "true",
    [string]$UseAzureOidcLogin = "false",
    [string]$UseAzureUserLogin = "false",
    [string]$UseAzureManagedIdentityLogin = "false"
)

$ErrorActionPreference = 'Stop'
$currentWorkingDirectory = (Get-Location).path
$fullTerraformCodePath = Join-Path -Path $currentWorkingDirectory -ChildPath $TerraformCodeLocation

# Get script directory
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

# Import all required modules
$modules = @("Logger", "Utils", "AzureCliLogin", "Terraform", "Homebrew", "Checkov", "Tenv", "Choco", "TerraformDocs")
foreach ($module in $modules)
{
    $modulePath = Join-Path -Path $scriptDir -ChildPath "PowerShellModules/$module.psm1"
    if (Test-Path $modulePath)
    {
        Import-Module $modulePath -Force -ErrorAction Stop
    }
    else
    {
        Write-Host "ERROR:  [$( $MyInvocation.MyCommand.Name )] Module not found: $modulePath" -ForegroundColor Red
        exit 1
    }
}

# Log that modules were loaded
_LogMessage -Level "INFO" -Message "[$( $MyInvocation.MyCommand.Name )] Modules loaded successfully" -InvocationName "$( $MyInvocation.MyCommand.Name )"

$convertedDebugMode = ConvertTo-Boolean $DebugMode
_LogMessage -Level 'DEBUG' -Message "DebugMode: `"$DebugMode`" → $convertedDebugMode" -InvocationName "$( $MyInvocation.MyCommand.Name )"

# Enable debug mode if DebugMode is set to $true
if ($true -eq $convertedDebugMode)
{
    $Global:DebugPreference = 'Continue'     # module functions see this
    $Env:TF_LOG = 'DEBUG'         # Terraform debug
}
else
{
    $Global:DebugPreference = 'SilentlyContinue'
}

try
{
    # Test pre-requisites are done
    $whichOs = Assert-WhichOs -PassThru

    if ("linux" -eq $whichOs.ToLower() -or "macos" -eq $whichOs.ToLower())
    {
        Assert-HomebrewPath
    }
    elseif ("windows" -eq $whichOs.ToLower())
    {
        Assert-ChocoPath
    }
    else
    {
        throw "Unsupported OS: $whichOs"
    }

    Get-InstalledPrograms -Programs @("Connect-AzAccount", "az", "terraform", "checkov")
    Test-TenvExists

    # Convert the string flags to Boolean and log the results at DEBUG level

    $convertedAttemptAzureLogin = ConvertTo-Boolean $AttemptAzureLogin
    _LogMessage -Level 'DEBUG' -Message "AttemptAzureLogin:   `"$AttemptAzureLogin`"   → $convertedAttemptAzureLogin"   -InvocationName $MyInvocation.MyCommand.Name

    $convertedUseAzureClientSecretLogin = ConvertTo-Boolean $UseAzureClientSecretLogin
    _LogMessage -Level 'DEBUG' -Message "UseAzureClientSecretLogin:   `"$UseAzureClientSecretLogin`"   → $convertedUseAzureClientSecretLogin"   -InvocationName $MyInvocation.MyCommand.Name

    $convertedUseAzureOidcLogin = ConvertTo-Boolean $UseAzureOidcLogin
    _LogMessage -Level 'DEBUG' -Message "UseAzureOidcLogin:           `"$UseAzureOidcLogin`"           → $convertedUseAzureOidcLogin"           -InvocationName $MyInvocation.MyCommand.Name

    $convertedUseAzureUserLogin = ConvertTo-Boolean $UseAzureUserLogin
    _LogMessage -Level 'DEBUG' -Message "UseAzureUserLogin:           `"$UseAzureUserLogin`"           → $convertedUseAzureUserLogin"           -InvocationName $MyInvocation.MyCommand.Name

    $convertedUseAzureManagedIdentityLogin = ConvertTo-Boolean $UseAzureManagedIdentityLogin
    _LogMessage -Level 'DEBUG' -Message "UseAzureManagedIdentityLogin: `"$UseAzureManagedIdentityLogin`" → $convertedUseAzureManagedIdentityLogin" -InvocationName $MyInvocation.MyCommand.Name

    $convertedRunTerraformInit = ConvertTo-Boolean $RunTerraformInit
    _LogMessage -Level 'DEBUG' -Message "RunTerraformInit: `"$RunTerraformInit`" → $convertedRunTerraformInit" -InvocationName "$( $MyInvocation.MyCommand.Name )"

    $convertedRunTerraformPlan = ConvertTo-Boolean $RunTerraformPlan
    _LogMessage -Level 'DEBUG' -Message "RunTerraformPlan: `"$RunTerraformPlan`" → $convertedRunTerraformPlan" -InvocationName "$( $MyInvocation.MyCommand.Name )"

    $convertedRunTerraformPlanDestroy = ConvertTo-Boolean $RunTerraformPlanDestroy
    _LogMessage -Level 'DEBUG' -Message "RunTerraformPlanDestroy: `"$RunTerraformPlanDestroy`" → $convertedRunTerraformPlanDestroy" -InvocationName "$( $MyInvocation.MyCommand.Name )"

    $convertedRunTerraformApply = ConvertTo-Boolean $RunTerraformApply
    _LogMessage -Level 'DEBUG' -Message "RunTerraformApply: `"$RunTerraformApply`" → $convertedRunTerraformApply" -InvocationName "$( $MyInvocation.MyCommand.Name )"

    $convertedRunTerraformDestroy = ConvertTo-Boolean $RunTerraformDestroy
    _LogMessage -Level 'DEBUG' -Message "RunTerraformDestroy: `"$RunTerraformDestroy`" → $convertedRunTerraformDestroy" -InvocationName "$( $MyInvocation.MyCommand.Name )"

    $convertedDeletePlanFiles = ConvertTo-Boolean $DeletePlanFiles
    _LogMessage -Level 'DEBUG' -Message "DeletePlanFiles: `"$DeletePlanFiles`" → $convertedDeletePlanFiles" -InvocationName "$( $MyInvocation.MyCommand.Name )"

    $convertedRunCheckov = ConvertTo-Boolean $RunCheckov
    _LogMessage -Level 'DEBUG' -Message "RunCheckov: `"$RunCheckov`" → $convertedRunCheckov" -InvocationName "$( $MyInvocation.MyCommand.Name )"

    $convertedCheckovSoftfail = ConvertTo-Boolean $CheckovSoftfail
    _LogMessage -Level 'DEBUG' -Message "CheckovSoftfail: `"$CheckovSoftfail`" → $convertedCheckovSoftfail" -InvocationName "$( $MyInvocation.MyCommand.Name )"


    $convertedCreateTerraformWorkspace = ConvertTo-Boolean $CreateTerraformWorkspace
    _LogMessage -Level 'DEBUG' -Message "CreateTerraformWorkspace: `"$CreateTerraformWorkspace`" → $convertedCreateTerraformWorkspace" -InvocationName "$( $MyInvocation.MyCommand.Name )"


    # ── Chicken-and-egg / mutual exclusivity checks ───────────────────────────────
    if (-not $convertedRunTerraformInit -and (
    $convertedRunTerraformPlan -or
            $convertedRunTerraformPlanDestroy -or
            $convertedRunTerraformApply -or
            $convertedRunTerraformDestroy))
    {
        $msg = 'Terraform init must be run before plan / apply / destroy operations.'
        _LogMessage -Level 'ERROR' -Message $msg -InvocationName $MyInvocation.MyCommand.Name
        throw $msg
    }

    if ($convertedRunTerraformPlan -and $convertedRunTerraformPlanDestroy)
    {
        $msg = 'Both Terraform Plan and Terraform Plan-Destroy cannot be true at the same time.'
        _LogMessage -Level 'ERROR' -Message $msg -InvocationName $MyInvocation.MyCommand.Name
        throw $msg
    }

    if ($convertedRunTerraformApply -and $convertedRunTerraformDestroy)
    {
        $msg = 'Both Terraform Apply and Terraform Destroy cannot be true at the same time.'
        _LogMessage -Level 'ERROR' -Message $msg -InvocationName $MyInvocation.MyCommand.Name
        throw $msg
    }

    if (-not $convertedRunTerraformPlan -and $convertedRunTerraformApply)
    {
        $msg = 'You must run terraform **plan** together with **apply** when using this script.'
        _LogMessage -Level 'ERROR' -Message $msg -InvocationName $MyInvocation.MyCommand.Name
        throw $msg
    }

    if (-not $convertedRunTerraformPlanDestroy -and $convertedRunTerraformDestroy)
    {
        $msg = 'You must run terraform **plan destroy** together with **destroy** when using this script.'
        _LogMessage -Level 'ERROR' -Message $msg -InvocationName $MyInvocation.MyCommand.Name
        throw $msg
    }

    $processedStacks = @()
    try
    {

        if ($convertedAttemptAzureLogin)
        {

            Connect-AzureCli `
            -UseClientSecret $convertedUseAzureClientSecretLogin `
            -UseOidc $convertedUseAzureOidcLogin `
            -UseUserDeviceCode $convertedUseAzureUserLogin `
            -UseManagedIdentity $convertedUseAzureManagedIdentityLogin
        }

        $stackFolders = Get-TerraformStackFolders `
                    -CodeRoot $fullTerraformCodePath `
                    -StacksToRun $TerraformStackToRun

        # ──────────────────── REVERSE execution order for destroys ────────────────
        if ($convertedRunTerraformPlanDestroy -or $convertedRunTerraformDestroy)
        {

            # 1. sort numerically by the leading digits in the folder name
            $stackFolders = $stackFolders |
                    Sort-Object {
                        # “C:\...\1_network”  →  1
                        [int](
                        (($_ -split '[\\/]')[-1]) -replace '^(\d+)_.*', '$1'
                        )
                    }

            # 2. reverse   (static .NET call – do **not** pipe this!)
            [array]::Reverse($stackFolders)
        }

        foreach ($folder in $stackFolders)
        {

            $processedStacks += $folder

            # terraform fmt – always safe
            Invoke-TerraformFmtCheck  -CodePath $folder

            # ── INIT ──────────────────────────────────────────────────────────────
            if ($convertedRunTerraformInit)
            {
                Invoke-TerraformInit -CodePath $folder -InitArgs '-input=false','-upgrade=true'
            }

            # workspace (needs an init first)
            if ($convertedRunTerraformInit -and
                    $convertedCreateTerraformWorkspace -and
                    -not [string]::IsNullOrWhiteSpace($TerraformWorkspace))
            {

                Invoke-TerraformWorkspaceSelect -CodePath $folder -WorkspaceName $TerraformWorkspace
            }

            # ── VALIDATE ──────────────────────────────────────────────────────────
            if ($convertedRunTerraformInit)
            {
                Invoke-TerraformValidate -CodePath $folder
            }

            # ── PLAN / PLAN-DESTROY ───────────────────────────────────────────────
            if ($convertedRunTerraformPlan)
            {
                Invoke-TerraformPlan -CodePath $folder -PlanArgs $TerraformPlanExtraArgs -PlanFile $TerraformPlanFileName
            }
            elseif ($convertedRunTerraformPlanDestroy)
            {
                Invoke-TerraformPlanDestroy -CodePath $folder -PlanArgs $TerraformPlanDestroyExtraArgs -PlanFile $TerraformDestroyPlanFileName
            }

            # JSON + Checkov need a plan file
            if ($convertedRunTerraformPlan -or $convertedRunTerraformPlanDestroy)
            {

                if ($convertedRunTerraformPlan)
                {
                    $TfPlanFileName = $TerraformPlanFileName
                }

                if ($convertedRunTerraformPlanDestroy)
                {
                    $TfPlanFileName = $TerraformDestroyPlanFileName
                }

                Convert-TerraformPlanToJson -CodePath $folder -PlanFile $TfPlanFileName

                if ($convertedRunCheckov -and $convertedRunTerraformPlan)
                {
                    Invoke-Checkov `
                -CodePath           $folder `
                -CheckovSkipChecks  $CheckovSkipCheck `
                -SoftFail:          $convertedCheckovSoftfail
                }
            }

            # ── APPLY / DESTROY ───────────────────────────────────────────────────
            if ($convertedRunTerraformApply)
            {
                Invoke-TerraformApply -CodePath $folder -SkipApprove -ApplyArgs $TerraformApplyExtraArgs
            }
            elseif ($convertedRunTerraformDestroy)
            {
                Invoke-TerraformDestroy -CodePath $folder -SkipApprove -DestroyArgs $TerraformDestroyExtraArgs
            }
        }

    }
    catch
    {
        _LogMessage -Level 'ERROR' -Message "Script execution error: $( $_.Exception.Message )" -InvocationName $MyInvocation.MyCommand.Name
        throw
    }
}
catch
{
    _LogMessage -Level "ERROR" -Message "Error: $( $_.Exception.Message )" -InvocationName "$( $MyInvocation.MyCommand.Name )"
    exit 1
}

finally
{
    if ($convertedDeletePlanFiles)
    {

        $patterns = @(
            $TfPlanFileName,
            "${TfPlanFileName}.json",
            "${TfPlanFileName}-destroy.tfplan",
            "${TfPlanFileName}-destroy.tfplan.json"
        )

        foreach ($folder in $processedStacks)
        {
            foreach ($pat in $patterns)
            {

                $file = Join-Path $folder $pat
                if (Test-Path $file)
                {
                    try
                    {
                        Remove-Item $file -Force -ErrorAction Stop
                        _LogMessage -Level DEBUG -Message "Deleted $file" `
                                    -InvocationName $MyInvocation.MyCommand.Name
                    }
                    catch
                    {
                        _LogMessage -Level WARN -Message "Failed to delete $file – $( $_.Exception.Message )" `
                                    -InvocationName $MyInvocation.MyCommand.Name
                    }
                }
                else
                {
                    _LogMessage -Level DEBUG -Message "No file to delete: $file" `
                                -InvocationName $MyInvocation.MyCommand.Name
                }
            }
        }
    }
    else
    {
        _LogMessage -Level DEBUG -Message 'DeletePlanFiles is false – leaving plan files in place.' `
                    -InvocationName $MyInvocation.MyCommand.Name
    }

    if ($convertedUseAzureUserLogin)
    {
        Disconnect-AzureCli -IsUserDeviceLogin $true
    }
    else
    {
        Disconnect-AzureCli -IsUserDeviceLogin $false
    }

    $Env:TF_LOG = $null
    Set-Location $currentWorkingDirectory
}

