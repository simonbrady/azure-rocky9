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
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    protocol                   = "Tcp"
    source_address_prefixes    = concat([var.allowed_cidr], azurerm_subnet.snet.address_prefixes)
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = 22
    access                     = "Allow"
  }

  security_rule {
    name                       = "allow-http"
    priority                   = 110
    direction                  = "Inbound"
    protocol                   = "Tcp"
    source_address_prefixes    = [var.allowed_cidr]
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = 80
    access                     = "Allow"
  }

  security_rule {
    name                       = "allow-azure-lb"
    priority                   = 3990
    direction                  = "Inbound"
    protocol                   = "*"
    source_address_prefix      = "AzureLoadBalancer"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
    access                     = "Allow"
  }

  security_rule {
    name                       = "deny-others"
    priority                   = 4000
    direction                  = "Inbound"
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
    access                     = "Deny"
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

module "vm" {
  depends_on = [azurerm_marketplace_agreement.rocky]
  source     = "git::https://github.com/simonbrady/azure-vm-tf-module.git?ref=2.3.1"

  admin_user                = "frank"
  create_load_balancer      = true
  custom_data               = base64encode(file("cloud-init.yml"))
  fault_domain_count        = var.fault_domain_count
  location                  = var.location
  network_security_group_id = azurerm_network_security_group.nsg.id
  prefix                    = var.prefix
  public_key                = file("~/.ssh/id_rsa.pub")
  resource_group_name       = azurerm_resource_group.rg.name
  subnet_id                 = azurerm_subnet.snet.id
  vm_count                  = 2
  vm_size                   = "Standard_B2s"

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

# Load-balancer config specific to this use of the module
resource "azurerm_lb_probe" "http" {
  loadbalancer_id = module.vm.lb_id
  name            = "http-probe"
  port            = 80
}

resource "azurerm_lb_rule" "http" {
  loadbalancer_id                = module.vm.lb_id
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = module.vm.lb_frontend_config
  backend_address_pool_ids       = [module.vm.lb_backend_pool_id]
  probe_id                       = azurerm_lb_probe.http.id
}
