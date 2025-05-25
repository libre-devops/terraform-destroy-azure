locals {
  envs = {
    dev = "Development"
  }
  repo_name      = split("/", var.repository_url)[4]
  project        = local.repo_name
  default_branch = "refs/heads/main"
  folders_path   = { for env, name in local.envs : env => "\\PipelineTemplates\\${local.project}\\${env}" }
}