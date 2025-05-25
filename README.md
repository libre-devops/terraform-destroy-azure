
# Libre DevOps – Terraform Azure Docker GitHub Action

A heavily opinionated GitHub Action designed to streamline Terraform workflows targeting Azure environments. This action encapsulates a Docker container preloaded with essential tools like Terraform, Azure CLI, PowerShell, and various language version managers, facilitating consistent and secure infrastructure deployments.

## 🚀 Features

- **Comprehensive Tooling:** Includes Terraform, Azure CLI, PowerShell, and version managers for Python, Node.js, Go, Ruby, PHP, and Java.
- **Flexible Authentication:** Supports multiple Azure authentication methods, including OIDC, Client Secret, Managed Identity, and Azure AD.
- **Modular Execution:** Allows granular control over Terraform commands (`init`, `validate`, `plan`, `apply`, `destroy`) through input parameters.
- **Security Scanning:** Optional integration with Checkov for infrastructure security analysis.
- **Customizable Backend Configuration:** Supports dynamic backend state file naming with optional prefixes and suffixes.

## 📦 Docker Image

The action utilizes a Docker container built from the provided `Dockerfile`, ensuring a consistent environment across different runs.

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
name: 'Terraform Plan'

on:
  push:
    branches:
      - main
  pull_request:
    types: [closed]
  workflow_dispatch:

jobs:
  azure-terraform-job:
    name: 'Terraform Build'
    runs-on: ubuntu-latest
    environment: tst

    steps:
      - uses: actions/checkout@v3

      - name: Libre DevOps Terraform GitHub Action
        id: terraform-build
        uses: libre-devops/terraform-azure-docker-gh-action@v1
        with:
          terraform-code-location: "terraform"
          terraform-stack-to-run-json: '["all"]'
          terraform-workspace: "dev"
          run-terraform-init: "true"
          run-terraform-validate: "true"
          run-terraform-plan: "true"
          run-terraform-apply: "false"
          run-terraform-destroy: "false"
          terraform-version: "latest"
          debug-mode: "false"
          delete-plan-files: "true"
          run-checkov: "true"
          checkov-softfail: "false"
          create-terraform-workspace: "true"
          use-azure-oidc-login: "true"
          attempt-azure-login: "true"
```

## 🔐 Azure Authentication

The action supports various Azure authentication methods:

- **OIDC Login:** Recommended for GitHub Actions.
- **Client Secret Login:** Uses service principal credentials.
- **Managed Identity Login:** For Azure-hosted runners with managed identities.
- **User Login:** Interactive login using device code.

Set the corresponding input parameters (`use-azure-oidc-login`, `use-azure-client-secret-login`, etc.) to enable the desired authentication method.

## 🧪 Testing

To test the action locally or in a development environment, you can use the provided `Run-Docker.ps1` script, which builds and runs the Docker container with appropriate parameters.

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

For more information and examples, please refer to the [repository](https://github.com/libre-devops/terraform-azure-docker-gh-action).
