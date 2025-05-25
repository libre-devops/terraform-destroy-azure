data "azuredevops_project" "target" {
  name = "libredevops"
}

data "azuredevops_serviceendpoint_github" "github" {
  project_id            = data.azuredevops_project.target.id
  service_endpoint_name = data.azuredevops_project.target.name
}
