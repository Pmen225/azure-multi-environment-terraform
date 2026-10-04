terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 5.0, < 6.0"
    }
  }
}

variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "address_space" {
  description = "IPv4 ranges. The first range must leave space for a /24 integration subnet."
  type        = list(string)

  validation {
    condition = length(var.address_space) > 0 && alltrue([
      for cidr in var.address_space : can(cidrnetmask(cidr))
    ]) && can(cidrsubnet(var.address_space[0], 8, 1)) && try(tonumber(split("/", var.address_space[0])[1]) == 16, false)
    error_message = "Provide valid IPv4 CIDRs with a /16 as the first range."
  }
}

resource "azurerm_virtual_network" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
}

resource "azurerm_subnet" "app" {
  name                 = "app"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [cidrsubnet(var.address_space[0], 8, 1)]

  delegation {
    name = "appsvc"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

output "subnet_id" {
  value = azurerm_subnet.app.id
}
