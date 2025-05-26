
# Libre DevOps – Terraform Azure Composite GitHub Action

A heavily opinionated GitHub Action designed to streamline Terraform workflows targeting Azure environments. This action encapsulates a Composite preloaded with essential tools like Terraform, Azure CLI, PowerShell, and various language version managers, facilitating consistent and secure infrastructure deployments.

## 🚀 Features

- **Comprehensive Tooling:** Includes Terraform, Azure CLI, PowerShell, and version managers for Python, Node.js, Go, Ruby, PHP, and Java.
- **Flexible Authentication:** Supports multiple Azure authentication methods, including OIDC, Client Secret, Managed Identity, and Azure AD.
- **Modular Execution:** Allows granular control over Terraform commands (`init`, `validate`, `plan`, `apply`, `destroy`) through input parameters.
- **Security Scanning:** Optional integration with Checkov for infrastructure security analysis.
- **Customizable Backend Configuration:** Supports dynamic backend state file naming with optional prefixes and suffixes.

## 🛠️ Inputs

The action accepts the following inputs:

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| `terraform-code-location` | Path to the root folder containing Terraform code. | No | `terraform` |
| `terraform-stack-to-run-json` | JSON array of stack names/folders to run (e.g., `['all']`, `['rg']`, `['network']`). | No | `['all']` |
| `terraform-workspace` | Terraform workspace to use or create. | No | `""` |
| `run-terraform-init` | Whether to run `terraform init` before other commands. | No | `true` |
| `run-terraform-validate` | Whether to run `terraform validate` after init. | No | `true` |
| `run-terraform-plan` | Whether to run `terraform plan`. | No | `true` |
| `run-terraform-plan-destroy` | Whether to run `terraform plan -destroy`. | No | `false` |
| `run-terraform-apply` | Whether to run `terraform apply` after a successful plan. | No | `false` |
| `run-terraform-destroy` | Whether to run `terraform destroy`. | No | `false` |
| `terraform-init-create-backend-state-file-name` | Auto-generates a backend state file name per stack. | No | `true` |
| `terraform-init-create-backend-state-file-prefix` | Prefix for the generated backend state file name. | No | `""` |
| `terraform-init-create-backend-state-file-suffix` | Suffix for the generated backend state file name. | No | `""` |
| `terraform-init-extra-args-json` | JSON array of extra arguments for `terraform init`. | No | `[]` |
| `terraform-plan-extra-args-json` | JSON array of extra arguments for `terraform plan`. | No | `[]` |
| `terraform-plan-destroy-extra-args-json` | JSON array of extra arguments for `terraform plan -destroy`. | No | `[]` |
| `terraform-apply-extra-args-json` | JSON array of extra arguments for `terraform apply`. | No | `[]` |
| `terraform-destroy-extra-args-json` | JSON array of extra arguments for `terraform destroy`. | No | `[]` |
| `debug-mode` | Enable verbose debug logging. | No | `false` |
| `delete-plan-files` | Delete the plan files after execution. | No | `true` |
| `terraform-version` | Terraform version to use (e.g., `latest`, `1.6.5`). | No | `latest` |
| `run-checkov` | Whether to run Checkov security scan on the plan. | No | `true` |
| `checkov-skip-check` | Comma-separated list of Checkov check IDs to skip. | No | `""` |
| `checkov-softfail` | Continue pipeline even if Checkov finds issues. | No | `false` |
| `checkov-extra-args-json` | JSON array of extra arguments for Checkov. | No | `[]` |
| `terraform-plan-file-name` | Filename for the Terraform plan output. | No | `tfplan.plan` |
| `terraform-destroy-plan-file-name` | Filename for the Terraform destroy plan output. | No | `tfplan-destroy.plan` |
| `create-terraform-workspace` | If true, create or select the Terraform workspace. | No | `true` |
| `use-azure-client-secret-login` | Enable Azure Client Secret login (SPN auth). | No | `false` |
| `use-azure-oidc-login` | Enable Azure OIDC login. | No | `true` |
| `use-azure-user-login` | Enable interactive user/device code login for Azure. | No | `false` |
| `use-azure-managed-identity-login` | Enable Azure Managed Identity login. | No | `false` |
| `use-azure-service-connection` | Enable Azure DevOps service connection. | No | `true` |
| `install-tenv-terraform` | Install and manage Terraform with tenv. | No | `false` |
| `install-azure-cli` | Install Azure CLI in the container. | No | `false` |
| `attempt-azure-login` | Attempt Azure login in the script. | No | `false` |
| `install-checkov` | Install Checkov in the container. | No | `false` |

## 🧪 Example Usage

Here's an example of how to use the action in a GitHub workflow:

```yaml
# .github/workflows/terraform-azure.yml

name: Terraform Build

on:
  workflow_dispatch:
    inputs:
      terraform-code-location:
        description: 'Terraform code location'
        required: false
        default: 'terraform'
      terraform-workspace:
        description: 'Terraform workspace'
        required: false
        default: 'dev'
      terraform-stack-to-run-json:
        description: 'Terraform stacks to run'
        required: false
        default: '["rg"]'
      debug-mode:
        description: 'Debug mode'
        required: false
        default: 'false'
env:
  terraform-init-extra-args-json: '["-backend-config=subscription_id=${{ secrets.ARM_BACKEND_SUBSCRIPTION_ID }}", "-backend-config=resource_group_name=${{ secrets.ARM_BACKEND_STORAGE_RG_NAME }}", "-backend-config=storage_account_name=${{ secrets.ARM_BACKEND_STORAGE_ACCOUNT }}", "-backend-config=container_name=${{ secrets.ARM_BACKEND_CONTAINER_NAME }}"]'


permissions:
  id-token: write # This is required for requesting the JWT
  contents: read  # This is required for actions/checkout

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Libre DevOps - Run Terraform for Azure
        uses: libre-devops/terraform-azure-composite-gh-action@v0.1
        with:
          terraform-code-location: ${{ github.event.inputs.terraform-code-location }}
          terraform-stack-to-run-json: ${{ github.event.inputs.terraform-stack-to-run-json }}
          terraform-workspace: ${{ github.event.inputs.terraform-workspace }}
          debug-mode: ${{ github.event.inputs.debug-mode }}
          terraform-init-extra-args-json: ${{ env.terraform-init-extra-args-json }}
        env:
          ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
          ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
          ARM_OIDC_TOKEN: ${{ env.OIDC_TOKEN }}
          TENV_AUTO_INSTALL: true
          ARM_USE_AZUREAD: true
```

## 🔐 Azure Authentication

The action supports various Azure authentication methods:

- **OIDC Login:** Recommended for GitHub Actions.
- **Client Secret Login:** Uses service principal credentials.
- **Managed Identity Login:** For Azure-hosted runners with managed identities.
- **User Login:** Interactive login using device code.

Set the corresponding input parameters (`use-azure-oidc-login`, `use-azure-client-secret-login`, etc.) to enable the desired authentication method.


## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

For more information and examples, please refer to the [repository](https://github.com/libre-devops/terraform-azure-docker-gh-action).
