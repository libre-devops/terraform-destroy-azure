# Run 'terraform validate'
function Invoke-TerraformValidate
{
    param (
        [string]$CodePath
    )

    if (-not (Test-Path $CodePath))
    {
        _LogMessage -Level "ERROR" -Message "Terraform code not found: $TemplatePath" -InvocationName "$( $MyInvocation.MyCommand.Name )"
        throw "Terraform code not found: $CodePath"
    }

    _LogMessage -Level "INFO" -Message "Validating Terraform: $CodePath" -InvocationName "$( $MyInvocation.MyCommand.Name )"
    Set-Location $CodePath
    & terraform validate
}

# Run 'terraform validate'
function Invoke-TerraformFmtCheck
{
    param (
        [string]$CodePath
    )

    if (-not (Test-Path $CodePath))
    {
        _LogMessage -Level "ERROR" -Message "Terraform code not found: $TemplatePath" -InvocationName "$( $MyInvocation.MyCommand.Name )"
        throw "Terraform code not found: $CodePath"
    }

    _LogMessage -Level "INFO" -Message "Validating Terraform: $CodePath" -InvocationName "$( $MyInvocation.MyCommand.Name )"
    Set-Location $CodePath
    & terraform fmt -check
}

function Get-TerraformStackFolders
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]  $CodeRoot,

        [Parameter(Mandatory)]
        [string[]]$StacksToRun
    )

    #─────────────────────────────────── pre-checks ────────────────────────────
    if (-not (Test-Path $CodeRoot))
    {
        _LogMessage -Level 'ERROR' -Message "Code root not found: $CodeRoot" `
                    -InvocationName $MyInvocation.MyCommand.Name
        throw "Code root not found: $CodeRoot"
    }

    $allDirs = Get-ChildItem -Path $CodeRoot -Directory |
            Where-Object { $_.Name -match '^\d+_.+' }

    if (-not $allDirs)
    {
        _LogMessage -Level 'ERROR' -Message "No stack folders found underneath $CodeRoot" `
                    -InvocationName $MyInvocation.MyCommand.Name
        throw "No stack folders found underneath $CodeRoot"
    }

    #──────────────────────────── discover / index stacks ─────────────────────
    $stackLookup = @{ }
    foreach ($dir in $allDirs)
    {
        if ($dir.Name -match '^(?<order>\d+)_(?<name>.+)$')
        {
            $stackLookup[$matches.name.ToLower()] = @{
                Path = $dir.FullName
                Order = [int]$matches.order
            }
        }
    }

    #──────────────────────────── argument sanitisation ────────────────────────
    $requested = @(
    $StacksToRun |
            ForEach-Object { $_.Trim() } |
            Where-Object  { $_ }         # drop empty entries
    )

    if ($requested -contains 'all' -and $requested.Count -gt 1)
    {
        _LogMessage -Level 'WARN' `
            -Message "'all' cannot be combined with explicit stack names – ignoring 'all' and using the named stacks only." `
            -InvocationName $MyInvocation.MyCommand.Name

        $requested = $requested | Where-Object { $_.ToLower() -ne 'all' }
    }

    #──────────────────────────── resolve stack list ───────────────────────────
    $result = [System.Collections.Generic.List[string]]::new()

    if (($requested.Count -eq 1) -and ($requested[0].ToLower() -eq 'all'))
    {
        _LogMessage -Level 'INFO' -Message 'Running ALL stacks (numeric order)' `
                    -InvocationName $MyInvocation.MyCommand.Name

        $stackLookup.GetEnumerator() |
                Sort-Object { $_.Value.Order } |
                ForEach-Object { [void]$result.Add($_.Value.Path) }
    }
    else
    {
        foreach ($stack in $requested)
        {
            $key = $stack.ToLower()
            if (-not $stackLookup.ContainsKey($key))
            {
                _LogMessage -Level 'ERROR' -Message "Stack '$stack' not found under $CodeRoot" `
                            -InvocationName $MyInvocation.MyCommand.Name
                throw "Stack '$stack' not found under $CodeRoot"
            }
            [void]$result.Add($stackLookup[$key].Path)
        }
    }

    #────────────────────────────────── debug log ──────────────────────────────
    _LogMessage -Level 'DEBUG' `
        -Message "Stack execution order → $( $result -join ', ' )" `
        -InvocationName $MyInvocation.MyCommand.Name

    return $result
}

###############################################################################
# Run `terraform init`
###############################################################################
function Invoke-TerraformInit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CodePath,

    # Optional additional arguments, e.g. "-backend-config=xyz.tfbackend"
        [string[]]$InitArgs = @()
    )

    $inv = $MyInvocation.MyCommand.Name
    $orig = Get-Location

    try {
        if (-not (Test-Path $CodePath)) {
            _LogMessage -Level 'ERROR' -Message "Terraform code not found: $CodePath" -InvocationName $inv
            throw "Terraform code not found: $CodePath"
        }

        _LogMessage -Level 'INFO'  -Message "Running *terraform init* in: $CodePath" -InvocationName $inv
        Set-Location $CodePath

        & terraform init @InitArgs
        $code = $LASTEXITCODE
        _LogMessage -Level 'DEBUG' -Message "terraform init exit-code: $code" -InvocationName $inv

        if ($code -ne 0) {
            throw "terraform init failed (exit $code)."
        }
    }
    catch {
        _LogMessage -Level 'ERROR' -Message $_.Exception.Message -InvocationName $inv
        throw
    }
    finally {
        Set-Location $orig
    }
}

###############################################################################
# Run `terraform workspace select -or-create=true <name>`
###############################################################################
function Invoke-TerraformWorkspaceSelect {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CodePath,
        [Parameter(Mandatory)][string]$WorkspaceName
    )

    $inv  = $MyInvocation.MyCommand.Name
    $orig = Get-Location

    try {
        if (-not (Test-Path $CodePath)) {
            _LogMessage -Level 'ERROR' -Message "Terraform code not found: $CodePath" -InvocationName $inv
            throw "Terraform code not found: $CodePath"
        }

        _LogMessage -Level 'INFO' -Message "Selecting workspace '$WorkspaceName' (auto-create) in $CodePath" -InvocationName $inv
        Set-Location $CodePath

        & terraform workspace select -or-create=true $WorkspaceName
        $code = $LASTEXITCODE
        _LogMessage -Level 'DEBUG' -Message "terraform workspace select exit-code: $code" -InvocationName $inv

        if ($code -ne 0) {
            throw "workspace selection failed (exit $code)."
        }
    }
    catch {
        _LogMessage -Level 'ERROR' -Message $_.Exception.Message -InvocationName $inv
        throw
    }
    finally {
        Set-Location $orig
    }
}

# Export (add this alongside your other Export-ModuleMember line if desired)
Export-ModuleMember -Function Invoke-TerraformValidate, Invoke-TerraformFmtCheck, Get-TerraformStackFolders, Invoke-TerraformInit, Invoke-TerraformWorkspaceSelect

