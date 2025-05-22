# Tests/Get-TerraformStackFolders.Tests.ps1
# ---------------------------------------------------------------------------
# Verifies the behaviour of Get-TerraformStackFolders in the Terraform module
# ---------------------------------------------------------------------------

# ── Arrange: import module under test and stub logger ────────────────────────
Import-Module "$PSScriptRoot/../PowerShellModules/Terraform.psm1" -Force


function _LogMessage { }   # isolate tests from real logger

Describe 'Get-TerraformStackFolders' {

    # Build a throw-away fake terraform hierarchy in Pester’s $TestDrive
    BeforeAll {
        $CodeRoot = Join-Path $TestDrive 'terraform'
        New-Item -ItemType Directory -Path $CodeRoot           | Out-Null
        foreach ($dir in '0_rg','1_network','2_sql') {
            New-Item -ItemType Directory -Path (Join-Path $CodeRoot $dir) | Out-Null
        }
    }

    Context 'keyword "all"' {

        It 'returns every stack in numeric order when only "all" is requested' {
            $folders = Get-TerraformStackFolders -CodeRoot $CodeRoot -StacksToRun 'all'

            $folders | Split-Path -Leaf | Should -BeExactly @('0_rg','1_network','2_sql')
        }

        It 'ignores "all" when combined with explicit names' {
            $folders = Get-TerraformStackFolders -CodeRoot $CodeRoot `
                                                 -StacksToRun @('all','rg','network')

            $folders | Split-Path -Leaf | Should -BeExactly @('0_rg','1_network')
        }
    }

    Context 'explicit list behaviour' {

        It 'returns a single stack folder when one name is supplied' {
            $folders = Get-TerraformStackFolders -CodeRoot $CodeRoot -StacksToRun 'network'

            $folders | Split-Path -Leaf | Should -BeExactly @('1_network')
        }

        It 'honours caller-specified order for multiple stacks' {
            $folders = Get-TerraformStackFolders -CodeRoot $CodeRoot `
                                                 -StacksToRun @('network','rg')

            $folders | Split-Path -Leaf | Should -BeExactly @('1_network','0_rg')
        }
    }

    Context 'error handling' {

        It 'throws when a requested stack does not exist' {
            { Get-TerraformStackFolders -CodeRoot $CodeRoot -StacksToRun 'doesNotExist' } |
                    Should -Throw
        }
    }
}
