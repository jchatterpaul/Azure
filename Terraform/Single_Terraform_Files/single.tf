terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "EnterSubscriptionIDHere"
  tenant_id       = "EnterTenantIDHere"
  features {

  }
}

variable "resource_group_name" {
  type    = string
  default = "terraformgrp"
}

variable "network_name" {
  type    = string
  default = "mynewnetwork"
}

variable "vm_name" {
  type    = string
  default = "mynewvm"
}

resource "azurerm_resource_group" "grp" {
  name     = var.resource_group_name
  location = "eastus"
  tags = {
    environment = "Terraform Demo"
  }
}

resource "azurerm_virtual_network" "staging" {
  name                = var.network_name
  address_space       = ["10.0.0.0/16"]
  location            = "eastus"
  resource_group_name = azurerm_resource_group.grp.name
  tags = {
    environment = "Terraform Demo"
  }

}

resource "azurerm_subnet" "default" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.grp.name
  virtual_network_name = azurerm_virtual_network.staging.name
  address_prefix       = "10.0.0.0/24"
}

resource "azurerm_public_ip" "tfpublicip" {
  name                = "myPublicIP"
  location            = azurerm_resource_group.grp.location
  resource_group_name = azurerm_resource_group.grp.name
  allocation_method   = "Dynamic"
  tags = {
    environment = "Terraform Demo"
  }
}

resource "azurerm_network_security_group" "tfnsg" {
  name                = "myNetworkSecurityGroup"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.grp.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Terraform Demo"
  }
}

resource "azurerm_network_interface" "interface" {
  name                = "default-interface"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.grp.name
  ip_configuration {
    name                          = "interfaceconfiguration"
    subnet_id                     = azurerm_subnet.default.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.tfpublicip.id
  }
  tags = {
    environment = "Terraform Demo"
  }
}

# connect security group to network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.interface.id
  network_security_group_id = azurerm_network_security_group.tfnsg.id
}

resource "azurerm_virtual_machine" "vm" {
  name                  = var.vm_name
  location              = "eastus"
  resource_group_name   = azurerm_resource_group.grp.name
  network_interface_ids = [azurerm_network_interface.interface.id]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "osdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "mynewvm"
    admin_username = "azureuser"
    admin_password = "EnterPasswordHere"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = "Terraform Demo"
  }
}


