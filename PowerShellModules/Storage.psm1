function Assert-AzStorageContainer
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$StorageAccountSubscription,

        [Parameter(Mandatory = $true)]
        [string]$StorageAccountName,

        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory = $true)]
        [string]$ContainerName
    )

    begin {
        try
        {
            $azureAplicationId = $Env:ARM_CLIENT_ID
            $azureTenantId = $Env:ARM_TENANT_ID
            $azurePassword = ConvertTo-SecureString $Env:ARM_CLIENT_SECRET -AsPlainText -Force
            $psCred = New-Object System.Management.Automation.PSCredential($azureAplicationId, $azurePassword)
            Connect-AzAccount -ServicePrincipal -Credential $psCred -Tenant $azureTenantId | Out-Null
            Write-Host "Info: Connected to AzAccount using Powershell" -ForegroundColor Yellow

            # Set the subscription context
            Set-AzContext -SubscriptionId $StorageAccountSubscription | Out-Null

            # Get the Storage Account
            $storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
        }
        catch
        {
            throw "[$( $MyInvocation.MyCommand.Name )] Error in setting up the Azure context: $_"
            return
        }
    }

    process {
        try
        {
            # Create a storage context using OAuth token
            $ctx = New-AzStorageContext -StorageAccountName $storageAccount.StorageAccountName -UseConnectedAccount

            # Check if the Blob Container Exists
            $container = Get-AzStorageContainer -Name $ContainerName -Context $ctx -ErrorAction SilentlyContinue

            # Create the Container if it Doesn't Exist
            if ($null -eq $container)
            {
                New-AzStorageContainer -Name $ContainerName -Context $ctx
                Write-Host "Success: Container '$ContainerName' created." -ForegroundColor Green
            }
            else
            {
                Write-Host "Info: Container '$ContainerName' already exists." -ForegroundColor Yellow
            }
        }
        catch
        {
            throw "[$( $MyInvocation.MyCommand.Name )] Error in processing the container creation: $_"
        }
    }

    end {
        Write-Host "Operation completed, removing PowerShell Context"
        Disconnect-AzAccount | Out-Null
    }
}

Export-ModuleMember -Function Assert-AzStorageContainer