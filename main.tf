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

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    protocol                   = "Tcp"
    source_address_prefixes    = ["127.0.0.1/32"] # Change to your IP
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = 22
    access                     = "Allow"
  }
}

resource "azurerm_subnet_network_security_group_association" "assoc" {
  subnet_id                 = azurerm_subnet.snet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_public_ip" "pip" {
  name                = "${var.prefix}-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.snet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
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

resource "azurerm_linux_virtual_machine" "vm" {
  depends_on            = [azurerm_marketplace_agreement.rocky]
  name                  = "${var.prefix}-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = "Standard_B2s"
  admin_username        = "frank"
  network_interface_ids = [azurerm_network_interface.nic.id]

  admin_ssh_key {
    username   = "frank"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    name                 = "${var.prefix}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = data.azurerm_platform_image.rocky.publisher
    offer     = data.azurerm_platform_image.rocky.offer
    sku       = data.azurerm_platform_image.rocky.sku
    version   = data.azurerm_platform_image.rocky.version
  }

  plan {
    name      = "rockylinux-9"
    publisher = "erockyenterprisesoftwarefoundationinc1653071250513"
    product   = "rockylinux-9"
  }
}

output "vm_public_ip" {
  value = azurerm_public_ip.pip.ip_address
}
