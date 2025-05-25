resource "azuredevops_build_definition" "stages_init_plan" {
  for_each        = local.envs
  project_id      = data.azuredevops_project.target.id
  name            = "${title(local.repo_name)} - Stages - ${title(each.key)} - Terraform Init & Terraform Plan"
  path            = "${local.folders_path[each.key]}\\stages"
  agent_pool_name = "Default"

  ci_trigger {
    use_yaml = false
  }

  repository {
    repo_type             = "GitHub"
    repo_id               = "${var.github_org_name}/${var.github_project_name}"
    branch_name           = local.default_branch
    yml_path              = ".azuredevops/workflows/stages/${each.key}/terraform-init-plan.yaml"
    service_connection_id = data.azuredevops_serviceendpoint_github.github.id
  }
}

resource "azuredevops_build_definition" "stages_init_plan_apply" {
  for_each        = local.envs
  project_id      = data.azuredevops_project.target.id
  name            = "${title(local.repo_name)} - Stages - ${title(each.key)} - Terraform Init, Terraform Plan & Terraform Apply"
  path            = "${local.folders_path[each.key]}\\stages"
  agent_pool_name = "Default"

  ci_trigger {
    use_yaml = false
  }

  repository {
    repo_type             = "GitHub"
    repo_id               = "${var.github_org_name}/${var.github_project_name}"
    branch_name           = local.default_branch
    yml_path              = ".azuredevops/workflows/stages/${each.key}/terraform-init-plan-apply.yaml"
    service_connection_id = data.azuredevops_serviceendpoint_github.github.id
  }
}

resource "azuredevops_build_definition" "stages_init_plan_destroy" {
  for_each        = local.envs
  project_id      = data.azuredevops_project.target.id
  name            = "${title(local.repo_name)} - Stages - ${title(each.key)} - Terraform Init & Terraform Plan Destroy"
  path            = "${local.folders_path[each.key]}\\stages"
  agent_pool_name = "Default"

  ci_trigger {
    use_yaml = false
  }

  repository {
    repo_type             = "GitHub"
    repo_id               = "${var.github_org_name}/${var.github_project_name}"
    branch_name           = local.default_branch
    yml_path              = ".azuredevops/workflows/stages/${each.key}/terraform-init-plan-destroy.yaml"
    service_connection_id = data.azuredevops_serviceendpoint_github.github.id
  }
}

resource "azuredevops_build_definition" "stages_init_plan_destroy_apply" {
  for_each        = local.envs
  project_id      = data.azuredevops_project.target.id
  name            = "${title(local.repo_name)} - Stages - ${title(each.key)} - Terraform Init, Terraform Plan Destroy & Terraform Destroy"
  path            = "${local.folders_path[each.key]}\\stages"
  agent_pool_name = "Default"

  ci_trigger {
    use_yaml = false
  }

  repository {
    repo_type             = "GitHub"
    repo_id               = "${var.github_org_name}/${var.github_project_name}"
    branch_name           = local.default_branch
    yml_path              = ".azuredevops/workflows/stages/${each.key}/terraform-init-plan-destroy-apply.yaml"
    service_connection_id = data.azuredevops_serviceendpoint_github.github.id
  }
}