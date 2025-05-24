locals {
  vnet_name       = "vnet-${var.short}-${var.loc}-${terraform.workspace}-03"
  dev_subnet_name = "DevSubnet"
  nsg_name        = "nsg-${var.short}-${var.loc}-${terraform.workspace}-03"
}

module "shared_vars" {
  source = "libre-devops/shared-vars/azurerm"
}

locals {
  lookup_cidr = {
    for landing_zone, envs in module.shared_vars.cidrs : landing_zone => {
      for env, cidr in envs : env => cidr
    }
  }
}

module "subnet_calculator" {
  source = "libre-devops/subnet-calculator/null"

  base_cidr = local.lookup_cidr[var.short][var.env][0]
  subnets = {
    (local.dev_subnet_name) = {
      mask_size = 26
      netnum    = 0
    }
  }
}

module "network" {
  source = "libre-devops/network/azurerm"

  rg_name  = data.azurerm_resource_group.rg.name
  location = data.azurerm_resource_group.rg.location
  tags     = data.azurerm_resource_group.rg.tags

  vnet_name          = local.vnet_name
  vnet_location      = data.azurerm_resource_group.rg.location
  vnet_address_space = [module.subnet_calculator.base_cidr]

  subnets = {
    for i, name in module.subnet_calculator.subnet_names :
    name => {
      address_prefixes  = toset([module.subnet_calculator.subnet_ranges[i]])
      service_endpoints = name == local.dev_subnet_name ? ["Microsoft.KeyVault"] : []

      # Only assign delegation to subnet3
      delegation = []
    }
  }
}

module "client_ip" {
  source = "libre-devops/ip-address/external"
}

module "nsg" {
  source = "libre-devops/nsg/azurerm"

  rg_name  = data.azurerm_resource_group.rg.name
  location = data.azurerm_resource_group.rg.location
  tags     = data.azurerm_resource_group.rg.tags

  nsg_name              = local.nsg_name
  associate_with_subnet = true
  subnet_ids            = { for k, v in module.network.subnets_ids : k => v if k != "AzureBastionSubnet" }
  custom_nsg_rules = {
    "AllowVnetInbound" = {
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    }
    "AllowClientInbound" = {
      priority                   = 101
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = chomp(module.client_ip.public_ip_address)
      destination_address_prefix = "VirtualNetwork"
    }
  }
}
