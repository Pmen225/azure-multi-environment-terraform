terraform {
  required_version = ">= 1.8.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 5.0, < 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6, < 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "location" {
  type    = string
  default = "uksouth"
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_resource_group" "main" {
  name     = "rg-portfolio-dev-${random_string.suffix.result}"
  location = var.location
}

module "network" {
  source              = "../../modules/network"
  name                = "vnet-portfolio-dev"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.20.0.0/16"]
}

module "app" {
  source              = "../../modules/app"
  name                = "portfolio-dev-${random_string.suffix.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "B1"
  subnet_id           = module.network.subnet_id
}

output "web_url" {
  description = "App Service URL; this project does not deploy application code."
  value       = "https://${module.app.hostname}"
}

output "resource_group" {
  value = azurerm_resource_group.main.name
}
