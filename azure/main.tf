terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vm_name" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "cloud_init_config" {
  type = string
}

variable "machine_type" {
  type = string
}

variable "disk_encryption_id" {
  type = string
}

variable "vm_id" {
  type = string
  description = "Unique identifier for the VM"
}

variable "workspace_id" {
  type = string
  description = "Workspace identifier"
}

data "cloudinit_config" "conf" {
  gzip          = true
  base64_encode = true
  
  part {
    content_type = "text/cloud-config"
    content      = file(var.cloud_init_config)
    filename     = "conf.yml"
  }
}

resource "azurerm_public_ip" "vm_public_ip" {
  name                = "${var.vm_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
  domain_name_label   = lower(var.vm_name)

  tags = {
    vm_id        = var.vm_id
    workspace_id = var.workspace_id
  }
}

resource "azurerm_virtual_network" "vm_vnet" {
  name                = "${var.vm_name}-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/16"]

  tags = {
    vm_id        = var.vm_id
    workspace_id = var.workspace_id
  }
}

resource "azurerm_subnet" "vm_subnet" {
  name                 = "${var.vm_name}-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vm_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "vm_nic" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_public_ip.id
  }

  tags = {
    vm_id        = var.vm_id
    workspace_id = var.workspace_id
  }
}

resource "azurerm_linux_virtual_machine" "confidential" {
  name                = var.vm_name
  location            = var.location
  resource_group_name = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.vm_nic.id]
  size = var.machine_type

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    security_encryption_type = "VMGuestStateOnly"
    disk_encryption_set_id = var.disk_encryption_id
  }
  
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "cvm"
    version   = "latest"
  }
  
  admin_username       = "adminuser"
  disable_password_authentication = false
  admin_password = "P@ssw0rd123!" # Replace with a secure password or use a variable
  
  vtpm_enabled        = true
  secure_boot_enabled = true
  custom_data         = data.cloudinit_config.conf.rendered

  tags = {
    vm_id        = var.vm_id
    workspace_id = var.workspace_id
  }
}

data "azurerm_public_ip" "vm_public_ip_data" {
  name                = azurerm_public_ip.vm_public_ip.name
  resource_group_name = var.resource_group_name
  depends_on          = [azurerm_linux_virtual_machine.confidential]
}

output "vm_public_ip" {
  value = data.azurerm_public_ip.vm_public_ip_data.ip_address
}

output "vm_fqdn" {
  value = data.azurerm_public_ip.vm_public_ip_data.fqdn
}
