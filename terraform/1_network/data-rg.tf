locals {
  rg_name         = "rg-${var.short}-${var.loc}-${terraform.workspace}-01"
}

data "azurerm_resource_group" "rg" {
  name = local.rg_name
}