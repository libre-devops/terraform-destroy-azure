locals {
  envs = {
    dev  = "Development"
  }
  repo_name      = split("/", var.repository_url)[4]
  project        = local.repo_name
  default_branch = "main"
  folders_path   = { for env, name in local.envs : env => "\\PipelineTemplates\\${local.project}\\${env}" }
}

resource "azuredevops_build_definition" "init_plan" {
  for_each        = local.envs
  project_id      = data.azuredevops_project.target.id
  name            = "${title(local.repo_name)} - ${title(each.key)} - Terraform Init & Terraform Plan"
  path            = local.folders_path[each.key]
  agent_pool_name = "Default"

  ci_trigger {
    use_yaml = false
  }

  repository {
    repo_type             = "GitHub"
    repo_id               = "${var.github_org_name}/${var.github_project_name}"
    branch_name           = local.default_branch
    yml_path              = ".azuredevops/workflows/steps/${each.key}/terraform-init-plan.yaml"
    service_connection_id = data.azuredevops_serviceendpoint_github.github.id
  }
}

resource "azuredevops_build_definition" "init_plan_apply" {
  for_each        = local.envs
  project_id      = data.azuredevops_project.target.id
  name            = "${title(local.repo_name)} - ${title(each.key)} - Terraform Init, Terraform Plan & Terraform Apply"
  path            = local.folders_path[each.key]
  agent_pool_name = "Default"

  ci_trigger {
    use_yaml = false
  }

  repository {
    repo_type             = "GitHub"
    repo_id               = "${var.github_org_name}/${var.github_project_name}"
    branch_name           = local.default_branch
    yml_path              = ".azuredevops/workflows/steps/${each.key}/terraform-init-plan-apply.yaml"
    service_connection_id = data.azuredevops_serviceendpoint_github.github.id
  }
}

resource "azuredevops_build_definition" "init_plan_destroy" {
  for_each        = local.envs
  project_id      = data.azuredevops_project.target.id
  name            = "${title(local.repo_name)} - ${title(each.key)} - Terraform Init & Terraform Plan Destroy"
  path            = local.folders_path[each.key]
  agent_pool_name = "Default"

  ci_trigger {
    use_yaml = false
  }

  repository {
    repo_type             = "GitHub"
    repo_id               = "${var.github_org_name}/${var.github_project_name}"
    branch_name           = local.default_branch
    yml_path              = ".azuredevops/workflows/steps/${each.key}/terraform-init-plan-destroy.yaml"
    service_connection_id = data.azuredevops_serviceendpoint_github.github.id
  }
}

resource "azuredevops_build_definition" "init_plan_destroy_apply" {
  for_each        = local.envs
  project_id      = data.azuredevops_project.target.id
  name            = "${title(local.repo_name)} - ${title(each.key)} - Terraform Init, Terraform Plan Destroy & Terraform Destroy"
  path            = local.folders_path[each.key]
  agent_pool_name = "Default"

  ci_trigger {
    use_yaml = false
  }

  repository {
    repo_type             = "GitHub"
    repo_id               = "${var.github_org_name}/${var.github_project_name}"
    branch_name           = local.default_branch
    yml_path              = ".azuredevops/workflows/steps/${each.key}/terraform-init-plan-destroy-apply.yaml"
    service_connection_id = data.azuredevops_serviceendpoint_github.github.id
  }
}
