# Tests/Utils.Tests.ps1
# -------------------------------------------------------------
# Unit tests for helper functions in Utils.psm1
# (No assertions on _LogMessage – only on observable behaviour)
# -------------------------------------------------------------

# 0 ── Provide a no-op logger so helpers don’t break if they call it
function global:_LogMessage { }

# 1 ── Import module under test (after the stub!)
Import-Module "$PSScriptRoot/../PowerShellModules/Utils.psm1" -Force

# ──────────────────────────────────────────────────────────────
Describe 'Test-PathExists' {

    BeforeAll {
        $fileGood = New-Item -Path (Join-Path $TestDrive 'good.txt') -ItemType File -Force
        $fileBad  = Join-Path $TestDrive 'missing.txt'
    }

    It 'runs without throwing regardless of mix of good / bad paths' {
        { Test-PathExists -Paths @($fileGood.FullName, $fileBad) } | Should -Not -Throw
    }
}

# ──────────────────────────────────────────────────────────────
Describe 'Get-InstalledPrograms' {

    It 'runs without throwing when some programs are missing' {
        # Fake Get-Command results used inside the helper
        Mock Get-Command -MockWith {
            if ($Name -eq 'cmd') { [pscustomobject]@{ Source = 'C:\fake\cmd.exe' } }
            else                 { $null }
        }

        { Get-InstalledPrograms -Programs @('cmd','definitelyNotThere') } | Should -Not -Throw
    }
}

# ──────────────────────────────────────────────────────────────
Describe 'ConvertTo-Boolean' {
    It '"true"  returns $true'  { ConvertTo-Boolean 'true'  | Should -BeTrue  }
    It '"false" returns $false' { ConvertTo-Boolean 'false' | Should -BeFalse }
}

