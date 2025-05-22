Import-Module "$PSScriptRoot/../PowerShellModules/Pester.psm1"
. "$PSScriptRoot\_Bootstrap.ps1"

Invoke-PesterTests "*"