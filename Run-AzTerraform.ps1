param (
    [string]$RunTerraformInit = "true",
    [string]$RunTerraformPlan = "true",
    [string]$RunTerraformPlanDestroy = "false",
    [string]$RunTerraformApply = "false",
    [string]$RunTerraformDestroy = "false",
    [bool]$DebugMode = $false,
    [string]$DeletePlanFiles = "true",
    [string]$TerraformVersion = "latest",
    [string]$RunCheckov = "false",

    [Parameter(Mandatory = $true)]
    [string]$TerraformCodeLocation,

    [Parameter(Mandatory = $true)]
    [string]$BackendStorageSubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$BackendStorageAccountName,

    [Parameter(Mandatory = $true)]
    [string]$BackendStorageAccountRgName,

    [Parameter(Mandatory = $true)]
    [string]$BackendStorageAccountBlobContainerName,

    [Parameter(Mandatory = $true)]
    [string]$BackendStorageAccountBlobStatefileName
)

try
{
    $ErrorActionPreference = 'Stop'
    $CurrentWorkingDirectory = (Get-Location).path
    $TerraformCodePath = Join-Path -Path $CurrentWorkingDirectory -ChildPath $TerraformCodeLocation

    # Enable debug mode if DebugMode is set to $true
    if ($DebugMode)
    {
        $DebugPreference = "Continue"
        $Env:TF_LOG = "DEBUG"
    }
    else
    {
        $DebugPreference = "SilentlyContinue"
    }



    function Invoke-TerraformInit
    {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [string]$BackendStorageSubscriptionId,

            [Parameter(Mandatory = $true)]
            [string]$BackendStorageAccountName,

            [Parameter(Mandatory = $true)]
            [string]$WorkingDirectory
        )

        Begin {

            # Initial setup and variable declarations
            Write-Debug "[$( $MyInvocation.MyCommand.Name )] Debug: Initializing Terraform..."
            $BackendStorageAccountBlobContainerName = $BackendStorageAccountBlobContainerName
            $BackendStorageAccountRgName = $BackendStorageAccountRgName

            Assert-AzStorageContainer `
                -StorageAccountSubscription $BackendStorageSubscriptionId `
                -StorageAccountName $BackendStorageAccountName `
                -ResourceGroupName $BackendStorageAccountRgName `
                -ContainerName $BackendStorageAccountBlobContainerName
        }

        Process {
            try
            {

                $terraformCache = Join-Path -Path $WorkingDirectory -ChildPath ".terraform"

                if (Test-Path -Path $terraformCache)
                {
                    try
                    {
                        Write-Debug "[$( $MyInvocation.MyCommand.Name )] Debug: Attempting to remove : $terraformCache"
                        Remove-Item -Force $terraformCache -Recurse -Confirm:$false
                    }
                    catch
                    {
                        throw "[$( $MyInvocation.MyCommand.Name )] Error: Failed to remove .terraform folder: $_"
                        exit 1
                    }
                }

                # Change to the specified working directory
                Set-Location -Path $WorkingDirectory

                # Construct the backend config parameters
                $backendConfigParams = @(
                    "-backend-config=subscription_id=$BackendStorageSubscriptionId",
                    "-backend-config=storage_account_name=$BackendStorageAccountName",
                    "-backend-config=resource_group_name=$BackendStorageAccountRgName",
                    "-backend-config=container_name=$BackendStorageAccountBlobContainerName"
                    "-backend-config=key=$BackendStorageAccountBlobStatefileName"
                )

                Write-Debug "[$( $MyInvocation.MyCommand.Name )] Debug: Backend config params are: $backendConfigParams"

                # Run terraform init with the constructed parameters
                terraform init @backendConfigParams | Out-Host
                Write-Debug "[$( $MyInvocation.MyCommand.Name )] Debug: Last exit code is $LASTEXITCODE"
                # Check if terraform init was successful
                if ($LASTEXITCODE -ne 0)
                {
                    throw "[$( $MyInvocation.MyCommand.Name )] Error: Terraform init failed with exit code $LASTEXITCODE"
                    exit 1
                }
            }
            catch
            {
                throw "[$( $MyInvocation.MyCommand.Name )] Error: Terraform init failed with exception: $_"
                exit 1
            }
        }

        End {
            Write-Debug "[$( $MyInvocation.MyCommand.Name )] Debug: Terraform initialization completed."
        }
    }


    function Invoke-TerraformPlan
    {
        [CmdletBinding()]
        param (
            [string]$WorkingDirectory = $WorkingDirectory,
            [bool]$RunTerraformPlan = $true
        )

        Begin {
            Write-Debug "[$( $MyInvocation.MyCommand.Name )] Begin: Initializing Terraform Plan in $WorkingDirectory"
        }

        Process {
            if ($RunTerraformPlan)
            {
                Write-Host "[$( $MyInvocation.MyCommand.Name )] Info: Running Terraform Plan in $WorkingDirectory" -ForegroundColor Green
                try
                {
                    Set-Location -Path $WorkingDirectory
                    terraform plan -out tfplan.plan | Out-Host

                    if (Test-Path tfplan.plan)
                    {
                        terraform show -json tfplan.plan | Tee-Object -FilePath tfplan.json | Out-Null
                    }
                    else
                    {
                        throw "[$( $MyInvocation.MyCommand.Name )] Error: Terraform plan file not created"
                        exit 1
                    }
                }
                catch
                {
                    throw "[$( $MyInvocation.MyCommand.Name )] Error encountered during Terraform plan: $_"
                    exit 1
                }
            }
        }

        End {
            Write-Debug "[$( $MyInvocation.MyCommand.Name )] End: Completed Terraform Plan execution"
        }
    }



    # Function to execute Terraform plan for destroy
    function Invoke-TerraformPlanDestroy
    {
        [CmdletBinding()]
        param (
            [string]$WorkingDirectory = $WorkingDirectory,
            [bool]$RunTerraformPlanDestroy = $true
        )

        Begin {
            Write-Debug "[$( $MyInvocation.MyCommand.Name )] Begin: Preparing to execute Terraform Plan Destroy in $WorkingDirectory"
        }

        Process {
            if ($RunTerraformPlanDestroy)
            {
                try
                {
                    Write-Host "[$( $MyInvocation.MyCommand.Name )] Info: Running Terraform Plan Destroy in $WorkingDirectory" -ForegroundColor Yellow
                    Set-Location -Path $WorkingDirectory
                    terraform plan -destroy -out tfplan.plan | Out-Host

                    if (Test-Path tfplan.plan)
                    {
                        terraform show -json tfplan.plan | Tee-Object -FilePath tfplan.json | Out-Null
                    }
                    else
                    {
                        throw "[$( $MyInvocation.MyCommand.Name )] Error: Terraform plan file not created"
                        exit 1
                    }
                }
                catch
                {
                    throw  "[$( $MyInvocation.MyCommand.Name )] Error encountered during Terraform Plan Destroy: $_"
                    exit 1
                }
            }
            else
            {
                throw  "[$( $MyInvocation.MyCommand.Name )] Error encountered during Terraform Plan Destroy or internal script error occured: $_"
                exit 1
            }
        }

        End {
            Write-Debug "[$( $MyInvocation.MyCommand.Name )] End: Completed execution of Terraform Plan Destroy"
        }
    }

    # Function to execute Terraform apply
    function Invoke-TerraformApply
    {
        if ($RunTerraformApply -eq $true)
        {
            try
            {
                Write-Host "[$( $MyInvocation.MyCommand.Name )] Info: Running Terraform Apply in $WorkingDirectory" -ForegroundColor Yellow
                if (Test-Path tfplan.plan)
                {
                    terraform apply -auto-approve tfplan.plan | Out-Host
                }
                else
                {
                    throw "[$( $MyInvocation.MyCommand.Name )] Error: Terraform plan file not present for terraform apply"
                    return $false
                }
            }
            catch
            {
                throw "[$( $MyInvocation.MyCommand.Name )] Error: Terraform Apply failed"
                return $false
            }
        }
    }

    # Function to execute Terraform destroy
    function Invoke-TerraformDestroy
    {
        if ($RunTerraformDestroy -eq $true)
        {
            try
            {
                Write-Host "[$( $MyInvocation.MyCommand.Name )] Info: Running Terraform Destroy in $WorkingDirectory" -ForegroundColor Yellow
                if (Test-Path tfplan.plan)
                {
                    terraform apply -auto-approve tfplan.plan | Out-Host
                }
                else
                {
                    throw "[$( $MyInvocation.MyCommand.Name )] Error: Terraform plan file not present for terraform destroy"
                    return $false
                }
            }
            catch
            {
                throw "[$( $MyInvocation.MyCommand.Name )] Error: Terraform Destroy failed"
                return $false
            }
        }
    }

    # Convert string parameters to boolean
    $ConvertedRunTerraformInit = ConvertTo-Boolean $RunTerraformInit
    $ConvertedRunTerraformPlan = ConvertTo-Boolean $RunTerraformPlan
    $ConvertedRunTerraformPlanDestroy = ConvertTo-Boolean $RunTerraformPlanDestroy
    $ConvertedRunTerraformApply = ConvertTo-Boolean $RunTerraformApply
    $ConvertedRunTerraformDestroy = ConvertTo-Boolean $RunTerraformDestroy
    $ConvertedDeletePlanFiles = ConvertTo-Boolean $DeletePlanFiles
    $ConvertedRunCheckov = ConvertTo-Boolean $RunCheckov


    # Diagnostic output
    Write-Debug "[$( $MyInvocation.MyCommand.Name )] Debug: ConvertedRunTerraformInit: $ConvertedRunTerraformInit"
    Write-Debug "[$( $MyInvocation.MyCommand.Name )] Debug: ConvertedRunTerraformPlan: $ConvertedRunTerraformPlan"
    Write-Debug "[$( $MyInvocation.MyCommand.Name )] Debug: ConvertedRunTerraformPlanDestroy: $ConvertedRunTerraformPlanDestroy"
    Write-Debug "[$( $MyInvocation.MyCommand.Name )] Debug: ConvertedRunTerraformApply: $ConvertedRunTerraformApply"
    Write-Debug "[$( $MyInvocation.MyCommand.Name )] Debug: ConvertedRunTerraformDestroy: $ConvertedRunTerraformDestroy"
    Write-Debug "[$( $MyInvocation.MyCommand.Name )] Debug: DebugMode: $DebugMode"
    Write-Debug "[$( $MyInvocation.MyCommand.Name )] Debug: ConvertedDeletePlanFiles: $ConvertedDeletePlanFiles"


    # Chicken and Egg checker
    if (-not$ConvertedRunTerraformInit -and ($ConvertedRunTerraformPlan -or $ConvertedRunTerraformPlanDestroy -or $ConvertedRunTerraformApply -or $ConvertedRunTerraformDestroy))
    {
        throw "[$( $MyInvocation.MyCommand.Name )] Error: Terraform init must be run before executing plan, plan destroy, apply, or destroy commands."
        exit 1
    }

    if ($ConvertedRunTerraformPlan -eq $true -and $ConvertedRunTerraformPlanDestroy -eq $true)
    {
        throw "[$( $MyInvocation.MyCommand.Name )] Error: Both Terraform Plan and Terraform Plan Destroy cannot be true at the same time"
        exit 1
    }

    if ($ConvertedRunTerraformApply -eq $true -and $ConvertedRunTerraformDestroy -eq $true)
    {
        throw "[$( $MyInvocation.MyCommand.Name )] Error: Both Terraform Apply and Terraform Destroy cannot be true at the same time"
        exit 1
    }

    if ($ConvertedRunTerraformPlan -eq $false -and $ConvertedRunTerraformApply -eq $true)
    {
        throw "[$( $MyInvocation.MyCommand.Name )] Error: You must run terraform plan and terraform apply together to use this script"
        exit 1
    }

    if ($ConvertedRunTerraformPlanDestroy -eq $false -and $ConvertedRunTerraformDestroy -eq $true)
    {
        throw "[$( $MyInvocation.MyCommand.Name )] Error: You must run terraform plan destroy and terraform destroy together to use this script"
        exit 1
    }

    try
    {
        # Initial Terraform setup
        Test-TenvExists
        Test-TerraformExists

        $WorkingDirectory = $TerraformCodePath

        # Terraform Init
        if ($ConvertedRunTerraformInit)
        {
            Invoke-TerraformInit `
                -WorkingDirectory $WorkingDirectory `
                -BackendStorageAccountName $BackendStorageAccountName `
                -BackendStorageSubscriptionId $BackendStorageSubscriptionId
            $InvokeTerraformInitSuccessful = ($LASTEXITCODE -eq 0)
        }
        else
        {
            throw "[$( $MyInvocation.MyCommand.Name )] Error: Terraform initialization failed."
        }

        # Conditional execution based on parameters
        if ($InvokeTerraformInitSuccessful -and $ConvertedRunTerraformPlan -and -not$ConvertedRunTerraformPlanDestroyonvRunTerraformPlanDestroy)
        {
            Invoke-TerraformPlan -WorkingDirectory $WorkingDirectory
            $InvokeTerraformPlanSuccessful = ($LASTEXITCODE -eq 0)

            if ($ConvertedRunCheckov -and $InvokeTerraformPlanSuccessful)
            {
                Run-Checkov -WorkingDirectory $WorkingDirectory
            }
        }

        if ($InvokeTerraformInitSuccessful -and $ConvertedRunTerraformPlanDestroy -and -not$ConvertedRunTerraformPlan)
        {
            Invoke-TerraformPlanDestroy -WorkingDirectory $WorkingDirectory
            $InvokeTerraformPlanDestroySuccessful = ($LASTEXITCODE -eq 0)
        }

        if ($InvokeTerraformInitSuccessful -and $ConvertedRunTerraformApply -and $InvokeTerraformPlanSuccessful)
        {
            Invoke-TerraformApply
            $InvokeTerraformApplySuccessful = ($LASTEXITCODE -eq 0)
            if (-not$InvokeTerraformApplySuccessful)
            {
                throw "[$( $MyInvocation.MyCommand.Name )] Error: An error occured during terraform apply command"
                exit 1
            }
        }

        if ($ConvertedRunTerraformDestroy -and $InvokeTerraformPlanDestroySuccessful)
        {
            Invoke-TerraformDestroy
            $InvokeTerraformDestroySuccessful = ($LASTEXITCODE -eq 0)

            if (-not$InvokeTerraformDestroySuccessful)
            {
                throw "[$( $MyInvocation.MyCommand.Name )] Error: An error occured during terraform destroy command"
                exit 1
            }
        }
        try {
            # ── Terraform init ───────────────────────────────────────────────────────
            if ($convertedRunTerraformInit) {
                _LogMessage -Level 'INFO'  -Message 'Running terraform init…' -InvocationName $MyInvocation.MyCommand.Name

                Invoke-TerraformInit `
            -WorkingDirectory             $WorkingDirectory `
            -BackendStorageAccountName    $BackendStorageAccountName `
            -BackendStorageSubscriptionId $BackendStorageSubscriptionId

                $invokeTerraformInitSuccessful = ($LASTEXITCODE -eq 0)
                if (-not $invokeTerraformInitSuccessful) {
                    _LogMessage -Level 'ERROR' -Message 'terraform init failed.' -InvocationName $MyInvocation.MyCommand.Name
                    throw 'terraform init failed.'
                }
            }
            else {
                _LogMessage -Level 'ERROR' -Message 'Terraform init flag is false – cannot continue.' -InvocationName $MyInvocation.MyCommand.Name
                throw 'Terraform initialisation was skipped.'
            }

            # ── Terraform plan ───────────────────────────────────────────────────────
            if ($invokeTerraformInitSuccessful -and $convertedRunTerraformPlan -and -not $convertedRunTerraformPlanDestroy) {
                _LogMessage -Level 'INFO' -Message 'Running terraform plan…' -InvocationName $MyInvocation.MyCommand.Name

                Invoke-TerraformPlan -WorkingDirectory $WorkingDirectory
                $invokeTerraformPlanSuccessful = ($LASTEXITCODE -eq 0)

                if (-not $invokeTerraformPlanSuccessful) {
                    _LogMessage -Level 'ERROR' -Message 'terraform plan failed.' -InvocationName $MyInvocation.MyCommand.Name
                    throw 'terraform plan failed.'
                }

                if ($convertedRunCheckov) {
                    _LogMessage -Level 'INFO' -Message 'Running Checkov scan…' -InvocationName $MyInvocation.MyCommand.Name
                    Invoke-Checkov -CodeLocation $WorkingDirectory
                }
            }

            # ── Terraform plan destroy ───────────────────────────────────────────────
            if ($invokeTerraformInitSuccessful -and $convertedRunTerraformPlanDestroy -and -not $convertedRunTerraformPlan) {
                _LogMessage -Level 'INFO' -Message 'Running terraform plan destroy…' -InvocationName $MyInvocation.MyCommand.Name

                Invoke-TerraformPlanDestroy -WorkingDirectory $WorkingDirectory
                $invokeTerraformPlanDestroySuccessful = ($LASTEXITCODE -eq 0)

                if (-not $invokeTerraformPlanDestroySuccessful) {
                    _LogMessage -Level 'ERROR' -Message 'terraform plan destroy failed.' -InvocationName $MyInvocation.MyCommand.Name
                    throw 'terraform plan destroy failed.'
                }
            }

            # ── Terraform apply ──────────────────────────────────────────────────────
            if ($invokeTerraformInitSuccessful -and $convertedRunTerraformApply -and $invokeTerraformPlanSuccessful) {
                _LogMessage -Level 'INFO' -Message 'Running terraform apply…' -InvocationName $MyInvocation.MyCommand.Name

                Invoke-TerraformApply
                $invokeTerraformApplySuccessful = ($LASTEXITCODE -eq 0)

                if (-not $invokeTerraformApplySuccessful) {
                    _LogMessage -Level 'ERROR' -Message 'terraform apply failed.' -InvocationName $MyInvocation.MyCommand.Name
                    throw 'terraform apply failed.'
                }
            }

            # ── Terraform destroy ────────────────────────────────────────────────────
            if ($convertedRunTerraformDestroy -and $invokeTerraformPlanDestroySuccessful) {
                _LogMessage -Level 'INFO' -Message 'Running terraform destroy…' -InvocationName $MyInvocation.MyCommand.Name

                Invoke-TerraformDestroy
                $invokeTerraformDestroySuccessful = ($LASTEXITCODE -eq 0)

                if (-not $invokeTerraformDestroySuccessful) {
                    _LogMessage -Level 'ERROR' -Message 'terraform destroy failed.' -InvocationName $MyInvocation.MyCommand.Name
                    throw 'terraform destroy failed.'
                }
            }
        }
        catch {
            _LogMessage -Level 'ERROR' -Message "Script execution error: $($_.Exception.Message)" -InvocationName $MyInvocation.MyCommand.Name
            throw    # let the error propagate to any higher-level handler
        }

    }
    catch
    {
        throw "[$( $MyInvocation.MyCommand.Name )] Error: in script execution: $_"
        exit 1
    }

}
catch
{
    throw "[$( $MyInvocation.MyCommand.Name )] Error: An error has occured in the script:  $_"
    exit 1
}

finally
{
    if ($DeletePlanFiles -eq $true)
    {
        $planFile = "tfplan.plan"
        if (Test-Path $planFile)
        {
            Remove-Item -Path $planFile -Force -ErrorAction Stop
            Write-Debug "[$( $MyInvocation.MyCommand.Name )] Debug: Deleted $planFile"
        }
        $planJson = "tfplan.json"
        if (Test-Path $planJson)
        {
            Remove-Item -Path $planJson -Force -ErrorAction Stop
            Write-Debug "[$( $MyInvocation.MyCommand.Name )] Debug: Deleted $planJson"
        }
    }
    Set-Location $CurrentWorkingDirectory
}


