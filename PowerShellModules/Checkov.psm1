function Invoke-Checkov {
    [CmdletBinding()]
    param (
        [string]$PlanJsonFile = 'tfplan.json',

        [Parameter(Mandatory)]
        [string]$CodeLocation,

        [string]$CheckovSkipChecks = ''
    )

    # ── 1  Locate Checkov ────────────────────────────────────────────────────────
    try {
        $checkovPath = Get-Command checkov -ErrorAction Stop
        _LogMessage -Level 'INFO' -Message "Checkov found at: $($checkovPath.Source) – running scan..." -InvocationName "$($MyInvocation.MyCommand.Name)"
    }
    catch {
        _LogMessage -Level 'ERROR' -Message 'Checkov is not installed or not in PATH.' -InvocationName "$($MyInvocation.MyCommand.Name)"
        throw 'Checkov is not installed or not in PATH.'
    }

    # ── 2  Build --skip-check argument (if any) ──────────────────────────────────
    $skipArgument = @()           # default = nothing to skip
    $trimmed      = $CheckovSkipChecks.Trim()

    # treat '', "" or an empty string as "no skips"
    if ($trimmed -and $trimmed -ne "''" -and $trimmed -ne '""') {
        $checks = ($trimmed -split ',') |
                ForEach-Object { $_.Trim() } |
                Where-Object  { $_ }

        if ($checks.Count) {
            $formattedList = ($checks | ForEach-Object { " - $_" }) -join "`n"
            _LogMessage -Level 'INFO' -Message "The following tests are being skipped:`n$formattedList" -InvocationName "$($MyInvocation.MyCommand.Name)"
            $skipArgument = @('--skip-check', ($checks -join ','))
        }
        else {
            _LogMessage -Level 'INFO' -Message 'No tests are being skipped.' -InvocationName "$($MyInvocation.MyCommand.Name)"
        }
    }
    else {
        _LogMessage -Level 'INFO' -Message 'No tests are being skipped.' -InvocationName "$($MyInvocation.MyCommand.Name)"
    }

    # ── 3  Compose full argument list & run Checkov ──────────────────────────────
    $checkovArgs = @(
        '-s'
        '-f' , $PlanJsonFile
        '--repo-root-for-plan-enrichment', $CodeLocation
    ) + $skipArgument

    _LogMessage -Level 'INFO' -Message "Executing Checkov with args: $($checkovArgs -join ' ')" -InvocationName "$($MyInvocation.MyCommand.Name)"

    & checkov @checkovArgs
}

Export-ModuleMember -Function Invoke-Checkov
