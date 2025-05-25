terraform {
  #Use the latest by default, uncomment below to pin or use hcl.lck
  required_providers {
    azuredevops = {
      source = "microsoft/azuredevops"
    }
  }
  backend "local" {} # throwaway
}