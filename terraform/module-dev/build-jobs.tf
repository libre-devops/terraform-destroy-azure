resource "azuredevops_build_definition" "job_terraform_build" {
  for_each        = local.envs
  project_id      = data.azuredevops_project.target.id
  name            = "${title(local.repo_name)} - ${title(each.key)} - Terraform Build"
  path            = "${local.folders_path[each.key]}\\jobs"
  agent_pool_name = "Default"

  ci_trigger {
    use_yaml = false
  }

  repository {
    repo_type             = "GitHub"
    repo_id               = "${var.github_org_name}/${var.github_project_name}"
    branch_name           = local.default_branch
    yml_path              = ".azuredevops/workflows/jobs/${each.key}/terraform-build.yaml"
    service_connection_id = data.azuredevops_serviceendpoint_github.github.id
  }
}

resource "azuredevops_build_definition" "job_terraform_destroy" {
  for_each        = local.envs
  project_id      = data.azuredevops_project.target.id
  name            = "${title(local.repo_name)} - ${title(each.key)} - Terraform Destroy"
  path            = "${local.folders_path[each.key]}\\jobs"
  agent_pool_name = "Default"

  ci_trigger {
    use_yaml = false
  }

  repository {
    repo_type             = "GitHub"
    repo_id               = "${var.github_org_name}/${var.github_project_name}"
    branch_name           = local.default_branch
    yml_path              = ".azuredevops/workflows/jobs/${each.key}/terraform-destroy.yaml"
    service_connection_id = data.azuredevops_serviceendpoint_github.github.id
  }
}