locals {
  rg_name = "rg-${var.short}-${var.loc}-${terraform.workspace}-03"
}

data "azurerm_resource_group" "rg" {
  name = local.rg_name
}