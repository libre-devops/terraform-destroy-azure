locals {
  rg_name         = "rg-${var.short}-${var.loc}-${terraform.workspace}-01"
}

module "rg" {
  source = "libre-devops/rg/azurerm"

  rg_name  = local.rg_name
  location = local.location
  tags     = local.tags
}
