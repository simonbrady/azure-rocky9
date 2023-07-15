terraform {
  required_version = "~>1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "location" {
  type        = string
  default     = "Australia East"
  description = "Location to create resources in"
}

variable "prefix" {
  type        = string
  default     = "rocky9"
  description = "Common prefix for resource names"
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "snet" {
  name                 = "snet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [azurerm_virtual_network.vnet.address_space[0]]
}

resource "azurerm_marketplace_agreement" "rocky" {
  publisher = "erockyenterprisesoftwarefoundationinc1653071250513"
  offer     = "rockylinux-9"
  plan      = "rockylinux-9"
}

data "azurerm_platform_image" "rocky" {
  location  = var.location
  publisher = "erockyenterprisesoftwarefoundationinc1653071250513"
  offer     = "rockylinux-9"
  sku       = "rockylinux-9"
}

module "vm" {
  depends_on = [azurerm_marketplace_agreement.rocky]
  source     = "git::https://github.com/simonbrady/azure-vm-tf-module.git?ref=1.0.0"

  admin_user          = "frank"
  allowed_cidr        = "127.0.0.1/32" # Replace with your IP
  location            = var.location
  prefix              = var.prefix
  public_key          = file("~/.ssh/id_rsa.pub")
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.snet.id
  vm_count            = 1
  vm_size             = "Standard_B2s"

  plan = {
    name      = "rockylinux-9"
    publisher = "erockyenterprisesoftwarefoundationinc1653071250513"
    product   = "rockylinux-9"
  }
  source_image_reference = {
    publisher = data.azurerm_platform_image.rocky.publisher
    offer     = data.azurerm_platform_image.rocky.offer
    sku       = data.azurerm_platform_image.rocky.sku
    version   = data.azurerm_platform_image.rocky.version
  }
}

output "vm_public_ips" {
  value = module.vm.vm_public_ips
}
