variable "repository_url" {
  type        = string
  description = "The URL of the repo building this project.  Passed as a TF_VAR from pipeline"
  default     = "https://github.com/libre-devops/terraform-azure-azdo-pipeline-templates"
}

variable "github_org_name" {
  type        = string
  description = "The name of the GitHub org that owns the repo."
  default     = "libre-devops"
}

variable "github_project_name" {
  type        = string
  description = "The name of the project within the GitHub org project.  Should be in the form: libre-devops/<project-name>"
  default     = "terraform-azure-azdo-pipeline-templates"
}