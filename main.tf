provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = var.location
}


#-------------------------------------------------------------------------
# Add Network
#-------------------------------------------------------------------------
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    project = "${var.project}"
  }
}

resource "azurerm_subnet" "internal" {
  name                 = "${var.prefix}-snet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
        name                       = "Internet_Traffic"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
  }

  tags = {
    project = "${var.project}"
  }
}

resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.internal.id
  network_security_group_id = azurerm_network_security_group.main.id
}

#-------------------------------------------------------------------------
# Add Load Balancer
#-------------------------------------------------------------------------
resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-pip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"

  tags = {
    project = "${var.project}"
  }
}

resource "azurerm_lb" "main" {
  name                = "${var.prefix}-lbe"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  frontend_ip_configuration {
    name                 = "primary"
    public_ip_address_id = azurerm_public_ip.main.id
  }
 
 tags = {
    project = "${var.project}"
  }
}

resource "azurerm_lb_backend_address_pool" "main" {
  name                = "${var.prefix}-backend_address_pool"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.main.id
}

resource "azurerm_lb_probe" "main" {
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.main.id
  name                = "${var.prefix}-lbe_probe"
  port                = 80
}

resource "azurerm_lb_rule" "main" {
  resource_group_name            = azurerm_resource_group.main.name
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "${var.prefix}-lb_rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_id        = azurerm_lb_backend_address_pool.main.id
  probe_id			 = azurerm_lb_probe.main.id
  frontend_ip_configuration_name = "primary"
}

#-------------------------------------------------------------------------
# Add NICs
#-------------------------------------------------------------------------
resource "azurerm_network_interface" "main" {
  count		      = "${var.numofservers}"
  name                = "${var.prefix}-nic-${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "${var.prefix}-subnet"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }

 tags = {
    project = "${var.project}"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "main" {
  count 			= "${var.numofservers}" 
  network_interface_id    	= element(azurerm_network_interface.main.*.id, count.index)
  ip_configuration_name   	= "${var.prefix}-subnet"
  backend_address_pool_id 	= azurerm_lb_backend_address_pool.main.id
}

#-------------------------------------------------------------------------
# Add Availability Set
#-------------------------------------------------------------------------
resource "azurerm_availability_set" "main" {
	name			     = "${var.prefix}-avail"
	location        	     = azurerm_resource_group.main.location
	resource_group_name 	     = azurerm_resource_group.main.name
	platform_fault_domain_count  = 2
	platform_update_domain_count = 2

 tags = {
    project = "${var.project}"
  }
}

#-------------------------------------------------------------------------
# Add virtual machines
#-------------------------------------------------------------------------
data "azurerm_image" "main" {
  name                	= "apacheserver"
  resource_group_name 	= "packerimages"
}

resource "azurerm_linux_virtual_machine" "main" {
  count				  = "${var.numofservers}"
  name                            = "${var.prefix}-vm${count.index}"
  resource_group_name             = azurerm_resource_group.main.name
  availability_set_id             = azurerm_availability_set.main.id
  location                        = azurerm_resource_group.main.location
  size                            = "Standard_D2s_v3"
  admin_username                  = "${var.user}"
  admin_password                  = "${var.password}"
  disable_password_authentication = false
  network_interface_ids = ["${element(azurerm_network_interface.main.*.id, count.index)}"]

  source_image_id       = data.azurerm_image.main.id
  
  os_disk {
    name                 = "${var.prefix}-os-disk-${count.index}"
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
 
  tags = {
    project = "${var.project}"
  }
}


